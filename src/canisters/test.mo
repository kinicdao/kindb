import U "./utils";

// Vessel
import JSON "mo:json/JSON";
import LexEncode "mo:lexicographic-encoding/EncodeInt";

// Motoko base
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";

// Static Vals
func init() {
  let NAT32_MIN = 0;
  let NAT32_MAX = 4294967295; // 0xFFFFFFFF
  Debug.print("ENCODED_HASH_MIN: " # LexEncode.encodeInt(NAT32_MIN));
  Debug.print("ENCODED_HASH_MAX: " # LexEncode.encodeInt(NAT32_MAX));
  Debug.print("ENCODED_SCORE_MIN: " # LexEncode.encodeInt(0)); // Score with the highest confidence is '0' (= 100 - Score_raw) because sort is in ascending order.
  Debug.print("ENCODED_SCORE_MAX: " # LexEncode.encodeInt(100));
  Debug.print("ENCODED_DATALENGTH_MIN: " # LexEncode.encodeInt(0));
  Debug.print("ENCODED_DATALENGTH_MAX: " # LexEncode.encodeInt(NAT32_MAX));
};

// convertToAttributeWithRequeiredKeys
let keyPairs: [(Text, JSON.JSON)] = [
  ("String",  #String "string value"),
  ("Number",  #Number 0),
  ("Boolean", #Boolean true),
  ("Array Text", #Array([#String("0"), #String("1"), #String("2"),  #String("3")])),
  ("Object", #Object([
    ("key0", #String "string value"),
    ("key1", #Number 0),
    ("key2", #Boolean true),
    ("key3", #Array([#String("0"), #String("1"), #String("2"),  #String("3")]))
  ]))
];
for ((key, json) in keyPairs.vals()) {
  ignore U.convertToAttribute(json)
};

// convertToAttributeWithRequeiredKeys
ignore U.convertToAttributeWithRequeiredKeys([
  ("datalength", #Number 0),
  ("type", #String "app"),
  ("canisterid", #String "aaa-aa"),
  ("lastseen", #String "2022-05-09"),
  ("apptype", #String ""),
  ("status", #String ""),
  ("title", #String "test title"),
  ("subtitle", #String "test subtitle"),
  ("content", #String "test content"),
  ("note", #String ""),
  ("tf-idf", #Object([
    ("TITLES", #Array([#String "path0 title", #String "path1 title", #String "path2 title"])),
    ("PAGES", #Array([#String "path0 title", #String "path1 title", #String "path2 title"])),
    ("word1", #Array([#String "index tf-idf value", #String "index tf-idf value", #String "index tf-idf value"])),
    ("word2", #Array([#String "index tf-idf value", #String "index tf-idf value", #String "index tf-idf value"]))
  ]))
]);


// findTermInPlainText

assert(U.findTermInPlainText(
  [
    ("word1", 1.0),
    ("word2", 0.9)
  ],
  "plainText: Text,   word1"
) == 1.0);

assert(U.findTermInPlainText_AND(
  [
    [("word1", 1.0),("word2", 0.9)],
    [("word3", 1.0),("word4", 0.1)],
  ],
  "plainText: Text,   word2, word4"
) == 0.5);


// Tf
type PathIdx = Nat; // metadataに格納されているpages:[Path]のIndex
type Word = Text;
type Tf = Float; // idfはフロント側で計算すれば良いので
type Host = Text;
// Metadata
type Path = Text;
type Title = Text;

let a: [(Host, [(PathIdx, Tf)])] = [
  // ("h1", [(0, 0.1), (1, 0.2)]),
  // ("h2", [(0, 0.3), (1, 0.4)]),
  // ("h3",[(0, 0.5), (1, 0.6)])
  ("h1", [(0, 0.1)]),
  ("h2", [(0, 0.3)]),
  ("h3",[(0, 0.5)])
];

let b: [(Host, [(PathIdx, Tf)])] = [
  ("h1", [(0, 0.7), (1, 0.8)]),
  // ("h2", [(1, 0.9)]),
  // ("h3",[(0, 0.0)])
];

let hosts = U.drop<(Host, [(PathIdx, Tf)])>([a], U.compareHost);
Debug.print "\n";
Debug.print(debug_show(hosts));

// ホスト内のページの積集合を求める
let set_hosts_pages = Buffer.Buffer<(Host, [[(PathIdx, Tf)]])>(hosts.size());
label Hosts for (pagesOfHosts in hosts.vals()) {
  let (host, _) = pagesOfHosts[0];
  let pages_arr = Buffer.Buffer<[(PathIdx, Tf)]>(pagesOfHosts.size());
  for ((_, pages) in pagesOfHosts.vals()) {
    pages_arr.add(pages);
  };
  let set_pages = U.drop<(PathIdx, Tf)>(Buffer.toArray<[(PathIdx, Tf)]>(pages_arr), U.comparePage);
  if (set_pages.size() == 0) continue Hosts;
  set_hosts_pages.add((host, set_pages));
  // Debug.print(debug_show(set_pages));
};
Debug.print "\n";
Debug.print(debug_show(Buffer.toArray<(Host, [[(PathIdx, Tf)]])>(set_hosts_pages)));

// PathIdx同士をまとめる。[Tf]はwordの順番に並んでいる。
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
Debug.print "\n";
Debug.print(debug_show(Buffer.toArray<(Host, [(PathIdx, [Tf])])>(zipedByPathIdx)));



// for (pagesOfHosts in set.vals()) {
//   let pages_arr = Buffer.Buffer<[(PathIdx, Tf)]>(pagesOfHosts.size());
//   for ((_, pages) in pagesOfHosts.vals()) {
//     pages_arr.add(pages);
//   };
//   let set_pages = U.drop<(PathIdx, Tf)>(Buffer.toArray<[(PathIdx, Tf)]>(pages_arr), U.comparePage);
//   Debug.print(debug_show(set_pages));
// };


Debug.print("Success!");

// $(vessel bin)/moc $(vessel sources 2>/dev/null) src/canisters/test.mo -r --hide-warnings