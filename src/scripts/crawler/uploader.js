// See https://forum.dfinity.org/t/using-dfinity-agent-in-node-js/6169/55

import { Actor, HttpAgent } from "@dfinity/agent";
import { importIdentity } from "../upload/loadpem.js";
import { createActor as ServiceCreateActor } from "../../declarations/tf_storage_service/index.js"; // Need to commentout "export const main = createActor(canisterId);" in this file.
import { createActor as IndexCreateActor } from "../../declarations/candb_index/index.js";
import fs from 'fs';

import { caloc_tf } from "./caloc_tf.js";


async function upload(serviceCanisterId, identityName, sites, page_count_include_the_word) {
  // set service canister client
  const identity = importIdentity(identityName);
  const agent = new HttpAgent({
    identity: identity,
    // host: "https://ic0.app",
    host: "http://127.0.0.1:8080",
    fetch,
  });
  const serviceActor = ServiceCreateActor(serviceCanisterId, {agent});

  // const sites = JSON.parse(fs.readFileSync("src/scripts/crawler/words_0_500.json", 'utf8'));
  // const sites = JSON.parse(fs.readFileSync("src/scripts/crawler/words_500_1000.json", 'utf8'));

  let arg = caloc_tf(sites, page_count_include_the_word);
  console.log("arg length "+ arg.length)
  
  
  await serviceActor.batchPut(arg[0])
    .then(_ => {
      console.log("OK: Data is uploaded");
    })
    .catch(e => {
      console.log(e);
      throw Error(e)
    });

  return [arg[1], arg[2], arg[3]]
};


if (process.argv.length != 5) throw "uploader.js <index canisterid> <your dfx identity name> <canister status/ offcial or non_offical>"
let indexCanisterId = process.argv[2];
let identityName = process.argv[3];
let status = process.argv[4]

console.log("canisterid = " + indexCanisterId);
console.log("identity name = " + identityName);
console.log("\n\n")
// console.log("json path = " + jsonPath)

let agent = new HttpAgent({
  // identity: identity,
  // host: "https://ic0.app",
  host: "http://127.0.0.1:8080",
  fetch,
});
let indexActor = IndexCreateActor(indexCanisterId, {agent});
let serviceCanisterId = (await indexActor.getCanistersByPK(status))[0];
if (!serviceCanisterId) throw Error(`cannot fetch the serveice canister of "${status}"`);
console.log("the serveice canister id is " + serviceCanisterId)

// Load word data files
const chunks = fs.readdirSync(`src/scripts/crawler/regulared_words_chunks/${status}`);
let l = 0;
for (const chunk of chunks) {
  if (chunk == ".gitkeep" || chunk == ".DS_Store" || chunk == "page_count_include_the_word.json") continue
  console.log("chunk: " + chunk)
  const filenames = fs.readdirSync(`src/scripts/crawler/regulared_words_chunks/${status}/` + chunk);

  let sites = [];

  // console.log("filenames length " + filenames.length);
  for (const filename of filenames) {
    // console.log(filename)
    if (filename == '.gitkeep' || filename == '.DS_Store') continue;
    sites.push(JSON.parse(fs.readFileSync(`src/scripts/crawler/regulared_words_chunks/${status}/${chunk}/${filename}`, 'utf8')));
  };

  // Debug
  // sites.forEach((site) => {
  //   if (site.serviceCanisterId == "dsmzx-jaaaa-aaaak-qagra-cai") console.log("In file fetch, include dsmzx-jaaaa-aaaak-qagra-cai");
  // });

  let page_count_include_the_word = {};

  const SIZE = 500;

  console.log("sites length = " + sites.length)

  for (let i = 0; ; i++) {
    const STR = i*SIZE;
    const END = i*SIZE+SIZE;

    try {
      const sub = sites.slice(STR, END);
      console.log(STR + " - " +  END);
      let res = await upload(serviceCanisterId, identityName, sub, page_count_include_the_word);
      console.log(res)
    }
    catch(e) {
      break
    };

    if (END > sites.length) break; // !! Note, Must be included
  };
  
  console.log("\n")
}



console.log("Finish Upload")

// node src/scripts/crawler/uploader.js be2us-64aaa-aaaaa-qaabq-cai default