// See https://forum.dfinity.org/t/using-dfinity-agent-in-node-js/6169/55

import { Actor, HttpAgent } from "@dfinity/agent";
import { importIdentity } from "./loadpem.js";
import { createActor as ServiceCreateActor } from "../../declarations/candb_service/index.js"; // Need to commentout "export const main = createActor(canisterId);" in this file.
import fs from 'fs';

async function searchTermLoop_(term1, term2) {
  let res = await serviceActor.searchTermWithNextKeysForParallelSearch(term1)
  let res2 = await serviceActor.searchTermWithTarget(true, true, true, [term2], [])

  const INIT = 0;
  const MAX = res[1].length;
  const CONCURRENCY = 10; // 同時実行できる数を定義
  console.log("Max", MAX)
  let cnt1 = INIT;
  let cnt2 = INIT;
  let promises = [];

  for (let i = 0; i < CONCURRENCY; i++) {
    let p = new Promise((resolve) => {
      (async function loop(index1, index2) {
        console.log(index1, index2)
        if (index1 < MAX) {
          await query_data(true, true, false, term1, [res[1][index1]]);
          loop(cnt1++, cnt2);
          return;
        }
        else if (index2 < MAX) {
          await query_data(true, true, true, term2, [res[1][index2]]);
          loop(cnt1, cnt2++);
          return;
        }
        resolve();
      })(cnt1++, cnt2);
    });
    promises.push(p);
  }

  await Promise.all(promises);

};

async function query_data(title, subtitle, content, term, sk) {
  return new Promise(async (resolve) => {
    let res = await serviceActor.searchTermWithTarget(title, subtitle, content, [term], sk)
    if (res[0] != '[]') console.log("get")
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

if (process.argv.length != 5) throw "uploader.js <service canisterid>"
let serviceCanisterId = process.argv[2]
let term1 = process.argv[3]
let term2 = process.argv[4]
console.log("canisterid = " + serviceCanisterId)
console.log(term1, term2)

const agent = new HttpAgent({
  // host: "https://ic0.app",
  host: "http://127.0.0.1:8080",
  fetch,
});
const serviceActor = ServiceCreateActor(serviceCanisterId, {agent})

searchTermLoop_(term1, term2)
