// See https://forum.dfinity.org/t/using-dfinity-agent-in-node-js/6169/55

import { Actor, HttpAgent } from "@dfinity/agent";
import { importIdentity } from "../upload/loadpem.js";
import { createActor as ServiceCreateActor } from "../../declarations/tf_storage_service/index.js"; // Need to commentout "export const main = createActor(canisterId);" in this file.
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

  // arg[0].forEach((e) => console.log(e))
  // console.log(arg[2]/arg[1], arg[3]/arg[1])

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


if (process.argv.length != 4) throw "uploader.js <service canisterid> <your dfx identity name>"
let serviceCanisterId = process.argv[2]
let identityName = process.argv[3]
// let jsonPath = process.argv[4]

console.log("canisterid = " + serviceCanisterId)
console.log("identity name = " + identityName)
// console.log("json path = " + jsonPath)

let page_count_include_the_word = {};

const SIZE = 500;

for (let i = 0; ; i++) {
  const STR = i*SIZE;
  const END = i*SIZE+SIZE;
  const data_path = `src/scripts/crawler/words_${STR}_${END}.json`;

  try {
    const sites = JSON.parse(fs.readFileSync(data_path, 'utf8'));
    console.log("ok: " + data_path)
    let res = await upload(serviceCanisterId, identityName, sites, page_count_include_the_word);
    console.log(res)
  }
  catch(e) {
    break
  };
};

// console.log( Object.entries(page_count_include_the_word))
// fs.writeFile(`src/scripts/crawler/page_count_include_the_word.json`, JSON.stringify(page_count_include_the_word, null, '    '), err => {
//   if (err) console.log(err.message);
// });


// node src/scripts/crawler/uploader.js be2us-64aaa-aaaaa-qaabq-cai default