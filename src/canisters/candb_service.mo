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

  */

  /*-- Search --*/
  let NAT32_MIN = 0;
  let NAT32_MAX = 4294967295; // 0xFFFFFFFF
  let ENCODED_HASH_MIN = LexEncode.encodeInt(NAT32_MIN);
  let ENCODED_HASH_MAX = LexEncode.encodeInt(NAT32_MAX);
  let ENCODED_SCORE_MIN = LexEncode.encodeInt(0); // Score with the highest confidence is '0' (= 100 - Score_raw) because sort is in ascending order.
  let ENCODED_SCORE_MAX = LexEncode.encodeInt(100);
  let ENCODED_DATALENGTH_MIN = LexEncode.encodeInt(0);
  let ENCODED_DATALENGTH_MAX = LexEncode.encodeInt(NAT32_MAX);

  stable var JsonKeys = [ // For output json keys
    "canisterid",
    "subnetid",
    "type",
    "datalength",
    "lastseen",
    "title",
    "subtitle",
    "content",
    "apptype",
    "note",
    "status",
    "notnull",
    "brokencount"
  ];

  // Make ScanOptions. startSk is nextKey which is returnd with last scan call
  func titleScanOptionsByApptype(apptype: Text, limit: Nat, startSk: ?Text): CanDB.ScanOptions {
    let skLowerBound = jointText(["type", "app", "apptype" , apptype, "titlehash", ENCODED_HASH_MIN, "score", ENCODED_SCORE_MIN, "canisterid", ""]);
    var skUpperBound = jointText(["type", "app", "apptype" , apptype, "titlehash", ENCODED_HASH_MAX, "score", ENCODED_SCORE_MAX, "canisterid", "~"]); // '~' is the last byte of ASCII
    switch (startSk) {
      case (?startSk) skUpperBound := startSk;
      case null {}
    };
    let scanOptions = {
      skLowerBound;
      skUpperBound;
      limit = limit;
      ascending = ?false;
    };
  };
  func lastseenScanOptions(apptype: Text, limit: Nat, startSk: ?Text): CanDB.ScanOptions {
    let skLowerBound = jointText(["type", "app", "apptype" , apptype, "lastseen", ""]);
    var skUpperBound = jointText(["type", "app", "apptype" , apptype, "lastseen", "~"]); // '~' is the last byte of ASCII
    switch (startSk) {
      case (?startSk) skUpperBound := startSk;
      case null {};
    };
    let scanOptions = {
      skLowerBound;
      skUpperBound;
      limit = limit;
      ascending = ?false; //search from newest
    };
  };
  func termScanOptions(limit: Nat, startSk: ?Text): CanDB.ScanOptions {
    let skLowerBound = jointText(["type", "app", "score", ENCODED_SCORE_MIN, "datalength", ENCODED_DATALENGTH_MIN, "canisterid", ""]);
    var skUpperBound = jointText(["type", "app", "score", ENCODED_SCORE_MAX, "datalength", ENCODED_DATALENGTH_MAX, "canisterid", "~"]); // '~' is the last byte of ASCII
    switch (startSk) {
      case (?startSk) skUpperBound := startSk;
      case null {};
    };
    let scanOptions = {
      skLowerBound;
      skUpperBound;
      limit = limit;
      ascending = ?false; //search from newest
    };
  };

  // Convert Type:Attribute to Type:JSON. Search "keys"(the second arg) and convet it to JSON. if no key, the value will be null.
  func attributeMapToJsonByKeys(attributeMap: Entity.AttributeMap, keys: [Text]): JSON.JSON {
    let keyvalues = Buffer.Buffer<(Text, JSON.JSON)>(keys.size());
    for (key in keys.vals()) {
      let value = switch (Entity.getAttributeMapValueForKey(attributeMap, key)) {
        case null        #Null;
        case (?#text v)  #String  v;
        case (?#int  v)  #Number  v;
        case (?#bool v)  #Boolean v;
        // TODO
        // case (?#float(v)) 
        // case (?#blob(v)) { };
        // case (?#tuple(v)) { };
        // case (?#arrayText(v)) { };
        // case (?#arrayInt(v)) { };
        // case (?#arrayBool(v)) { };
        // case (?#arrayFloat(v)) { };
        // case (?#tree(v)) { };
        case (?v) {
          Debug.print("not suported yet");
          #String(debug_show(v));
        };
      };
      keyvalues.add((key, value))
    };
    return #Object(Buffer.toArray(keyvalues))
  };

  // SQL: select distinct on(title) * from canisters where type = 'app' AND apptype = $1 ORDER BY title LIMIT 300
  // [Attention] Not in dictionary order by title. The title is hashed.
  public query func searchCategory(apptype: Text, startSk: ?Text): async (Text, ?Text) {
    let limit = 300;
    let buffer = Buffer.Buffer<JSON.JSON>(limit);
    let scanResult = CanDB.scan(db, titleScanOptionsByApptype(apptype, limit, startSk));
    var prevTitlehash = ENCODED_HASH_MIN;
    label DistinctOnTitle for (entity in scanResult.entities.vals()) {
      let tokens: [Text] = Iter.toArray(Text.split(entity.sk, #char '#'));
      // if (10 > tokens.size()) continue DistinctOnTitle;
      // if (tokens[5] != "titlehash") continue DistinctOnTitle;
      let titlehash = tokens[6];
      if (prevTitlehash == titlehash) continue DistinctOnTitle;

      let metadataSk: Text = switch (Entity.getAttributeMapValueForKey(entity.attributes, "metadataSk")) {
        case (?(#text sk)) sk;
        case _ continue DistinctOnTitle;
      };
      let attributemap = switch(CanDB.get(db, {sk = metadataSk})) {
        case (?entity) entity.attributes;
        case null continue DistinctOnTitle;
      };
      buffer.add(attributeMapToJsonByKeys(attributemap, JsonKeys));
      prevTitlehash := titlehash; // skip same title after this
    };
    return (JSON.show(#Array(Buffer.toArray(buffer))), scanResult.nextKey);
  };


  // SQL: select * from canisters where type = 'app' AND apptype = $1 ORDER BY lastseen DESC LIMIT 30
  public query func categorySearchNewest(apptype: Text, startSK: ?Text): async (Text, ?Text) {
    let limit = 60;
    let buffer = Buffer.Buffer<JSON.JSON>(limit); // WIP limit
    let scanResult = CanDB.scan(db, lastseenScanOptions(apptype, limit, startSK));
    label LastseenLoop for (entity in scanResult.entities.vals()) {

      let metadataSk: Text = switch (Entity.getAttributeMapValueForKey(entity.attributes, "metadataSk")) {
        case (?(#text sk)) sk;
        case _ continue LastseenLoop;
      };
      let attributemap = switch(CanDB.get(db, {sk = metadataSk})) {
        case (?entity) entity.attributes;
        case null continue LastseenLoop;
      };
      buffer.add(attributeMapToJsonByKeys(attributemap, JsonKeys));
    };
    return (JSON.show(#Array(Buffer.toArray(buffer))), scanResult.nextKey);
  };

  // SELECT * FROM canisters WHERE type = 'app' AND (title ILIKE '%" + term + "%' OR content ILIKE '%" + term + "%' OR subtitle ILIKE '%" + p.Category + "%') LIMIT 300;
  // If there are no results we search again 
  // newCat := longestWord(term)
  // SELECT * FROM canisters WHERE type = 'app' AND (title ILIKE '%" + newCat + "%' OR content ILIKE '%" + newCat + "%' OR subtitle ILIKE '%" + newCat + "%') LIMIT 300;
  public query func searchTerm(term: Text, startSK: ?Text): async (Text, ?Text) {
    let limit = 300;
    let scanResult = CanDB.scan(db, termScanOptions(limit, startSK));
    let buffer = Buffer.Buffer<JSON.JSON>(limit); // WIP limit
    let term_lowcase = Text.map(term , Prim.charToLower);
    label SearchLoop for (entity in scanResult.entities.vals()) {

      // For case-sensitive hits, use Text.map(text , Prim.charToLower)
      label FindTerm {
        switch(Entity.getAttributeMapValueForKey(entity.attributes, "title")) {
          case (?#text v) if (Text.contains(Text.map(v , Prim.charToLower), #text term_lowcase)) break FindTerm;
          case _ {};
        };
        switch(Entity.getAttributeMapValueForKey(entity.attributes, "subtilte")) {
          case (?#text v) if (Text.contains(Text.map(v , Prim.charToLower), #text term_lowcase)) break FindTerm;
          case _ {};
        };
        switch(Entity.getAttributeMapValueForKey(entity.attributes, "content")) {
          case (?#text v) if (Text.contains(Text.map(v , Prim.charToLower), #text term_lowcase)) break FindTerm;
          case _ {};
        };
        continue SearchLoop; // No hit, goto next.
      };
      buffer.add(attributeMapToJsonByKeys(entity.attributes, JsonKeys));
    };
    return (JSON.show(#Array(Buffer.toArray(buffer))), scanResult.nextKey);
  };

  // searchID #THIS TAKES THE ID AND RETURNS ONE THING
  // select * from canisters where type = 'app' AND canisterid = $1 LIMIT 1
  public query func searchCanisterId(canisterid: Text): async Text {
    let sk = jointText(["canisterid", canisterid]);
    var entity = switch(CanDB.get(db, {sk})) {
      case (?entity) entity;
      case null return JSON.show(#Null);
    };
    entity := switch (Entity.getAttributeMapValueForKey(entity.attributes, "metadataSk")) {
      case (?#text sk) switch (CanDB.get(db, {sk})) {
        case (?entity) entity;
        case null return JSON.show(#Null);
      };
      case _ return JSON.show(#Null);
    };
    let json = attributeMapToJsonByKeys(entity.attributes, JsonKeys);
    JSON.show json
  };


  /*-- Insert --*/

  func convertToAttributeWithRequeiredKeys(kvPairs: [(Text, JSON.JSON)]):
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
      let attribute = switch (value) {
        case (#Null    _) continue ConvertToAttribute;
        case (#String  v) #text v;
        case (#Number  v) #int v;
        case (#Boolean v) #bool v;
        case (#Object  v) Debug.trap "not supported"; //wip
        case (#Array   v) Debug.trap "not supported"; //wip
      };
      // check required keys. if null, do not assign to requeired keys
      // all text will converted to lower case
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

func batchInsert(inputJsonText: Text): async () {

    let inputJson = switch (JSON.parse inputJsonText) {
      case (?j) j;
      case null {Debug.trap "can't parse"; #Null};
    };

    let records = switch (inputJson) {
      case (#Array v) v;
      case _          Debug.trap "top level format must be array";
    };

    let batchOptions = Buffer.Buffer<CanDB.PutOptions>(records.size());
    for (record in records.vals()) {
      let kvPairs = switch (record) {
        case (#Object v)  v;
        case _            Debug.trap "second level format must be object";
      };
      
      let (metadata, metadataAttributes) = convertToAttributeWithRequeiredKeys(kvPairs);

      let (titleSk, lastseenSk, termSk, canisteridSk) =  switch (metadata.type_) {
        case "app" {
          let score = LexEncode.encodeInt(if (metadata.status == "official") 50 else 0); // if Official, the score is 50
          let titleSk       = jointText(["type", "app", "apptype" , metadata.apptype, "titlehash", metadata.titlehash, "score", score, "canisterid", metadata.canisterid]);
          let lastseenSk    = jointText(["type", "app", "apptype" , metadata.apptype, "lastseen", metadata.lastseen, "canisterid", metadata.canisterid]);
          let termSk        = jointText(["type", "app", "score", score, "datalength", metadata.datalength, "canisterid", metadata.canisterid]);
          let canisteridSk  = jointText(["canisterid", metadata.canisterid]);
          (titleSk, lastseenSk, termSk, canisteridSk)
        };
        case _ {
          let titleSk       = jointText(["type", metadata.type_, "titlehash", ENCODED_HASH_MIN, "canisterid", metadata.canisterid]);
          let lastseenSk    = jointText(["type", metadata.type_, "lastseen", metadata.lastseen, "canisterid", metadata.canisterid]);
          let termSk        = jointText(["type", metadata.type_, "score", ENCODED_SCORE_MIN, "datalength", ENCODED_DATALENGTH_MIN, "canisterid", metadata.canisterid]);
          let canisteridSk  = jointText(["canisterid", metadata.canisterid]);
          (titleSk, lastseenSk, termSk, canisteridSk)
        }
      };

      // If already exists, change the old key (Value is changed by batchPut)
      switch (CanDB.get(db, {sk = canisteridSk})) { // if already exist
        case (?entity) {
          // subsituate keys
          switch (Entity.getAttributeMapValueForKey(entity.attributes, "titleSk")) {
            case (?(#text(oldTitleSk))) {
              ignore CanDB.substituteKey(db, {oldSK = oldTitleSk; newSK = titleSk}); // replace old title key
              // switch (CanDB.get(db, {sk=oldTitleSk})) {case (?_) Debug.trap "error substituteKey"; case _ {Debug.print("ok substituteKey")}};
            };
            case _ {};
          };
          switch (Entity.getAttributeMapValueForKey(entity.attributes, "lastseenSk"),) {
            case (?(#text(oldLastseenSk))) ignore CanDB.substituteKey(db, {oldSK = oldLastseenSk; newSK = lastseenSk}); // replace old lastseen key
            case _ {};
          };
          switch (Entity.getAttributeMapValueForKey(entity.attributes, "termSk")) {
            case (?(#text(oldTermSk))) ignore CanDB.substituteKey(db, {oldSK = oldTermSk; newSK = termSk}); // replace old term key
            case _ {};
          };
        };
        case null {};
      };

      let metadataSk = termSk;
      batchOptions.add({ sk = titleSk;      attributes = [("metadataSk", #text metadataSk)] });
      batchOptions.add({ sk = lastseenSk;   attributes = [("metadataSk", #text metadataSk)] });
      batchOptions.add({ sk = termSk;       attributes = metadataAttributes }); // metadata is under termSk
      batchOptions.add({ sk = canisteridSk; attributes = [("metadataSk", #text metadataSk), ("titleSk", #text titleSk), ("lastseenSk", #text lastseenSk), ("termSk", #text termSk), ("type", #text(metadata.type_))] });
    };

    // batch insert
    await* CanDB.batchPut(db, Buffer.toArray(batchOptions));
  };
  

  func isOwner(caller: Principal): Bool {
    if (Principal.isAnonymous(caller)) return false;
    switch (owners) {
      case (?owners) {
        for (o in owners.vals()) {
          if (o == caller) return true
        };
        return false
      };
      case null return false
    }
  };

  // Only Use Owner, no check duplications of canisterid with other scaled canisters
  public shared({caller = caller}) func upload(inputJsonText: Text): async () {
    // auth owner
    if (not isOwner(caller)) throw Error.reject("not authorized");

    await batchInsert(inputJsonText);
  };

  type AppType = {
    #blog;
    #communication;
    #dao;
    #defi;
    #docs;
    #funny;
    #interesting;
    #investor;
    #portfolio;
    #landing;
    #learning;
    #music;
    #news;
    #social;
    #utility;
    #video;
    #wip;
    #info;
    #scam;
  };
  func getApptype(apptype: AppType): Text {
    switch (apptype) {
      case (#blog)          "blog";
      case (#communication) "communication";
      case (#dao)           "dao";
      case (#defi)          "defi";
      case (#docs)          "docs";
      case (#funny)         "funny";
      case (#interesting)   "interesting";
      case (#investor)      "investor";
      case (#portfolio)     "portfolio";
      case (#landing)       "landing";
      case (#learning)      "learning";
      case (#music)         "music";
      case (#news)          "news";
      case (#social)        "social";
      case (#utility)       "utility";
      case (#video)         "video";
      case (#wip)           "wip";
      case (#info)          "info";
      case (#scam)          "scam";
    };
  };
  type SubnetId = {
    #subnetId__qdvhd_os4o2_zzrdw_xrcv4_gljou_eztdp_bj326_e6jgr_tkhuc_ql6v2_yqe;
    #subnetId__mpubz_g52jc_grhjo_5oze5_qcj74_sex34_omprz_ivnsm_qvvhr_rfzpv_vae;
    #subnetId__brlsh_zidhj_3yy3e_6vqbz_7xnih_xeq2l_as5oc_g32c4_i5pdn_2wwof_oae;
    #subnetId__lhg73_sax6z_2zank_6oer2_575lz_zgbxx_ptudx_5korm_fy7we_kh4hl_pqe;
    #subnetId__lspz2_jx4pu_k3e7p_znm7j_q4yum_ork6e_6w4q6_pijwq_znehu_4jabe_kqe;
    #subnetId__shefu_t3kr5_t5q3w_mqmdq_jabyv_vyvtf_cyyey_3kmo4_toyln_emubw_4qe;
    #subnetId__pae4o_o6dxf_xki7q_ezclx_znyd6_fnk6w_vkv5z_5lfwh_xym2i_otrrw_fqe;
    #subnetId__ejbmu_grnam_gk6ol_6irwa_htwoj_7ihfl_goimw_hlnvh_abms4_47v2e_zqe;
    #subnetId__w4asl_4nmyj_qnr7c_6cqq4_tkwmt_o26di_iupkq_vx4kt_asbrx_jzuxh_4ae;
    #subnetId__qxesv_zoxpm_vc64m_zxguk_5sj74_35vrb_tbgwg_pcird_5gr26_62oxl_cae;
    #subnetId__snjp4_xlbw4_mnbog_ddwy6_6ckfd_2w5a2_eipqo_7l436_pxqkh_l6fuv_vae;
    #subnetId__io67a_2jmkw_zup3h_snbwi_g6a5n_rm5dn_b6png_lvdpl_nqnto_yih6l_gqe;
    #subnetId__eq6en_6jqla_fbu5s_daskr_h6hx2_376n5_iqabl_qgrng_gfqmv_n3yjr_mqe; 
    #subnetId__o3ow2_2ipam_6fcjo_3j5vt_fzbge_2g7my_5fz2m_p4o2t_dwlc4_gt2q7_5ae; 
    #subnetId__k44fs_gm4pv_afozh_rs7zw_cg32n_u7xov_xqyx3_2pw5q_eucnu_cosd4_uqe;
    #subnetId__5kdm2_62fc6_fwnja_hutkz_ycsnm_4z33i_woh43_4cenu_ev7mi_gii6t_4ae;
    #subnetId__pjljw_kztyl_46ud4_ofrj6_nzkhm_3n4nt_wi3jt_ypmav_ijqkt_gjf66_uae;
    #subnetId__gmq5v_hbozq_uui6y_o55wc_ihop3_562wb_3qspg_nnijg_npqp5_he3cj_3ae;
    #subnetId__6pbhf_qzpdk_kuqbr_pklfa_5ehhf_jfjps_zsj6q_57nrl_kzhpd_mu7hc_vae;
    #subnetId__e66qm_3cydn_nkf4i_ml4rb_4ro6o_srm5s_x5hwq_hnprz_3meqp_s7vks_5qe;
    #subnetId__yinp6_35cfo_wgcd2_oc4ty_2kqpf_t4dul_rfk33_fsq3r_mfmua_m2ngh_jqe;
    #subnetId__cv73p_6v7zi_u67oy_7jc3h_qspsz_g5lrj_4fn7k_xrax3_thek2_sl46v_jae;
    #subnetId__opn46_zyspe_hhmyp_4zu6u_7sbrh_dok77_m7dch_im62f_vyimr_a3n2c_4ae;
    #subnetId__4ecnw_byqwz_dtgss_ua2mh_pfvs7_c3lct_gtf4e_hnu75_j7eek_iifqm_sqe;
    #subnetId__nl6hn_ja4yw_wvmpy_3z2jx_ymc34_pisx3_3cp5z_3oj4a_qzzny_jbsv3_4qe;
    #subnetId__jtdsg_3h6gi_hs7o5_z2soi_43w3z_soyl3_ajnp3_ekni5_sw553_5kw67_nqe;
    #subnetId__3hhby_wmtmw_umt4t_7ieyg_bbiig_xiylg_sblrt_voxgt_bqckd_a75bf_rqe;
    #subnetId__csyj4_zmann_ys6ge_3kzi6_onexi_obayx_2fvak_zersm_euci4_6pslt_lae;
    #subnetId__4zbus_z2bmt_ilreg_xakz4_6tyre_hsqj4_slb4g_zjwqo_snjcc_iqphi_3qe;
  };
  func getSubnetId(subnetId: SubnetId): Text {
    switch (subnetId) {
    case (#subnetId__qdvhd_os4o2_zzrdw_xrcv4_gljou_eztdp_bj326_e6jgr_tkhuc_ql6v2_yqe) "qdvhd-os4o2-zzrdw-xrcv4-gljou-eztdp-bj326-e6jgr-tkhuc-ql6v2-yqe";
    case (#subnetId__mpubz_g52jc_grhjo_5oze5_qcj74_sex34_omprz_ivnsm_qvvhr_rfzpv_vae) "mpubz-g52jc-grhjo-5oze5-qcj74-sex34-omprz-ivnsm-qvvhr-rfzpv-vae";
    case (#subnetId__brlsh_zidhj_3yy3e_6vqbz_7xnih_xeq2l_as5oc_g32c4_i5pdn_2wwof_oae) "brlsh-zidhj-3yy3e-6vqbz-7xnih-xeq2l-as5oc-g32c4-i5pdn-2wwof-oae";
    case (#subnetId__lhg73_sax6z_2zank_6oer2_575lz_zgbxx_ptudx_5korm_fy7we_kh4hl_pqe) "lhg73-sax6z-2zank-6oer2-575lz-zgbxx-ptudx-5korm-fy7we-kh4hl-pqe";
    case (#subnetId__lspz2_jx4pu_k3e7p_znm7j_q4yum_ork6e_6w4q6_pijwq_znehu_4jabe_kqe) "lspz2-jx4pu-k3e7p-znm7j-q4yum-ork6e-6w4q6-pijwq-znehu-4jabe-kqe";
    case (#subnetId__shefu_t3kr5_t5q3w_mqmdq_jabyv_vyvtf_cyyey_3kmo4_toyln_emubw_4qe) "shefu-t3kr5-t5q3w-mqmdq-jabyv-vyvtf-cyyey-3kmo4-toyln-emubw-4qe";
    case (#subnetId__pae4o_o6dxf_xki7q_ezclx_znyd6_fnk6w_vkv5z_5lfwh_xym2i_otrrw_fqe) "pae4o-o6dxf-xki7q-ezclx-znyd6-fnk6w-vkv5z-5lfwh-xym2i-otrrw-fqe";
    case (#subnetId__ejbmu_grnam_gk6ol_6irwa_htwoj_7ihfl_goimw_hlnvh_abms4_47v2e_zqe) "ejbmu-grnam-gk6ol-6irwa-htwoj-7ihfl-goimw-hlnvh-abms4-47v2e-zqe";
    case (#subnetId__w4asl_4nmyj_qnr7c_6cqq4_tkwmt_o26di_iupkq_vx4kt_asbrx_jzuxh_4ae) "w4asl-4nmyj-qnr7c-6cqq4-tkwmt-o26di-iupkq-vx4kt-asbrx-jzuxh-4ae";
    case (#subnetId__qxesv_zoxpm_vc64m_zxguk_5sj74_35vrb_tbgwg_pcird_5gr26_62oxl_cae) "qxesv-zoxpm-vc64m-zxguk-5sj74-35vrb-tbgwg-pcird-5gr26-62oxl-cae";
    case (#subnetId__snjp4_xlbw4_mnbog_ddwy6_6ckfd_2w5a2_eipqo_7l436_pxqkh_l6fuv_vae) "snjp4-xlbw4-mnbog-ddwy6-6ckfd-2w5a2-eipqo-7l436-pxqkh-l6fuv-vae";
    case (#subnetId__io67a_2jmkw_zup3h_snbwi_g6a5n_rm5dn_b6png_lvdpl_nqnto_yih6l_gqe) "io67a-2jmkw-zup3h-snbwi-g6a5n-rm5dn-b6png-lvdpl-nqnto-yih6l-gqe";
    case (#subnetId__eq6en_6jqla_fbu5s_daskr_h6hx2_376n5_iqabl_qgrng_gfqmv_n3yjr_mqe) "eq6en-6jqla-fbu5s-daskr-h6hx2-376n5-iqabl-qgrng-gfqmv-n3yjr-mqe"; 
    case (#subnetId__o3ow2_2ipam_6fcjo_3j5vt_fzbge_2g7my_5fz2m_p4o2t_dwlc4_gt2q7_5ae) "o3ow2-2ipam-6fcjo-3j5vt-fzbge-2g7my-5fz2m-p4o2t-dwlc4-gt2q7-5ae"; 
    case (#subnetId__k44fs_gm4pv_afozh_rs7zw_cg32n_u7xov_xqyx3_2pw5q_eucnu_cosd4_uqe) "k44fs-gm4pv-afozh-rs7zw-cg32n-u7xov-xqyx3-2pw5q-eucnu-cosd4-uqe";
    case (#subnetId__5kdm2_62fc6_fwnja_hutkz_ycsnm_4z33i_woh43_4cenu_ev7mi_gii6t_4ae) "5kdm2-62fc6-fwnja-hutkz-ycsnm-4z33i-woh43-4cenu-ev7mi-gii6t-4ae";
    case (#subnetId__pjljw_kztyl_46ud4_ofrj6_nzkhm_3n4nt_wi3jt_ypmav_ijqkt_gjf66_uae) "pjljw-kztyl-46ud4-ofrj6-nzkhm-3n4nt-wi3jt-ypmav-ijqkt-gjf66-uae";
    case (#subnetId__gmq5v_hbozq_uui6y_o55wc_ihop3_562wb_3qspg_nnijg_npqp5_he3cj_3ae) "gmq5v-hbozq-uui6y-o55wc-ihop3-562wb-3qspg-nnijg-npqp5-he3cj-3ae";
    case (#subnetId__6pbhf_qzpdk_kuqbr_pklfa_5ehhf_jfjps_zsj6q_57nrl_kzhpd_mu7hc_vae) "6pbhf-qzpdk-kuqbr-pklfa-5ehhf-jfjps-zsj6q-57nrl-kzhpd-mu7hc-vae";
    case (#subnetId__e66qm_3cydn_nkf4i_ml4rb_4ro6o_srm5s_x5hwq_hnprz_3meqp_s7vks_5qe) "e66qm-3cydn-nkf4i-ml4rb-4ro6o-srm5s-x5hwq-hnprz-3meqp-s7vks-5qe";
    case (#subnetId__yinp6_35cfo_wgcd2_oc4ty_2kqpf_t4dul_rfk33_fsq3r_mfmua_m2ngh_jqe) "yinp6-35cfo-wgcd2-oc4ty-2kqpf-t4dul-rfk33-fsq3r-mfmua-m2ngh-jqe";
    case (#subnetId__cv73p_6v7zi_u67oy_7jc3h_qspsz_g5lrj_4fn7k_xrax3_thek2_sl46v_jae) "cv73p-6v7zi-u67oy-7jc3h-qspsz-g5lrj-4fn7k-xrax3-thek2-sl46v-jae";
    case (#subnetId__opn46_zyspe_hhmyp_4zu6u_7sbrh_dok77_m7dch_im62f_vyimr_a3n2c_4ae) "opn46-zyspe-hhmyp-4zu6u-7sbrh-dok77-m7dch-im62f-vyimr-a3n2c-4ae";
    case (#subnetId__4ecnw_byqwz_dtgss_ua2mh_pfvs7_c3lct_gtf4e_hnu75_j7eek_iifqm_sqe) "4ecnw-byqwz-dtgss-ua2mh-pfvs7-c3lct-gtf4e-hnu75-j7eek-iifqm-sqe";
    case (#subnetId__nl6hn_ja4yw_wvmpy_3z2jx_ymc34_pisx3_3cp5z_3oj4a_qzzny_jbsv3_4qe) "nl6hn-ja4yw-wvmpy-3z2jx-ymc34-pisx3-3cp5z-3oj4a-qzzny-jbsv3-4qe";
    case (#subnetId__jtdsg_3h6gi_hs7o5_z2soi_43w3z_soyl3_ajnp3_ekni5_sw553_5kw67_nqe) "jtdsg-3h6gi-hs7o5-z2soi-43w3z-soyl3-ajnp3-ekni5-sw553-5kw67-nqe";
    case (#subnetId__3hhby_wmtmw_umt4t_7ieyg_bbiig_xiylg_sblrt_voxgt_bqckd_a75bf_rqe) "3hhby-wmtmw-umt4t-7ieyg-bbiig-xiylg-sblrt-voxgt-bqckd-a75bf-rqe";
    case (#subnetId__csyj4_zmann_ys6ge_3kzi6_onexi_obayx_2fvak_zersm_euci4_6pslt_lae) "csyj4-zmann-ys6ge-3kzi6-onexi-obayx-2fvak-zersm-euci4-6pslt-lae";
    case (#subnetId__4zbus_z2bmt_ilreg_xakz4_6tyre_hsqj4_slb4g_zjwqo_snjcc_iqphi_3qe) "4zbus-z2bmt-ilreg-xakz4-6tyre-hsqj4-slb4g-zjwqo-snjcc-iqphi-3qe";
    }
  };
  type PostRequest = {
    apptype: AppType;
    canisterid: Text;
    subnetid: SubnetId;
    // type_,
    datalength: Nat;
    // lastseen: 
    title: Text;
    subtitle: Text;
    content: Text;
    note: Text;
    // status,
    // notnull
  };

  func lastseenNow(): Text {
     // generate YYYY-MM-DD format from unix time
    let date = DateTime.now(). getDateTimeObject();
    Nat.toText(date.year) #"-"# Nat.toText(date.month) #"-"# Nat.toText(date.day);
  };

  public  shared({caller = caller}) func userNewPost(request: PostRequest): async () {
    
    // generate YYYY-MM-DD format from unix time
    let lastseen = lastseenNow();

    // type_ is fixed
    let type_ = "app";

    // reject
    if (request.title.size() > 200) Debug.trap "title must under 200 charactors";
    if (request.subtitle.size() > 200) Debug.trap "subtitle must under 200 charactors";
    if (request.content.size() > 500) Debug.trap "content must under 500 charactors";
    if (request.note.size() > 200) Debug.trap "note must under 200 charactors";
    if (request.datalength > NAT32_MAX) Debug.trap "datalength is too large";
    if (request.canisterid == "") Debug.trap "canisterid is empty";

    /* 
    
    WIP: check caniter id duplications here
    
    */

    // use for SK, need to be encoded text
    let apptype = getApptype(request.apptype);
    let titlehash = if (request.title == "") ENCODED_HASH_MIN else LexEncode.encodeInt(Nat32.toNat(Text.hash(Text.map(request.title , Prim.charToLower))));
    let canisterid = Text.map(request.canisterid , Prim.charToLower);
    let datalength_encoded: Text = LexEncode.encodeInt(request.datalength); // for sk
    let subnetid = getSubnetId(request.subnetid);

    
    let titleSk       = jointText(["type", "app", "apptype" , apptype, "titlehash", titlehash, "score", ENCODED_SCORE_MIN, "canisterid", canisterid]);
    let lastseenSk    = jointText(["type", "app", "apptype" , apptype, "lastseen", lastseen, "canisterid", canisterid]);
    let termSk        = jointText(["type", "app", "score", ENCODED_SCORE_MIN, "datalength", datalength_encoded, "canisterid", canisterid]);
    let canisteridSk  = jointText(["canisterid", canisterid]);

    let metadataSk = termSk;

    let metadataAttributes = [
      ("canisterid", #text canisterid),
      ("subnetid", #text subnetid),
      ("type", #text "app"),
      ("datalength", #int (request.datalength)),
      ("lastseen", #text lastseen),
      ("title", #text (request.title)),
      ("subtitle", #text (request.subtitle)),
      ("content", #text (request.content)),
      ("apptype", #text apptype),
      ("note", #text (request.note))
      // ("status"), // status and notnull must be null here
      // ("notnull")
    ];


    // If the canister does not exist or is rip or broken.
    switch (CanDB.get(db, {sk = canisteridSk})) {
      case (?entity) {
        switch (Entity.getAttributeMapValueForKey(entity.attributes, "type")) {
          case (?(#text "app")) Debug.trap "already extists";
          case (?(#text "rip")) {};
          case (?(#text "broken")) {};
          case _ Debug.trap "cannot add it"; // cannot re-add scam
        };

        // subsituate keys
        switch (Entity.getAttributeMapValueForKey(entity.attributes, "titleSk")) {
          case (?(#text(oldTitleSk))) ignore CanDB.substituteKey(db, {oldSK = oldTitleSk; newSK = titleSk}); // replace old title key
          case _ {};
        };
        switch (Entity.getAttributeMapValueForKey(entity.attributes, "lastseenSk"),) {
          case (?(#text(oldLastseenSk))) ignore CanDB.substituteKey(db, {oldSK = oldLastseenSk; newSK = lastseenSk}); // replace old lastseen key
          case _ {};
        };
        switch (Entity.getAttributeMapValueForKey(entity.attributes, "termSk")) {
          case (?(#text(oldTermSk)))  ignore CanDB.substituteKey(db, {oldSK = oldTermSk; newSK = termSk}); // replace old term key
          case _ {};
        };

      };
      case _ {};
    };

    await* CanDB.batchPut(db, [
      { sk = titleSk;      attributes = [("metadataSk", #text metadataSk)] },
      { sk = lastseenSk;   attributes = [("metadataSk", #text metadataSk)] },
      { sk = termSk;       attributes = metadataAttributes }, // metadata is under termSk
      { sk = canisteridSk; attributes = [("metadataSk", #text metadataSk), ("titleSk", #text titleSk), ("lastseenSk", #text lastseenSk), ("termSk", #text termSk), ("type", #text "app")] }
    ]);

  };

  public shared({caller = caller}) func reportBroken(_canisterid: Text): async () {

    if (Principal.isAnonymous(caller)) Debug.trap "Anonymous user is not authenticated";

    let canisterid = Text.map(_canisterid , Prim.charToLower); // canisterid needs to be lowercase
    let canisteridSk  = jointText(["canisterid", canisterid]);
    let canisteridEntity = switch (CanDB.get(db, {sk = canisteridSk})) {
      case (?entity) entity;
      case _ Debug.trap "The canisterid dosen't exsit";
    };
    let metadataSk = switch (
      Entity.getAttributeMapValueForKey(canisteridEntity.attributes, "metadataSk"),
      Entity.getAttributeMapValueForKey(canisteridEntity.attributes, "type")
    ) {
      case (?#text sk, ?#text "app") sk; // if the type is not "app", recect report
      case _ Debug.trap "It's not app type"
    };
    let brokenCount = switch (Entity.getAttributeMapValueForKey(canisteridEntity.attributes, "brokencount")) {
      case (?#int c) c + 1;
      case _ 1;
    };

    func generateUpdateAttributeMapFunction(attribute: [(Entity.AttributeKey, Entity.AttributeValue)]): (?Entity.AttributeMap) -> Entity.AttributeMap {

      func updateAttributeMapWithKVPairs(attributeMap: Entity.AttributeMap, attributePairs: [(Entity.AttributeKey, Entity.AttributeValue)]): Entity.AttributeMap {
        var updatedMap = attributeMap;
        for ((k, v) in attributePairs.vals()) {
          updatedMap := RBT.put<Entity.AttributeKey, Entity.AttributeValue>(updatedMap, Text.compare, k, v);
        };

        updatedMap; 
      };
      return func(map: ?Entity.AttributeMap): Entity.AttributeMap {
        switch (map) {
          case (?map) updateAttributeMapWithKVPairs(map, attribute);
          case _ Debug.trap "The sk dosen't exsit";
        }
      };
    };

    let isStatusOfficial = switch (CanDB.get(db, {sk=metadataSk})) {
      case (?e) switch (Entity.getAttributeMapValueForKey(e.attributes, "status")) {
        case (?#text "official") true;
        case _ false;
      };
      case _ false;
    };

    if (brokenCount > 25 and (not isStatusOfficial)) { // OFFICIAL are not skipped here.

      let lastseen = lastseenNow();

      let newTitleSk       = jointText(["type", "broken", "titlehash", ENCODED_HASH_MIN, "canisterid", canisterid]);
      let newLastseenSk    = jointText(["type", "broken", "lastseen", lastseen, "canisterid", canisterid]);
      let newTermSk        = jointText(["type", "broken", "score", ENCODED_SCORE_MIN, "datalength", ENCODED_DATALENGTH_MIN, "canisterid", canisterid]);

      // subsituate keys
      switch (Entity.getAttributeMapValueForKey(canisteridEntity.attributes, "titleSk")) {
        case (?(#text(oldTitleSk))) ignore CanDB.substituteKey(db, {oldSK = oldTitleSk; newSK = newTitleSk}); // replace old title key
        case _ {};
      };
      switch (Entity.getAttributeMapValueForKey(canisteridEntity.attributes, "lastseenSk"),) {
        case (?(#text(oldLastseenSk))) ignore CanDB.substituteKey(db, {oldSK = oldLastseenSk; newSK = newLastseenSk}); // replace old lastseen key
        case _ {};
      };
      switch (Entity.getAttributeMapValueForKey(canisteridEntity.attributes, "termSk")) {
        case (?(#text(oldTermSk))) ignore CanDB.substituteKey(db, {oldSK = oldTermSk; newSK = newTermSk}); // replace old term key
        case _ {};
      };
      // update attributes
      let newMetadataSk = newTermSk;
      let updateCanisteridSkAttributes = generateUpdateAttributeMapFunction([
        ("metadataSk", #text newMetadataSk),
        ("titleSk", #text newTitleSk),
        ("lastseenSk", #text newLastseenSk),
        ("termSk", #text newTermSk),
        ("type", #text "broken")
      ]);
      let updateMetadataSkAttributes = generateUpdateAttributeMapFunction([
        ("type", #text "broken"),
        ("lastseen", #text lastseen)
      ]);
      let updateTitleSkAttributes = generateUpdateAttributeMapFunction([
        ("metadataSk", #text newMetadataSk)
      ]);
      let updateLastseenSkAttributes = generateUpdateAttributeMapFunction([
        ("metadataSk", #text newMetadataSk)
      ]);
      ignore CanDB.update(db, {sk=canisteridSk; updateAttributeMapFunction=updateCanisteridSkAttributes}); // canisterSk
      ignore CanDB.update(db, {sk=newMetadataSk; updateAttributeMapFunction=updateMetadataSkAttributes}); // metadataSk
      ignore CanDB.update(db, {sk=newTitleSk; updateAttributeMapFunction=updateTitleSkAttributes}); // titleSk
      ignore CanDB.update(db, {sk=newLastseenSk; updateAttributeMapFunction=updateLastseenSkAttributes}); // lastseenSk

      return // Attention, return is required here.
    };
    let updateAttributeMapFunction = generateUpdateAttributeMapFunction( [("brokencount", #int brokenCount)] );
    ignore CanDB.update(db, {sk=canisteridSk; updateAttributeMapFunction});
    ignore CanDB.update(db, {sk=metadataSk; updateAttributeMapFunction});
  };

  public shared query({caller=caller}) func debug_searchBySk(sk: Text): async ?Entity.Entity {
    if (not isOwner(caller)) throw Error.reject("not authorized");
    CanDB.get(db, {sk});
  };
  
  public shared query({caller=caller}) func debug_show_all(): async Text {
    if (not isOwner(caller)) throw Error.reject("not authorized");
    let rs = CanDB.scan(db, {
      skLowerBound = "#";
      skUpperBound = "#~";
      limit = 300;
      ascending = null;
    });

    var output = "\n";
    for (r in rs.entities.vals()) {
      output := output # r.sk # "\n";
    };
    output
  };
  public query func getOwners(): async ?[Text] {
    switch (owners) {
      case (?owners) {
        ?Array.map<Principal, Text>(owners, func(o) {
          Principal.toText(o)
        });
      };
      case null return null;
    }
  };

}
