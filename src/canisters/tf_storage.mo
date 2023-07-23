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

  func createBatchOptions(words: [(Word, [(Host, [Tf], [PathIdx])])], hosts: [(Host, [Path], [Title])]): [CanDB.PutOptions] { 
    let buffer = Buffer.Buffer<CanDB.PutOptions>(words.size()*hosts.size());

    for ((word, hosts) in words.vals()) {
      for ((host, tfs, idxs) in hosts.vals()) {
        let sk = jointText(["word", word, "host", host]);
        let attributes = [
          ("tf", #arrayFloat tfs),
          ("idx", #arrayInt idxs)
        ];
        buffer.add({sk; attributes});
      };
    };

    for ((host, pages, titles) in hosts.vals())  {
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

  public func batchPut(words: [(Word, [(Host, [Tf], [PathIdx])])], hosts: [(Host, [Path], [Title])]): async () {
    let batchOptions = createBatchOptions(words, hosts);
    await* CanDB.batchPut(db, batchOptions);
  };

  func compareEntity(a: Entity.Entity, b: Entity.Entity): Order.Order {
    Text.compare(a.sk, b.sk)
  };

  public func search(words: [Word]): async [Entity.Entity] {
    var merged = Buffer.Buffer<Entity.Entity>(1);
    for (word in words.vals()) {
      let skLowerBound = jointText(["word", word, "host", ""]);
      let skUpperBound = jointText(["word", word, "host", "~"]); // '~' is the last byte of ASCII
      let limit = host_count;

      let rs = CanDB.scan(db, {
        skLowerBound = "#";
        skUpperBound = "#~";
        limit;
        ascending = null;
      });// { entities : [E.Entity]; nextKey : ?E.SK }


      // memo ここの積集合を求める過程は要改善
      merged := Buffer.merge<Entity.Entity>(merged, Buffer.fromArray<Entity.Entity>(rs.entities), compareEntity);
    };

    Buffer.removeDuplicates<Entity.Entity>(merged, compareEntity);

    return Buffer.toArray<Entity.Entity>(merged);
  };

}
