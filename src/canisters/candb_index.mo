import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Buf "mo:base/Buffer";
import Array "mo:base/Array";
import Iter "mo:base/Iter";

import CA "mo:candb/CanisterActions";
import CanisterMap "mo:candb/CanisterMap";
import Utils "mo:candb/Utils";
import Buffer "mo:stable-buffer/StableBuffer";
// import Service "./candb_service";
import Service "./tf_storage_service";
import CanDbAdmin "mo:candb/CanDBAdmin";
import RBT "mo:stable-rbtree/StableRBTree";

shared ({ caller = initial_owner })  actor class IndexCanister() = this {
  /// @required stable variable (Do not delete or change)
  ///
  /// Holds the CanisterMap of PK -> CanisterIdList
  stable var pkToCanisterMap = CanisterMap.init();

  /// @required API (Do not delete or change)
  ///
  /// Get all canisters for an specific PK
  ///
  /// This method is called often by the candb-client query & update methods. 
  public shared query({caller = caller}) func getCanistersByPK(pk: Text): async [Text] {
    getCanisterIdsIfExists(pk);
  };

  /// @required function (Do not delete or change)
  ///
  /// Helper method acting as an interface for returning an empty array if no canisters
  /// exist for the given PK
  func getCanisterIdsIfExists(pk: Text): [Text] {
    switch(CanisterMap.get(pkToCanisterMap, pk)) {
      case null { [] };
      case (?canisterIdsBuffer) { Buffer.toArray(canisterIdsBuffer) } 
    }
  };

  stable var owner = initial_owner;

  public shared({caller = caller}) func changeOwner(newOnwer : Text): async () {
    if (Principal.isAnonymous(caller) or caller != owner) throw Error.reject("not authorized");
    owner := Principal.fromText(newOnwer);
  };

  public shared query func getOwner(): async Text {
    Principal.toText(owner)
  };

  public shared({caller = caller}) func autoScaleServiceCanister(pk: Text): async Text {
    // Auto-Scaling Authorization - if the request to auto-scale the partition does not coming from an existing canister in the partition, reject it.
    if (Utils.callingCanisterOwnsPK(caller, pkToCanisterMap, pk)) {
      Debug.print("creating an additional canister for pk=" # pk);
      await createServiceCanister(pk, ?[owner, Principal.fromActor(this)])
    } else {
      throw Error.reject("not authorized");
    };
  };
  
  // Owner only
  // Partition Service canisters by PK
  // Spins up a new Service canister with the provided pk and controllers
  public shared({caller = caller}) func createServiceCanisterByPk(pk: Text, extraOwners: [Principal]): async ?Text {
    if (Principal.isAnonymous(caller) or caller != owner) throw Error.reject("not authorized");
    if (extraOwners.size() > 8) throw Error.reject("Extra onwer must be under 8");
    let owners = Buf.Buffer<Principal>(10);  // let owners = Array.append<Principal>([owner, Principal.fromActor(this)], extraOwners);
    owners.add(owner);
    owners.add(Principal.fromActor(this));
    ignore Array.map<Principal, ()>(extraOwners, func(o) {owners.add(o)});
    let canisterIds = getCanisterIdsIfExists(pk);
    if (canisterIds == []) {
      ?(await createServiceCanister(pk, ?Buf.toArray(owners)));
    // The partition already exists. Don't create a new canister.
    } else {
      Debug.print(pk # " already exists");
      null 
    };

  };

  // Owner only
  public shared({caller = caller}) func upgradeServiceCanisterByPk(pk: Text, wasm: Blob, extraOwners: [Principal]): async [(Text, CanDbAdmin.InterCanisterActionResult)] {
    if (Principal.isAnonymous(caller) or caller != owner) throw Error.reject("not authorized");
    
    let scalingOptions = {
      autoScalingHook = autoScaleServiceCanister;
      sizeLimit = #heapSize(900_000_000); // Scale out at 900MB
      // for auto-scaling testing
      //sizeLimit = #count(3); // Scale out at 3 entities inserted
    };
    // await CanDbAdmin.upgradeCanistersByPK(
    //   pkToCanisterMap, // canistermap
    //   pk,
    //   wasm,
    //   scalingOptions
    // );

    if (extraOwners.size() > 8) throw Error.reject("Extra onwer must be under 8");
    let owners = Buf.Buffer<Principal>(10);  // let owners = Array.append<Principal>([owner, Principal.fromActor(this)], extraOwners);
    owners.add(owner);
    owners.add(Principal.fromActor(this));
    ignore Array.map<Principal, ()>(extraOwners, func(o) {owners.add(o)});

    // Copied from CanDBAdmin.mo and edit for patch
    let wasmModule = wasm;
    switch(CanisterMap.get(pkToCanisterMap, pk)) {
      case null [];
      case (?canisterIdsBuffer) {
        var canisterUpgradeStatusTracker = RBT.init<Text, CanDbAdmin.InterCanisterActionResult>();
        for (canisterId in canisterIdsBuffer.elems.vals()) {
          try {
            Debug.print("upgrading canister: " # canisterId);
            await CA.upgradeCanisterCode({
              canisterId = Principal.fromText(canisterId);
              wasmModule = wasmModule;
              args = to_candid({
                partitionKey = pk;
                scalingOptions = scalingOptions;
                owners = Buf.toArray(owners); // added
              });
            });
            Debug.print("finished upgrading canister: " # canisterId);
            canisterUpgradeStatusTracker := RBT.put<Text, CanDbAdmin.InterCanisterActionResult>(canisterUpgradeStatusTracker, Text.compare, canisterId, #ok);
          } catch(error) {
            Debug.print("upgrading canister:" # canisterId # " failed with error=" # Error.message(error));
            canisterUpgradeStatusTracker := RBT.put<Text, CanDbAdmin.InterCanisterActionResult>(canisterUpgradeStatusTracker, Text.compare, canisterId, #err(Error.message(error)) );
          };
        };
        Debug.print("pk=" # pk # ", upgrades for all canisters complete");
        return Iter.toArray(RBT.entries<Text, CanDbAdmin.InterCanisterActionResult>(canisterUpgradeStatusTracker));
      }
    };
  };

  func createServiceCanister(pk: Text, controllers: ?[Principal]): async Text {
    Debug.print("creating new service canister with pk=" # pk);
    // Pre-load 300 billion cycles for the creation of a new Service canister
    // Note that canister creation costs 100 billion cycles, meaning there are 200 billion
    // left over for the new canister when it is created
    Cycles.add(1_000_000_000_000); // Note, add 1T cycle
    let newServiceCanister = await Service.Service({
      partitionKey = pk;
      scalingOptions = {
        autoScalingHook = autoScaleServiceCanister;
        sizeLimit = #heapSize(900_000_000); // Scale out at 900MB
        // for auto-scaling testing
        //sizeLimit = #count(3); // Scale out at 3 entities inserted
      };
      owners = controllers;
    });
    let newServiceCanisterPrincipal = Principal.fromActor(newServiceCanister);
    await CA.updateCanisterSettings({
      canisterId = newServiceCanisterPrincipal;
      settings = {
        controllers = controllers;
        compute_allocation = ?0;
        memory_allocation = ?0;
        freezing_threshold = ?2592000;
      }
    });

    let newServiceCanisterId = Principal.toText(newServiceCanisterPrincipal);
    // After creating the new Service canister, add it to the pkToCanisterMap
    pkToCanisterMap := CanisterMap.add(pkToCanisterMap, pk, newServiceCanisterId);

    Debug.print("new service canisterId=" # newServiceCanisterId);
    newServiceCanisterId;
  };
}