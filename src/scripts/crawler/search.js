// See https://forum.dfinity.org/t/using-dfinity-agent-in-node-js/6169/55

import { Actor, HttpAgent } from "@dfinity/agent";
import { importIdentity } from "../upload/loadpem.js";
import { createActor as ServiceCreateActor } from "../../declarations/tf_storage_service/index.js"; // Need to commentout "export const main = createActor(canisterId);" in this file.
import fs from 'fs';

import {searchContent} from "./searchContent.js";
import {searchTitle} from "./searchTitle.js";

const N_COUNT_DOCUMENTS = 724+853+333; // document count
const N_AVERAGE_COUNT_WORDS = (40674+191220+28772)/N_COUNT_DOCUMENTS; // document length
const N_AVERAGE_KIND_WORDS = (24261+90241+18266)/N_COUNT_DOCUMENTS// kinds of word in the document

async function search(serviceCanisterId, identityName) {
  // set service canister client
  const identity = importIdentity(identityName);
  const agent = new HttpAgent({
    // identity: identity,
    // host: "https://ic0.app",
    host: "http://127.0.0.1:8080",
    fetch,
  });
  const serviceActor = ServiceCreateActor(serviceCanisterId, {agent});

  let query = ["account"];

  let hosts_content = await searchContent(serviceActor, query);
  let hosts_title = await searchTitle(serviceActor, query);


  const weight = 0.5;
  // delete duplication
  hosts_title = hosts_title.filter(([host, t, p, title_score]) => {
    for (let i = 0; i < hosts_content.length; i++) {
      if (hosts_content[i][0] == host) {
        let content_score = hosts_content[i][3];
        let total_score =  content_score + weight * title_score;
        hosts_content[i] = [host,  hosts_content[i][1],  hosts_content[i][2], total_score]
        return null
      };
    };
    return [host, t, p, weight*title_score];
  });

  // merge
  let hosts = hosts_content.concat(hosts_title);
  console.log(hosts.length)

  let sorted_by_tf_idf = hosts.sort(function(a, b){
    return b[3] -  a[3]
  });

  let j = sorted_by_tf_idf.map(([h, t, p, s]) => {
    let info = {
      "id": 0,
      "canisterid": h,
      "subnetid": "sample-subnetid",
      "type": "app",
      "datalength": 80,
      "lastseen": "2023-08-10",
      "title": t,
      "subtitle": "sample-subtitle",
      "content": "",
      "apptype": "",
      "note": "",
      "status": "",
      "notnull": ""
    };

    return info
  });


  console.log(j)

  
};


// if (process.argv.length != 4) throw "uploader.js <service canisterid> <your dfx identity name>"
let serviceCanisterId = process.argv[2]
let identityName = process.argv[3]
// let jsonPath = process.argv[4]

console.log("canisterid = " + serviceCanisterId)
console.log("identity name = " + identityName)
// console.log("json path = " + jsonPath)

search(serviceCanisterId, identityName)
