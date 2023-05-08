// See https://forum.dfinity.org/t/using-dfinity-agent-in-node-js/6169/55

import { Actor, HttpAgent } from "@dfinity/agent";
import { importIdentity } from "./loadpem.js";
import { createActor as ServiceCreateActor } from "../../declarations/candb_service/index.js"; // Need to commentout "export const main = createActor(canisterId);" in this file.
import fs from 'fs';

async function searchTermLoop_(serviceCanisterId, term) {
  // set service canister client
  const agent = new HttpAgent({
    // host: "https://ic0.app",
    host: "http://127.0.0.1:8080",
    fetch,
  });
  // let words = term.split(" ")
  const serviceActor = ServiceCreateActor(serviceCanisterId, {agent})
  let res = await searchUntilGet(serviceActor.searchTerm, term)
  console.log(res)
};

async function searchUntilGet(searchFunc, arg) {
  var nextSK = []
  var hits = []
  while (true) {
    await searchFunc(arg, nextSK)
    .then(res => {
      console.log("Search, " + res[0] + "next sk: " + res[1])
      if (res[0] != "[]") hits.push(res[0])
      nextSK = res[1]
    })
    .catch(e => {
      console.log(e)
    });
    // if (hit != "[]") return hit
    if (nextSK.length == 0) break
  };
  console.log("end")
  return JSON.stringify(hits)
};


if (process.argv.length != 4) throw "uploader.js <service canisterid>"
let serviceCanisterId = process.argv[2]
let term = process.argv[3]

console.log("canisterid = " + serviceCanisterId)

searchTermLoop_(serviceCanisterId, term)
