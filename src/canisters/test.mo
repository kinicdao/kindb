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
    ("key2", #Boolean true)
  ]))
];
for ((key, json) in keyPairs.vals()) {
  ignore U.convertToAttribute(json)
};
// ignore U.convertToAttributeWithRequeiredKeys(keyPairs);
Debug.print("Success!");

// $(vessel bin)/moc $(vessel sources 2>/dev/null) src/canisters/test.mo -r --hide-warnings