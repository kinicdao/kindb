import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import CanDB "mo:candb/CanDB";

// import Index "candb_index";

actor {
  public query func greet(name : Text) : async Text {
    "Hi, " # name # "!"
  };
  public query ({caller = caller}) func whoami(): async Text {
    Principal.toText(caller)
  };
  public query func whatistitlehash(): async Text {
    let titleSk       = jointText(["type", "app", "apptype" , "_apptype", "titlehash", "_titlehash", "score", "_score", "id", "_id"]);
    let tokens: [Text] = Iter.toArray(Text.split(titleSk, #char '#'));
    tokens[6]
  };

  func jointText(textArray: [Text]): Text {
    var result = "";
    for (t in textArray.vals()) {
      result := result # "#" # t;
    };
    result
  };
};
