import U "./utils";

// Vessel
import JSON "mo:json/JSON";
import LexEncode "mo:lexicographic-encoding/EncodeInt";

// Motoko base
import Debug "mo:base/Debug";

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

Debug.print("Success!");

// $(vessel bin)/moc $(vessel sources 2>/dev/null) src/canisters/test.mo -r --hide-warnings