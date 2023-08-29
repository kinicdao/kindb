// See https://forum.dfinity.org/t/using-dfinity-agent-in-node-js/6169/55

import { Actor, HttpAgent } from "@dfinity/agent";
import { importIdentity } from "../upload/loadpem.js";
import { createActor as ServiceCreateActor } from "../../declarations/tf_storage_service/index.js"; // Need to commentout "export const main = createActor(canisterId);" in this file.
import { createActor as IndexCreateActor } from "../../declarations/candb_index/index.js";
import fs from 'fs';

import { caloc_tf } from "./caloc_tf.js";

// parse command line argumetns
import { Command } from 'commander';
const program = new Command();


async function upload(host, serviceCanisterId, identity, sites, page_count_include_the_word) {
  // set service canister client
  const agent = new HttpAgent({
    identity: identity,
    host: host,
    fetch,
  });
  const serviceActor = ServiceCreateActor(serviceCanisterId, {agent});

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




// Entry
program
  // .option('-d, --debug', 'output extra debugging')
  .option('--public', 'use public network')
  .option('--indexId <id>', 'candb index canister id')
  .option('--name <name>', 'identity name')
  .option('--official', 'official or non_official')
  .option('--chunk <num>', 'start chunk index');

program.parse(process.argv);
const options = program.opts();
// console.log(options)

// set host
let host = "http://127.0.0.1:8080";
if (options.public == true) {
  host = "https://ic0.app";
  console.log("uploading data to public canister");
}

// set index canister id
let indexCanisterId = "bkyz2-fmaaa-aaaaa-qaaaq-cai";
if (options.indexId) {
  indexCanisterId = options.indexId;
}

// set identity name
let identityName = "default";
if (options.name) {
  identityName = options.name;
}

// set official or non_official
let status = "non_official";
if (options.official) {
  status = "official";
}

// set start chunk index
let start_chunk_idx = 0;
if (options.chunk) {
  start_chunk_idx = options.chunk
}


console.log("host = " + host);
console.log("index canisterid = " + indexCanisterId);
console.log("identity name = " + identityName);
console.log("status = " + status)
console.log("\n\n")

// throw Error("")

const identity = importIdentity(identityName);
let agent = new HttpAgent({
  identity: identity,
  host: host,
  fetch,
});
let indexActor = IndexCreateActor(indexCanisterId, {agent});
let serviceCanisterId = (await indexActor.getCanistersByPK(status))[0];
if (!serviceCanisterId) throw Error(`cannot fetch the serveice canister of "${status}"`);
console.log("the serveice canister id is " + serviceCanisterId)

let ave_length = [0, 0, 0];

// Load word data files
let chunks = fs.readdirSync(`src/scripts/crawler/regulared_words_chunks/${status}`);
chunks = chunks.sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));
console.log(chunks)

let l = 0;
for (let chunk_idx = start_chunk_idx; chunk_idx < chunks.length; chunk_idx++) {
  const chunk = chunks[chunk_idx];
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

  let page_count_include_the_word = {};

  const SIZE = 500;

  console.log("sites length = " + sites.length)

  for (let i = 0; ; i++) {
    const STR = i*SIZE;
    const END = i*SIZE+SIZE;

    try {
      const sub = sites.slice(STR, END);
      console.log(STR + " - " +  END);
      let res = await upload(host, serviceCanisterId, identity, sub, page_count_include_the_word);
      console.log(res)

      ave_length[0] += res[0];
      ave_length[1] += res[1];
      ave_length[2] += res[2];

    }
    catch(e) {
      break
    };

    if (END > sites.length) break; // !! Note, Must be included
  };
  
  console.log("\n")
}



console.log("Finish Upload")
console.log(ave_length)

// node src/scripts/crawler/uploader.js be2us-64aaa-aaaaa-qaabq-cai default