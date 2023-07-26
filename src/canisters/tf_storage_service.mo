import CA "mo:candb/CanisterActions";
import CanDB "mo:candb/CanDB";
import Entity "mo:candb/Entity";
import Prelude "mo:base/Prelude";

import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Nat32 "mo:base/Nat32";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Prim "mo:⛔";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Array "mo:base/Array";
import Time "mo:base/Time";
import Float "mo:base/Float";
import Order "mo:base/Order";

import LexEncode "mo:lexicographic-encoding/EncodeInt";
import JSON "mo:json/JSON";
import DateTime "mo:DateTime/DateTime";

import RBT "mo:stable-rbtree/StableRBTree";

shared ({ caller = owner }) actor class Service({
  // the primary key of this canister
  partitionKey: Text;
  // the scaling options that determine when to auto-scale out this canister storage partition
  scalingOptions: CanDB.ScalingOptions;
  // (optional) allows the developer to specify additional owners (i.e. for allowing admin or backfill access to specific endpoints)
  owners: ?[Principal];
}) {
  /// @required (may wrap, but must be present in some form in the canister)
  stable let db = CanDB.init({
    pk = partitionKey;
    scalingOptions = scalingOptions;
    btreeOrder = null;
  });

  /// @recommended (not required) public API
  public query func getPK(): async Text { db.pk };

  /// @required public API (Do not delete or change)
  public query func skExists(sk: Text): async Bool { 
    CanDB.skExists(db, sk);
  };

  /// @required public API (Do not delete or change)
  public shared({ caller = caller }) func transferCycles(): async () {
    if (caller == owner) {
      return await CA.transferCycles(caller);
    };
  };

  /*-- For batch insert (called from node.js) --*/
  public query func isStatusComplete(): async Bool {
    switch (db.scalingStatus) {
      case (#complete) true;
      case _ false;
    }
  };

  /*-- Helper --*/
  func jointText(textArray: [Text]): Text {
    var result = "";
    for (t in textArray.vals()) {
      result := result # "#" # t;
    };
    result
  };


  Debug.print "Hi, I'm upgraded!";
  
  /*

  <SK, Attribute>
    - canisteridSk:
      Key:        "#canisterid#<canisterid>"
      Attribute:  [("metadataSk", <metadataSk>), ("titleSk", <titleSk>),("lastseenSk", <lastseenSk>)]
    - titleSk:  
      Key:        "#type#app#apptype#<blog, nft, game ...>#titlehash"#<Nat32>#score#<0-99>#id#<Nat>"
      Attribute:  [("metadataSk", <metadataSk>)]
    - lastseenSk: 
      Key:        "#type#app#lastseen#<YYYY-MM-DD>#apptype#<blog, nft, game ...>#id#<Nat>"
      Attribute   [("title"), ("subtitle"), ("content"), ("canisterid"), ("subnetid"), ("type"), ("apptype"), ("datalength"), ("lastseen"), ("id"), ("status"), ("notnull"), ("note")]
    
    - TF_SK:
      Key:        "#word#<word>#host#<host>"
      Attribute:  ["tf score"]
    - METADATA_SK:
      Key:        "#host#<host>"
      Attribute:  
  */

  /*-- Insert --*/

  // Tf
  type PathIdx = Nat; // metadataに格納されているpages:[Path]のIndex
  type Word = Text;
  type Tf = Float; // idfはフロント側で計算すれば良いので
  type Host = Text;
  // Metadata
  type Path = Text;
  type Title = Text;
  stable var host_count: Nat = 0;

  func createBatchOptions(sites :[(Host, [Path], [Title], [(Word, ([Tf], [PathIdx]))])]): [CanDB.PutOptions] { 

    var maxWordsSize = 0;
    for ((_, _, _, words) in sites.vals()) {
      if (words.size() > maxWordsSize) maxWordsSize := words.size();
    };
    let buffer = Buffer.Buffer<CanDB.PutOptions>(maxWordsSize*sites.size());

    for ((host, pages, titles, words) in sites.vals()) {
      for ((word, (tfs, idxs)) in words.vals()) {
        let sk = jointText(["word", word, "host", host]);
        let attributes = [
          ("tf", #arrayFloat tfs),
          ("idx", #arrayInt idxs)
        ];
        buffer.add({sk; attributes});
      };

      let sk = jointText(["host", host, "titles&pages"]);
      let attributes = [
        ("pages",  #arrayText(pages)),
        ("titles", #arrayText(titles))
      ];
      buffer.add({sk; attributes});

      if (not CanDB.skExists(db, sk)) host_count +=1; // this count is used for scan limit
    };

    return Buffer.toArray<CanDB.PutOptions>(buffer);
  };

  public func batchPut(sites :[(Host, [Path], [Title], [(Word, ([Tf], [PathIdx]))])]): async () {
    let batchOptions = createBatchOptions(sites);
    await* CanDB.batchPut(db, batchOptions);
  };

  func compareEntity(a: Entity.Entity, b: Entity.Entity): Order.Order {
    Text.compare(a.sk, b.sk)
  };

  func compareHost(a: Entity.Entity, b: Entity.Entity): Order.Order {
    let a_host = Iter.toArray(Text.split(a.sk, #text "#host#"))[1];
    let b_host = Iter.toArray(Text.split(b.sk, #text "#host#"))[1];
     Text.compare(a_host, b_host)
  };

  func setIntersect<T>(_a: [T], _b: [T], compare: (T, T)->Order.Order): [T] {
    let b = Buffer.fromArray<T>(_b);

    let set =  Buffer.Buffer<T>(_a.size());

    for (v in _a.vals()) {
      switch (Buffer.binarySearch<T>(v, b, compare)) {
        case (?_) set.add(v);
        case _ {};
      };
    };

    return Buffer.toArray<T>(set);
  };

  public func search(words: [Word]): async [Entity.Entity] {
    var set: ?[Entity.Entity] = null;
    for (word in words.vals()) {
      let skLowerBound = jointText(["word", word, "host", ""]);
      let skUpperBound = jointText(["word", word, "host", "~"]); // '~' is the last byte of ASCII
      let limit = host_count;

      let res = CanDB.scan(db, {
        skLowerBound;
        skUpperBound;
        limit;
        ascending = null;
      });// { entities : [E.Entity]; nextKey : ?E.SK }

      set := switch (set) {
        case (?set) ?setIntersect<Entity.Entity>(set, res.entities, compareHost);
        case null ?res.entities;
      };

      Debug.print(debug_show(set))
    };

    /*
    WIP: search in titles
    */

    // Buffer.removeDuplicates<Entity.Entity>(merged, compareEntity); // OR Search

    return switch (set) {
      case (?set) set;
      case null [];
    }
  };

}
