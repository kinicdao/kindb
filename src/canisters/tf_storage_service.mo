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
import HashMap "mo:base/HashMap";

import LexEncode "mo:lexicographic-encoding/EncodeInt";
import JSON "mo:json/JSON";
import DateTime "mo:DateTime/DateTime";

import RBT "mo:stable-rbtree/StableRBTree";
import Timer "mo:base/Timer";

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
  type CountOfWord = Nat;
  type KindOfWord = Nat;
  type DocumentInfo = (CountOfWord, KindOfWord);
  stable var host_count: Nat = 0; // WIP: 重複でhostをカウントしてしまう

  // Count words in this canister used for scaning and deleting word keys
  stable var stableEntries: [(Word, Nat)] = [];
  let wordMap = HashMap.fromIter<Word, Nat>(stableEntries.vals(), 1, Text.equal, Text.hash);
  system func postupgrade() {
    stableEntries := Iter.toArray(wordMap.entries());
  };
  func incWordCount(word: Word) {
    switch (wordMap.get(word)) {
      case (?count) wordMap.put(word, count+1);
      case _ wordMap.put(word, 1);
    };
  };

  func createBatchOptions(sites :[(Host, [Path], [Title], [CountOfWord], [KindOfWord], [(Word, ([Tf], [PathIdx]))])]): [CanDB.PutOptions] { 

    var maxWordsSize = 0;
    for ((_, _, _, _, _, words) in sites.vals()) {
      if (words.size() > maxWordsSize) maxWordsSize := words.size();
    };
    let buffer = Buffer.Buffer<CanDB.PutOptions>(maxWordsSize*sites.size());

    for ((host, pages, titles, countOfWords, klindOfWords, words) in sites.vals()) {

      let metadata_sk = jointText(["host", host, "metadata"]);
      let new_metadata_attributes = switch (CanDB.get(db, {sk=metadata_sk})) {
        case (?entity) { // if the host already exsits,
          //wip
          // delete all word keys
          // update metadata attributes

          Debug.trap "";
        };
        case _ {
          let metadata_attributes = [
            ("pages",  #arrayText(pages)),
            ("titles", #arrayText(titles)),
            ("countOfWords", #arrayInt(countOfWords)),
            ("kindOfWords", #arrayInt(klindOfWords))
          ];
          metadata_attributes;
        };
      };

      buffer.add({sk=metadata_sk; attributes=new_metadata_attributes});

      for ((word, (tfs, idxs)) in words.vals()) {
        let sk = jointText(["word", word, "host", host]);
        let attributes = [
          ("tfs", #arrayFloat tfs),
          ("idxs", #arrayInt idxs)
        ];
        incWordCount(word);
        buffer.add({sk; attributes});
      };

      // if (not CanDB.skExists(db, sk)) host_count +=1; // this count is used for scan limit
    };

    return Buffer.toArray<CanDB.PutOptions>(buffer);
  };

  public func batchPut(sites :[(Host, [Path], [Title], [CountOfWord], [KindOfWord], [(Word, ([Tf], [PathIdx]))])]): async () {
    let batchOptions = createBatchOptions(sites);
    await* CanDB.batchPut(db, batchOptions);
  };


  /*-- Search --*/

  func compareEntity(a: Entity.Entity, b: Entity.Entity): Order.Order {
    Text.compare(a.sk, b.sk)
  };

  func setIntersect<T>(_a: [T], _b: [T], compare: (T, T)->Order.Order): [T]{
    let b = Buffer.fromArray<T>(_b);

    let set =  Buffer.Buffer<T>(_a.size());

    for (v in _a.vals()) {
      switch (Buffer.binarySearch<T>(v, b, compare)) {
        case (?_) {
          set.add(v);
        };
        case _ {};
      };
    };

    return Buffer.toArray<T>(set);
  };

  func compareHost(a: (Host, [(PathIdx, Tf)]), b: (Host, [(PathIdx, Tf)])): Order.Order {
    let (a_host, _) = a;
    let (b_host, _) = b;
    return Text.compare(a_host, b_host);
  };


  func comparePage(a: (PathIdx, Tf), b: (PathIdx, Tf)): Order.Order {
    let (a_pathIdx, _) = a;
    let (b_pathIdx, _) = b;
    return Nat.compare(a_pathIdx, b_pathIdx);
  };

  // [[(k1, a), (k2, b), (k3, c)],  [(k1, d), (k3, e)], [(k1, f), (k3, g)]] -> [[(k1, a), (k1, d), (k1, f)], [(k3, c), (k3, e), (k3, g)]]
  // Drop non-duplicated elements
  func drop<T>(arr: [[T]], compare: (T, T)->Order.Order): [[T]]{

    if (arr.size() == 0) return [];

    // Separate fist arr and rest arr
    let sub_arr = Array.subArray<[T]>(arr, 1, arr.size()-1);
    let a_arr = arr[0];

    let set = Buffer.Buffer<Buffer.Buffer<T>>(arr.size()); // [[T]]
    
    // If arr[1:] has elements of arr[0], put the values into the set buffer
    label A_VAL for (a_val in arr[0].vals()) {
      let set_sub = Buffer.Buffer<T>(arr.size());
      set_sub.add(a_val);

      for (b_arr:[T] in sub_arr.vals()) {
        let b_buf = Buffer.fromArray<T>(b_arr);
        switch (Buffer.binarySearch<T>(a_val, b_buf, compare)) {
          case (?b_arr_idx){
            let b_val = b_arr[b_arr_idx];
            set_sub.add(b_val);
          };
          case _ continue A_VAL; // if the b_buff does not have the a_val, skipt this a_val;
        }
      };

      set.add(set_sub);
    };

    return Array.map<Buffer.Buffer<T>, [T]>(Buffer.toArray<Buffer.Buffer<T>>(set), func (buf) {
      Buffer.toArray<T>(buf)
    });

  };

  type HitPagesOfHost = (Host, [(PathIdx, Tf)]);
  public query func search(words: [Word]): async [(Host, [(Title, Path, Int, Int, [Tf])])] { // Int: CountOfWord, Int: KindOfWord
    var hits: [var [HitPagesOfHost]] = Array.init<[HitPagesOfHost]>(words.size(), []);
    var word_idx = 0;
    for (word in words.vals()) {
      // Scan CanDB
      let skLowerBound = jointText(["word", word, "host", ""]);
      let skUpperBound = jointText(["word", word, "host", "~"]); // '~' is the last byte of ASCII
      let limit = host_count;
      let res = CanDB.scan(db, {
        skLowerBound;
        skUpperBound;
        limit;
        ascending = null;
      }); // returns { entities : [E.Entity]; nextKey : ?E.SK }

      // Hit pages per query words
      hits[word_idx] := Array.mapFilter<Entity.Entity, HitPagesOfHost>(res.entities, func(entity) {
        let host = Iter.toArray(Text.split(entity.sk, #text "#host#"))[1];
        let ziped = switch (
            Entity.getAttributeMapValueForKey(entity.attributes, "tfs"),
            Entity.getAttributeMapValueForKey(entity.attributes, "idxs")
        ) {
          case (?#arrayFloat(tfs), ?#arrayInt(idxs)) {
            Buffer.toArray<(Nat, Float)>(Buffer.zip<Nat, Float>(Buffer.fromArray<Nat>(Array.map<Int, Nat>(idxs, func(idx){Int.abs(idx)})), Buffer.fromArray<Float>(tfs)));
          };
          case _ return null;
        };
        return ?(host, ziped);
      });

      word_idx +=1;
    };

    // Drop the non-duplicated Hosts (set intersection)
    let hosts = drop<HitPagesOfHost>(Array.freeze<[HitPagesOfHost]>(hits), compareHost); // return [ [(Host1, [PathIdx, Tf]), (Host1, ...)],  [(Host2, [PathIdx, Tf]), (Host2, ...)]]
    if (hosts.size() == 0) return [];

    // Drop the non-duplicated Pages in Host (set intersection)
    // Note: the [Tf] are arranged in word order
    let set_hosts_pages = Buffer.Buffer<(Host, [[(PathIdx, Tf)]])>(hosts.size());
    label Hosts for (pagesOfHost in hosts.vals()) { // pagesOfHost: [(host, [(idx, tf)])]
      let (host, _) = pagesOfHost[0]; // the first element of tuples are all same host in this array: pagesOfHost.
      let pages_arr_buff = Buffer.Buffer<[(PathIdx, Tf)]>(pagesOfHost.size());
      for ((_, pages) in pagesOfHost.vals()) {
        pages_arr_buff.add(pages);
      };
      let pages_arr = Buffer.toArray<[(PathIdx, Tf)]>(pages_arr_buff);
      let set_pages = drop<(PathIdx, Tf)>(pages_arr, comparePage);
      if (set_pages.size() == 0) continue Hosts;
      set_hosts_pages.add((host, set_pages));
    };

    // Combine the pathIdx into one because the first elements of tuples are smae pathIdx in [(host, [(path1, [tf]), (path1, ...), (path1, ...)], [(path2, ...), (path2, ...)])]
    let zipedByPathIdx =  Buffer.mapFilter<(Host, [[(PathIdx, Tf)]]), (Host, [(PathIdx, [Tf])])>(set_hosts_pages, func((host, pages_tf)) {
      if (pages_tf.size() == 0) return null;
      let res = Buffer.Buffer<(PathIdx, [Tf])>(pages_tf.size());
      for (page in pages_tf.vals()) {
        if (page.size() == 0) return null;
        let (pathIdx, _) = page[0];
        let tfs = Buffer.Buffer<Tf>(page.size());
        for ((_, tf) in page.vals()) {
          tfs.add(tf);
        };
        res.add((pathIdx, Buffer.toArray<Tf>(tfs)));
      };
      return ?(host, Buffer.toArray<(PathIdx, [Tf])>(res));
    });

    // Resolve the PathIdx and titles. 
    let resolvedPath =  Buffer.mapFilter<(Host, [(PathIdx, [Tf])]), (Host, [(Title, Path, Int, Int, [Tf])])>(zipedByPathIdx, func((host, pages_tf)) {
      if (pages_tf.size() == 0) return null;

      // get host metadata entity
      let sk = jointText(["host", host, "metadata"]);
      let entity = switch (CanDB.get(db, {sk})) {
        case (?entity) entity;
        case _ return null;
      };
      // get titles and pages
      let (titles, page_paths, countOfWords, kindOfWords) = switch (
        Entity.getAttributeMapValueForKey(entity.attributes, "titles"),
        Entity.getAttributeMapValueForKey(entity.attributes, "pages"),
        Entity.getAttributeMapValueForKey(entity.attributes, "countOfWords"),
        Entity.getAttributeMapValueForKey(entity.attributes, "kindOfWords")
      ) {
        case (?#arrayText(titles), ?#arrayText(page_paths), ?#arrayInt(countOfWords), ?#arrayInt(kindOfWords)) (titles, page_paths, countOfWords, kindOfWords);
        case _ return null;
      };
      // access the titles and pages
      // put it togther
      let res = Buffer.Buffer<(Title, Path, Int, Int, [Tf])>(pages_tf.size());
      for ((pathIdx, tfs) in pages_tf.vals()) {
        if (tfs.size() == 0) return null;
        let (title, path) = (titles[pathIdx], page_paths[pathIdx]);
        let (countOfWord, kindOfWord) = (countOfWords[pathIdx], kindOfWords[pathIdx]);
        res.add((title, path, countOfWord, kindOfWord, tfs));
      };

      return ?(host, Buffer.toArray<(Title, Path, Int, Int, [Tf])>(res));
    });

    return Buffer.toArray<(Host, [(Title, Path, Int, Int, [Tf])])>(resolvedPath);
   };

}
