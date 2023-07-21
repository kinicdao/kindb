import CA "mo:candb/CanisterActions";
import CanDB "mo:candb/CanDB";
import Entity "mo:candb/Entity";
import Prelude "mo:base/Prelude";

// Motoko Base
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
import Result "mo:base/Result";

import LexEncode "mo:lexicographic-encoding/EncodeInt";
import JSON "mo:json/JSON";
import DateTime "mo:DateTime/DateTime";

import RBT "mo:stable-rbtree/StableRBTree";
import Parser "mo:parser-combinators/Parser";


module {

  let NAT32_MIN = 0;
  let NAT32_MAX = 4294967295; // 0xFFFFFFFF
  let ENCODED_HASH_MIN = "00"; // LexEncode.encodeInt(NAT32_MIN);
  let ENCODED_HASH_MAX = "feffffff04"; // LexEncode.encodeInt(NAT32_MAX);
  let ENCODED_SCORE_MIN = "00"; // LexEncode.encodeInt(0); // Score with the highest confidence is '0' (= 100 - Score_raw) because sort is in ascending order.
  let ENCODED_SCORE_MAX = "64"; // LexEncode.encodeInt(100);
  let ENCODED_DATALENGTH_MIN = "00"; // LexEncode.encodeInt(0);
  let ENCODED_DATALENGTH_MAX = "feffffff04"; // LexEncode.encodeInt(NAT32_MAX);

  public func convertToAttribute(json: JSON.JSON): Entity.AttributeValue {
    switch (json) {
      case (#Null    _)  Debug.trap "not supported for Null";
      case (#String  v) #text v;
      case (#Number  v) #int v;
      case (#Boolean v) #bool v;
      case (#Object  v) { // v: [(Text, JSON)]
        var rbtree = RBT.init<Text, Entity.AttributeValueRBTreeValue>();
        for ((key, value) in v.vals()) {
          switch (value) {
            case (#String  v) rbtree := RBT.put(rbtree, Text.compare, key, #text v);
            case (#Number  v) rbtree := RBT.put(rbtree, Text.compare, key, #int v);
            case (#Boolean v) rbtree := RBT.put(rbtree, Text.compare, key, #bool v);
            case _ Debug.trap "not supported for Array & Object in Object"; //wip
          }
        };
        #tree rbtree;
      };
      case (#Array   v) { // v: [JSON]
        #arrayText(Array.map<JSON.JSON, Text>(v, func(elm) {
          switch (elm) {
            case (#String s) s;
            case _ Debug.trap "not supported for Array except for Text type"; //wip
          }
        }));
      };
    };
  };

  public func convertToAttributeWithRequeiredKeys(kvPairs: [(Text, JSON.JSON)]):
    (
      {
      type_:      Text;
      canisterid: Text;
      lastseen:   Text;
      titlehash:  Text;
      apptype:    Text;
      status:     Text;
      datalength: Text;
      canisteridlength: Nat;
      titlelength:    Nat;
      subtitlelength: Nat;
      contentlength:  Nat;
      notelength:     Nat;
      },
      [(Text, Entity.AttributeValue)]
    )
  {
    let metadataAttributes = Buffer.Buffer<(Text, Entity.AttributeValue)>(kvPairs.size());

    // requeired keys
    var type_null:       ?Text = null;
    var canisterid_null: ?Text = null;
    var lastseen:   Text = "2000-01-01";
    var titlehash:  Text = ENCODED_HASH_MIN;
    var apptype:    Text = "null"; // Attribute Type has no NULL type
    var status:     Text = "null"; 
    var datalength: Text = ENCODED_DATALENGTH_MIN;
    // metadata
    var canisteridlength: Nat = 0;
    var titlelength:    Nat = 0;
    var subtitlelength: Nat = 0;
    var contentlength:  Nat = 0;
    var notelength:     Nat = 0;

    label ConvertToAttribute for ((key, value) in kvPairs.vals()) {
      let attribute = switch value {
        case (#Null _) continue ConvertToAttribute; // Null type is not supported for CanDB Attribute. so we represent null as empty
        case _ convertToAttribute(value);
      };
      // check required keys. if null, do not assign to requeired keys
      // all text will converted to lower case
      // if the text is empty, treat as null (continue ConvertToAttribute)
      switch (key, attribute) {
        case ("datalength", #int  v) datalength :=  LexEncode.encodeInt v;
        case ("type",       #text v) if (v=="") continue ConvertToAttribute else type_null   := ?v; // if v is empty text, treat as null
        case ("canisterid", #text v) if (v=="") continue ConvertToAttribute else {
          canisteridlength := v.size();
          canisterid_null := ?Text.map(v , Prim.charToLower);
        };
        case ("lastseen",   #text v) if (v=="") continue ConvertToAttribute else lastseen   := Text.map(v , Prim.charToLower);
        case ("apptype",    #text v) if (v=="") continue ConvertToAttribute else apptype    := Text.map(v , Prim.charToLower);
        case ("status",     #text v) if (v=="") continue ConvertToAttribute else status     := Text.map(v , Prim.charToLower); // status is used for score
        case ("title",      #text v) if (v=="") continue ConvertToAttribute else {
          titlelength := v.size();
          titlehash  := LexEncode.encodeInt(Nat32.toNat(Text.hash(Text.map(v , Prim.charToLower))));
        };
        
        // get length
        case ("subtitle",   #text v) if (v=="") continue ConvertToAttribute else subtitlelength := v.size();
        case ("content",    #text v) if (v=="") continue ConvertToAttribute else contentlength  := v.size();
        case ("note",       #text v) if (v=="") continue ConvertToAttribute else notelength     := v.size();

        case (_) {};
      };
      metadataAttributes.add((key, attribute)); // Duplicate keys are overwritten
    };
    // Check requeired keys
    let (type_, canisterid) = switch (type_null, canisterid_null) {
      case (?t, ?c) (t, c);
      case _ Debug.trap "must include \"type\", \"canisterid\"";
    };

    return
    (
      {
        type_:      Text;
        canisterid: Text;
        lastseen:   Text;
        titlehash:  Text;
        apptype:    Text;
        status:     Text;
        datalength: Text;
        canisteridlength: Nat;
        titlelength:    Nat;
        subtitlelength: Nat;
        contentlength:  Nat;
        notelength:     Nat;
      }, 
      Buffer.toArray(metadataAttributes)
    );

  };

}