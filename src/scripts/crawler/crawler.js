// Public Lib
import puppeteer from 'puppeteer';
import fs from 'fs';
// import Math from 'Math';

// Local scrips
import {explore_one_page_V2} from './scraper.js';
import {isSubnetId} from './utils.js';


async function main() {

  const browser = await puppeteer.launch({
    headless : true,
    channel: 'chrome' // use local chrome app
  });

  // const Start = 0;
  // const End = Start+100;
  const crawling_list = JSON.parse(fs.readFileSync("KinicDB.json", 'utf8'));
  const SIZE = 500;
  const len = Math.ceil(crawling_list.length/SIZE);
  console.log(len);
  for (let i = 0; i < len; i++) {
    const STR = i*SIZE;
    const END = i*SIZE+SIZE;
    const sub = crawling_list.slice(STR, END);
    const all_collection = await crawling(browser, crawling_list);

    console.log("end")

    fs.writeFile(`src/scripts/crawler/words_${STR}_${END}.json`, JSON.stringify(all_collection, null, '    '), err => {
      if (err) console.log(err.message);
    });
  };

  browser.close();
  // console.log("finish")
};


async function crawling(browser, crawling_list) {

  const MAX_CONCURRENCY = 40;
  const CRAWLING_LENGTH = crawling_list.length;
  let crawling_index = 0;
  let promises = [];

  let all_collection = {};

  console.log("crawling_list len = " + CRAWLING_LENGTH)

  for (let CONCURRENT_ID = 0; CONCURRENT_ID < MAX_CONCURRENCY; CONCURRENT_ID++) {
    let page = await browser.newPage();
    let p = new Promise((resolve) => {

      // lexical scope variables
      let canisterId = crawling_list[crawling_index++]["canisterid"];
      let linked_url_count = 0;
      let collection = {};
      let unsearch = [`https://${canisterId}.raw.icp0.io`];

      // console.log(`setting root href ${i}: ` + `https://${unsearch[0]}.raw.icp0.io`);
      // console.log(`excusing id: ${CONCURRENT_ID} ` + working_href);
      // console.log(`excusing id: ${CONCURRENT_ID} ` + working_href + " returned")

      (async function loop() {
        if (unsearch.length != 0) {
          linked_url_count++;
          const next_href = unsearch.shift();
          await explore_one_page_V2(page, next_href, unsearch, collection);
          console.log(`id: ${CONCURRENT_ID}, canister: ${canisterId}, now deal: ${linked_url_count} ,rest unsaerch: ${unsearch.length} \n`)
          loop();
          return
        };
        all_collection[canisterId] = collection;
        if (crawling_index < CRAWLING_LENGTH){
          // reset lexical scope variables
          canisterId = crawling_list[crawling_index++]["canisterid"];
          linked_url_count = 0;
          collection = {};
          unsearch = [`https://${canisterId}.raw.icp0.io`];

          console.log("start new site")
          loop()
          return
        };
        resolve();
      })();

    });
    promises.push(p);
  };

  await Promise.all(promises);

  return all_collection;

};


await main();
