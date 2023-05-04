// See https://forum.dfinity.org/t/using-dfinity-agent-in-node-js/6169/55

import { Actor, HttpAgent } from "@dfinity/agent";
import { importIdentity } from "./loadpem.js";
import { createActor as ServiceCreateActor } from "../../declarations/candb_service/index.js"; // Need to commentout "export const main = createActor(canisterId);" in this file.
import fs from 'fs';

async function test_upload(serviceCanisterId, identityName, dataPath) {
  // set service canister client
  const identity = importIdentity(identityName);
  const agent = new HttpAgent({
    identity: identity,
    host: "https://ic0.app",
    fetch,
  });
  const serviceActor = ServiceCreateActor(serviceCanisterId, {agent})

  // split large json file
  let data = JSON.parse(fs.readFileSync(dataPath, 'utf8'));
  let size = fs.statSync(dataPath).size
  let splitCount = Math.ceil(size/(50*1024))
  let onePortionSize = Math.ceil(data.length/splitCount)

  console.log("chank num: " + splitCount)

  var arrayList = []
  var idx = 0
  while (idx < data.length) {
    let a = data.slice(idx, idx + onePortionSize)
    //remove special characters
    a.forEach((entry) => {

        if (entry && entry.title && typeof entry.title === 'string') {
          entry.title = entry.title.replace(/\"/g, '').replace(/\'/g, '').replace(/\`/g, '').replace(/\\/g, '');
        } else {
          entry.title = '';
        }
        if (entry && entry.subtitle && typeof entry.subtitle === 'string') {
          entry.subtitle = entry.subtitle.replace(/\"/g, '').replace(/\'/g, '').replace(/\`/g, '').replace(/\\/g, '');
        } else {
          entry.subtitle = '';
        }

        if (entry && entry.content && typeof entry.content === 'string') {
          entry.content = entry.content.replace(/\"/g, '').replace(/\'/g, '').replace(/\`/g, '').replace(/\\/g, '');
        } else {
          entry.content = '';
        }
    });
    a = JSON.stringify(a)
    arrayList.push(a)
    idx += onePortionSize
  }
  // upload to canister
  let errList = []
  var i = 0
  while (i < arrayList.length) {
    await serviceActor.upload(arrayList[i])
    .then(_ => {
      console.log("OK, Num:" + i + " length: " + arrayList[i].length)
    })
    .catch(e => {
      console.log("ERR, Num:" + i + " length: " + arrayList[i].length + e)
      errList.push(arrayList[i])
    });
    i += 1
  }

  console.log(errList.length)
};


if (process.argv.length != 5) throw "uploader.js <service canisterid> <your dfx identity name> <json(text) path>"
let serviceCanisterId = process.argv[2]
let identityName = process.argv[3]
let jsonPath = process.argv[4]

console.log("canisterid = " + serviceCanisterId)
console.log("identity ame = " + identityName)
console.log("json path = " + jsonPath)

test_upload(serviceCanisterId, identityName, jsonPath)
