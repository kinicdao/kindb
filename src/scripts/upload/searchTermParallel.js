// See https://forum.dfinity.org/t/using-dfinity-agent-in-node-js/6169/55

import { Actor, HttpAgent } from "@dfinity/agent";
import { importIdentity } from "./loadpem.js";
import { createActor as ServiceCreateActor } from "../../declarations/candb_service/index.js"; // Need to commentout "export const main = createActor(canisterId);" in this file.
import fs from 'fs';

async function searchTermLoop_(term) {
  let res = await serviceActor.searchTermWithNextKeysForParallelSearch(term)

  let promises = []

  for (let sk of res[1]) {
    promises.push(query_data(term, sk))
  }

  await Promise.all(promises).then((values) => {
    // console.log(values)
  });

};

async function query_data(term, sk) {
  return new Promise(async (resolve) => {
    let begin = new Date()
    // console.log("begin: ",sk, begin)
    let res = await serviceActor.searchTerm(term, [sk])
    // console.log(res[1][0], new Date() - begin)
    // console.log("time: ",sk, new Date() - begin)
    resolve(res)
  });
}


// if (res[0] == "[]") {
//   let promises = [];

//   res[1].forEach((sk) => {
//     promises.push(serviceActor.searchTerm(term, [sk]))
//     // console.log(sk)
//   })

//   await Promise.all(promises).then((values) => {
//     // console.log(values)
//   });

//   console.log("finish")
// }
// else {
//   console.log(res[0])
// }

if (process.argv.length != 4) throw "uploader.js <service canisterid>"
let serviceCanisterId = process.argv[2]
let term = process.argv[3]
console.log("canisterid = " + serviceCanisterId)

const agent = new HttpAgent({
  // host: "https://ic0.app",
  host: "http://127.0.0.1:8080",
  fetch,
});
const serviceActor = ServiceCreateActor(serviceCanisterId, {agent})

searchTermLoop_(term)
