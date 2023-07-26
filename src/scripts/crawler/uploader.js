// See https://forum.dfinity.org/t/using-dfinity-agent-in-node-js/6169/55

import { Actor, HttpAgent } from "@dfinity/agent";
import { importIdentity } from "../upload/loadpem.js";
import { createActor as ServiceCreateActor } from "../../declarations/tf_storage_service/index.js"; // Need to commentout "export const main = createActor(canisterId);" in this file.
import fs from 'fs';

import { caloc_tf } from "./caloc_tf.js";


async function upload(serviceCanisterId, identityName, dataPath) {
  // set service canister client
  const identity = importIdentity(identityName);
  const agent = new HttpAgent({
    identity: identity,
    // host: "https://ic0.app",
    host: "http://127.0.0.1:8080",
    fetch,
  });
  const serviceActor = ServiceCreateActor(serviceCanisterId, {agent});

  const sites = JSON.parse(fs.readFileSync("src/scripts/crawler/words_0_500.json", 'utf8'));

  let arg = caloc_tf(sites);

  // let arg = [
  //   [
  //     "Host", 
  //     ["Path"],
  //     ["Title"], 
  //     [
  //       ["Word", [[0.2], [0]]],
  //       ["Word1", [[0.07894736842105263], [0]]],
  //     ]
  //   ]
  // ];
  
  await serviceActor.batchPut(arg)
    .then(_ => {
      console.log("OK");
    })
    .catch(e => {
      console.log(e);
    });
};


if (process.argv.length != 4) throw "uploader.js <service canisterid> <your dfx identity name>"
let serviceCanisterId = process.argv[2]
let identityName = process.argv[3]
// let jsonPath = process.argv[4]

console.log("canisterid = " + serviceCanisterId)
console.log("identity name = " + identityName)
// console.log("json path = " + jsonPath)

upload(serviceCanisterId, identityName)
