// See https://forum.dfinity.org/t/using-dfinity-agent-in-node-js/6169/55

import { Actor, HttpAgent } from "@dfinity/agent";
import { importIdentity } from "../upload/loadpem.js";
import { createActor as ServiceCreateActor } from "../../declarations/tf_storage_service/index.js"; // Need to commentout "export const main = createActor(canisterId);" in this file.
import { createActor as OldServiceCreateActor } from "../../declarations/candb_service/index.js";
import fs from 'fs';

import {searchTotal} from "./searchTotal.js";

const N_COUNT_DOCUMENTS = 724+853+333; // document count
const N_AVERAGE_COUNT_WORDS = (40674+191220+28772)/N_COUNT_DOCUMENTS; // document length
const N_AVERAGE_KIND_WORDS = (24261+90241+18266)/N_COUNT_DOCUMENTS// kinds of word in the document

async function search(serviceCanisterId, identityName) {

  /* get canister ids from new db */
  // const identity = importIdentity(identityName);
  let agent = new HttpAgent({
    // identity: identity,
    // host: "https://ic0.app",
    host: "http://127.0.0.1:8080",
    fetch,
  });
  let serviceActor = ServiceCreateActor(serviceCanisterId, {agent});
  let query = ["account"];
  let hosts = await searchTotal(serviceActor, query);
  // console.log(hosts);


  /* get metadata from old db */

  agent = new HttpAgent({
    // identity: identity,
    host: "https://ic0.app",
    // host: "http://127.0.0.1:8080",
    fetch,
  });
  serviceActor = OldServiceCreateActor("nw5jb-vqaaa-aaaaf-qaj4a-cai", {agent}); // get it from public

  let get_metadata = async (canisterid) => {
    return new Promise(async (resolve) => {
      let res = await serviceActor.searchCanisterId(canisterid);
      resolve(res)
    });
  };
  // limit 30
  if (30 < hosts.length) {
    hosts = hosts.slice(0, 30)
  };
  let promises = [];
  hosts.map((host) => {
    promises.push(get_metadata(host.canisterid))
  });
  
  let res = await Promise.all(promises);
  console.log(res)




};


// if (process.argv.length != 4) throw "uploader.js <service canisterid> <your dfx identity name>"
let serviceCanisterId = process.argv[2]
let identityName = process.argv[3]
// let jsonPath = process.argv[4]

console.log("canisterid = " + serviceCanisterId)
console.log("identity name = " + identityName)
// console.log("json path = " + jsonPath)

search(serviceCanisterId, identityName)
