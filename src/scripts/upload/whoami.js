// See https://forum.dfinity.org/t/using-dfinity-agent-in-node-js/6169/55

import { Actor, HttpAgent } from "@dfinity/agent";
import { importIdentity } from "./loadpem.js";
import { createActor as ServiceCreateActor } from "../../declarations/main/index.js"; // Need to commentout "export const main = createActor(canisterId);" in this file.
import fs from 'fs';

async function whoami(identityName) {

  // set service canister client
  let serviceCanisterId = JSON.parse(fs.readFileSync("../../../../.dfx/local/canister_ids.json", 'utf8')).main.local
  console.log("canisterId = " + serviceCanisterId)
  const identity = importIdentity(identityName);
  const agent = new HttpAgent({
    identity: identity,
    host: "http://127.0.0.1:8080",
    fetch,
  });
  const serviceActor = ServiceCreateActor(serviceCanisterId, {agent})

  await serviceActor.whoami()
  .then(r => {
    console.log("OK, :" + r)
  })
  .catch(e => {
    console.log("ERR :" + e)
    errList.push(arrayList[i])
  });
};


if (process.argv.length != 3) throw "whoami.js <service canisterid> <your dfx identity name>"
let identityName = process.argv[2]
console.log("identity ame = " + identityName)

whoami(identityName)