import { IndexClient } from "candb-client-typescript/dist/IndexClient";
import { ActorClient } from "candb-client-typescript/dist/ActorClient";

import { idlFactory as IndexCanisterIDL } from "../../declarations/candb_index/index";
import { idlFactory as ServiceCanisterIDL } from "../../declarations/candb_service/index";
import { IndexCanister } from "../../declarations/candb_index/candb_index.did";
import { Service } from "../../declarations/candb_service/candb_service.did";

import fs from 'fs';
import path from 'path';


const localCanisterIds = JSON.parse(fs.readFileSync('./.dfx/local/canister_ids.json', 'utf8'));

export function intializeIndexClient(isLocal: boolean): IndexClient<IndexCanister> {
  const host = isLocal ? "http://127.0.0.1:8080" : "https://ic0.app";
  // canisterId of your index canister
  const canisterId = isLocal ? process.env.INDEX_CANISTER_ID : localCanisterIds.candb_index.local;;
  return new IndexClient<IndexCanister>({
    IDL: IndexCanisterIDL,
    canisterId, 
    agentOptions: {
      host,
    },
  })
};

export function initializeServiceClient(isLocal: boolean, indexClient: IndexClient<IndexCanister>): ActorClient<IndexCanister, Service> {
  const host = isLocal ? "http://127.0.0.1:8080" : "https://ic0.app";
  return new ActorClient<IndexCanister, Service>({
    actorOptions: {
      IDL: ServiceCanisterIDL,
      agentOptions: {
        host,
      }
    },
    indexClient, 
  })
};