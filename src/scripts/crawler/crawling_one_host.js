// Public Lib
import puppeteer from 'puppeteer';
import fs from 'fs';
// import Math from 'Math';

// Local scrips
import {explore_one_page_V2} from './scraper.js';
import {isSubnetId} from './utils.js';
import { type } from 'os';


async function main(canisterId) {

  const browser = await puppeteer.launch({
    headless : true,
    channel: 'chrome' // use local chrome app
  });

  let page = await browser.newPage();

  let collection = {};
  let unsearch = [`https://${canisterId}.raw.icp0.io`];
  while(unsearch.length != 0) {
    const next_href = unsearch.shift();
    await explore_one_page_V2(page, next_href, unsearch, collection);
    console.log(`canister: ${canisterId}, rest unsaerch: ${unsearch.length}, now deal: ${next_href}  \n`)
  };

  console.log("\n\n=======================================\n\n");
  console.log(Object.entries(collection));

  fs.writeFile(`src/scripts/crawler/log/${canisterId}.json`, JSON.stringify(collection, null, '    '), err => {
    if (err) console.log(err.message);
  });

  browser.close();
  // console.log("finish")
};

const host = "g4s5h-daaaa-aaaad-qbdpq-cai"

await main(host);
