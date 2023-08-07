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
  // console.log(arg[0])

  // arg[0].forEach((e) => console.log(e))
  // console.log(arg[2]/arg[1], arg[3]/arg[1])

  // arg = [
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

  // Debug
  // arg[0].forEach(([host, _]) => {
  //   if (host == "dsmzx-jaaaa-aaaak-qagra-cai") console.log("In uploading db, include dsmzx-jaaaa-aaaak-qagra-cai");
  // });

  
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
let serviceCanisterId = process.argv[2];
let identityName = process.argv[3];
// let jsonPath = process.argv[4]

console.log("canisterid = " + serviceCanisterId);
console.log("identity name = " + identityName);
// console.log("json path = " + jsonPath)

// Load word data
console.log("loading words");



// Load word data files
const chunks = fs.readdirSync('src/scripts/crawler/word_chunks');
let l = 0;
for (const chunk of chunks) {
  if (chunk == ".gitkeep" || chunk == ".DS_Store") continue
  console.log("chunk: " + chunk)
  const filenames = fs.readdirSync('src/scripts/crawler/word_chunks/' + chunk);

  let sites = [];

  console.log("filenames length " + filenames.length);
  for (const filename of filenames) {
    // console.log(filename)
    if (filename == '.gitkeep' || filename == '.DS_Store') continue;
    sites.push(JSON.parse(fs.readFileSync(`src/scripts/crawler/word_chunks/${chunk}/${filename}`, 'utf8')));
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
}



console.log("Finish Upload")

// console.log( Object.entries(page_count_include_the_word))
// fs.writeFile(`src/scripts/crawler/page_count_include_the_word.json`, JSON.stringify(page_count_include_the_word, null, '    '), err => {
//   if (err) console.log(err.message);
// });


// node src/scripts/crawler/uploader.js be2us-64aaa-aaaaa-qaabq-cai default