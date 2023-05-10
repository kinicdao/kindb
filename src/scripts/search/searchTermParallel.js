// See https://forum.dfinity.org/t/using-dfinity-agent-in-node-js/6169/55

import { Actor, HttpAgent } from "@dfinity/agent";
// import { importIdentity } from "./loadpem.js";
import { createActor as ServiceCreateActor } from "../src/declarations/candb_service/index.js"; // Need to commentout "export const main = createActor(canisterId);" in this file.
import fs from 'fs';

async function searchTermLoop_(term) {
  let res = JSON.parse(fs.readFileSync("./test/sks.json", 'utf8'))

  let got = false
  let data = []
  let query_data = async (term, sk) => {
    return new Promise(async (resolve) => {
      let res = await serviceActor.searchTerm(term, sk)
      if (res[0] != '[]') {
        // console.log("get")
        got = true
        data.push(res[0])
      }
      // else console.log("non")
      resolve(res)
    });
  }

  const MAX = res.length;
  const CONCURRENCY = 40;
  console.log("Max", MAX)
  let cnt = 0;
  let promises = [];

  for (let i = 0; i < CONCURRENCY; i++) {
    let p = new Promise((resolve) => {
      (async function loop(index) {
        if (index < MAX && !got) {
          await query_data(term, res[index]);
          // console.log(index)
          loop(cnt++);
          return;
        }
        resolve();
      })(cnt++);
    });
    promises.push(p);
  }
  await Promise.all(promises);

  let response = data.map(r => JSON.parse(r)).flat()
  console.log(response.length)

};

if (process.argv.length != 4) throw "uploader.js <service canisterid>"
let serviceCanisterId = process.argv[2]
let term = process.argv[3]
console.log("canisterid = " + serviceCanisterId)

const agent = new HttpAgent({
  host: "https://ic0.app",
  // host: "http://127.0.0.1:8080",
  fetch,
});
const serviceActor = ServiceCreateActor(serviceCanisterId, {agent})
var got = false
var result = []

searchTermLoop_(term)