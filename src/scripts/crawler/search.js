// See https://forum.dfinity.org/t/using-dfinity-agent-in-node-js/6169/55

import { Actor, HttpAgent } from "@dfinity/agent";
import { importIdentity } from "../upload/loadpem.js";
import { createActor as ServiceCreateActor } from "../../declarations/tf_storage_service/index.js"; // Need to commentout "export const main = createActor(canisterId);" in this file.
import fs from 'fs';

import { caloc_tf } from "./caloc_tf.js";


const N = 1910;
// const N_

async function search(serviceCanisterId, identityName) {
  // set service canister client
  const identity = importIdentity(identityName);
  const agent = new HttpAgent({
    identity: identity,
    // host: "https://ic0.app",
    host: "http://127.0.0.1:8080",
    fetch,
  });
  const serviceActor = ServiceCreateActor(serviceCanisterId, {agent});

  const sites = JSON.parse(fs.readFileSync("src/scripts/crawler/words_0_500.json", 'utf8'));

  let query = ["canister"];
  
  let res = await serviceActor.search(query)
    .then(res => {
      console.log("OK");
      // console.log(res);
      return res
    })
    .catch(e => {
      console.log(e);
    });

  // [ '27kdi-daaaa-aaaak-qaena-cai', [ [ 'NFT Info', '', [Array] ] ] ]

  let DummyIDF = 1.0; // dummy : idf[word]
  const page_count_include_the_word = JSON.parse(fs.readFileSync("src/scripts/crawler/page_count_include_the_word.json", 'utf8'));

  // let res = [
  //   [ 'a', [ [ 'p1', '', [0.5,0.1]],  [ 'p2', '/p2', [0.5,0.5]], [ 'p3', '/p3', [0.5,0.3]]] ],
  //   [ 'b', [ [ 'p1', '', [0.5,0.1]],  [ 'p2', '/p2', [0.5,0.5]], [ 'p3', '/p3', [0.5,0.3]]] ],
  //   [ 'c', [ [ 'p1', '/p', [0.5,0.1]],  [ 'p2', '/p2', [0.5,0.5]], [ 'p3', '/p3', [0.5,0.6]]] ]
  // ]

  let hosts = res.map(([host, pages]) => {
    // console.log(host)
    let max_tf_idf_page = ['', '', 0.0];
    let total_it_idf_score = 0;
    pages.forEach(([title, path, tfs]) => {
      let sum_tf_idf = 0;
      tfs.forEach((tf, i) => {
        let word = query[i];
        let idf = Math.log2(N/page_count_include_the_word[word]) //  IDF[word]
        sum_tf_idf += tf*idf;
      });
      if (sum_tf_idf > max_tf_idf_page[2]) max_tf_idf_page = [title, path, sum_tf_idf];
      total_it_idf_score += sum_tf_idf;
    });

    let show_page = [];
    if (pages[0][1] == "") {
      show_page = pages[0];
    }
    else {
      show_page = max_tf_idf_page;
    };
    
    // console.log(host, show_page[0], show_page[1], total_it_idf_score);
    return [host, show_page[0], show_page[1], total_it_idf_score]
  });
  
  // let multipiled_idf = [ [ 'page1', '', 1.0 ],  [ 'page2', '/page2', 1.5 ], [ 'page3', '/page3', 0.7 ] ];
  let sorted_by_tf_idf = hosts.sort(function(a, b){
    // console.log(a[2], b[2])
    return b[3] -  a[3]
  });
  console.log(sorted_by_tf_idf)



  /*

  ToDo
  - Set idf constant variable
  - Multipile the idf to each page

  - root pageがある場合、
    - 
  
  */
  
};


// if (process.argv.length != 4) throw "uploader.js <service canisterid> <your dfx identity name>"
let serviceCanisterId = process.argv[2]
let identityName = process.argv[3]
// let jsonPath = process.argv[4]

console.log("canisterid = " + serviceCanisterId)
console.log("identity name = " + identityName)
// console.log("json path = " + jsonPath)

search(serviceCanisterId, identityName)
