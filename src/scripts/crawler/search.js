// See https://forum.dfinity.org/t/using-dfinity-agent-in-node-js/6169/55

import { Actor, HttpAgent } from "@dfinity/agent";
import { importIdentity } from "../upload/loadpem.js";
import { createActor as ServiceCreateActor } from "../../declarations/tf_storage_service/index.js"; // Need to commentout "export const main = createActor(canisterId);" in this file.
import fs from 'fs';

import { caloc_tf } from "./caloc_tf.js";


const N_COUNT_DOCUMENTS = 724+853+333; // document count
const N_AVERAGE_COUNT_WORDS = (40674+191220+28772)/N_COUNT_DOCUMENTS; // document length
const N_AVERAGE_KIND_WORDS = (24261+90241+18266)/N_COUNT_DOCUMENTS// kinds of word in the document

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

  let query = ["dashboard", "developer"];
  
  let res = await serviceActor.search(query)
    .then(res => {
      console.log("OK");
      // console.log(res);
      return res
    })
    .catch(e => {
      console.log(e);
    });

  console.log("result num: " + res.length);
  // console.log("response size:" + JSON.stringify(res).length);

  // [ '27kdi-daaaa-aaaak-qaena-cai', [ [ 'NFT Info', '', [Array] ] ] ]

  // let DummyIDF = 1.0; // dummy : idf[word]
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
    pages.forEach(([title, path, count_words, kind_words, tfs]) => {
      let sum_tf_idf = 0;
      tfs.forEach((tf, i) => {
        let word = query[i];
        let idf = Math.log2(N_COUNT_DOCUMENTS/page_count_include_the_word[word]) //  IDF[word]
        // similer Okapi BM25
        const k = 2.0;
        const b = 0.75;
        sum_tf_idf += idf*(((k+1)*tf) / (tf+k*(1-b+b*(N_AVERAGE_COUNT_WORDS/Number(count_words))))); // 通常のBM25は|d|/aver(D)だが、これだと文章が短い方が高スコアになってしまうので、逆にしている。
        // sum_tf_idf += idf*tf;
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

  
};


// if (process.argv.length != 4) throw "uploader.js <service canisterid> <your dfx identity name>"
let serviceCanisterId = process.argv[2]
let identityName = process.argv[3]
// let jsonPath = process.argv[4]

console.log("canisterid = " + serviceCanisterId)
console.log("identity name = " + identityName)
// console.log("json path = " + jsonPath)

search(serviceCanisterId, identityName)
