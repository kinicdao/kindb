// Public Lib
import puppeteer from 'puppeteer';
import fs from 'fs';
// import Math from 'Math';

// Local scrips
import {explore_one_page_V2} from './scraper.js';
import {isSubnetId} from './utils.js';
import { type } from 'os';


async function main(start_crawling_index) {

  const browser = await puppeteer.launch({
    headless : true,
    channel: 'chrome' // use local chrome app
  });

  // const Start = 0;
  // const End = Start+100;
  const crawling_list = JSON.parse(fs.readFileSync("KinicDB.json", 'utf8'));
  await crawling(browser, crawling_list, start_crawling_index-1);

  browser.close();
  // console.log("finish")
};



async function crawling(browser, crawling_list, start_crawling_index) {

  const CRAWLING_LENGTH = crawling_list.length;
  let crawling_index = start_crawling_index; // default '-1';

  const date = new Date()
  let crawling_date = date.toLocaleDateString('en-GB').split('/').reverse().join('');

  console.log("crawling_list len = " + CRAWLING_LENGTH)

  let page = await browser.newPage();

  while (true) {

    while(true) {
      crawling_index++;
      if (crawling_index >= CRAWLING_LENGTH) return;
      console.log("canisterid: " + crawling_list[crawling_index].canisterid);
      console.log("type: " + crawling_list[crawling_index]["type"])
      let is_app_type = (crawling_list[crawling_index]["type"] == "app");
      if (is_app_type) break;

    };

    let current_crawling_index = crawling_index;
    let canisterId = crawling_list[current_crawling_index]["canisterid"];
    let linked_url_count = 0;
    let collection = {};
    let unsearch = [`https://${canisterId}.raw.icp0.io`];

    console.log("start scraping site")

    while (unsearch.length != 0) {
      // 未サーチのリンクが０になるまで、explore_one_pageで処理する
      // scrape pages until there are not un-searched links.s
      linked_url_count++;
      const next_href = unsearch.shift();
      await explore_one_page_V2(page, next_href, unsearch, collection);
      console.log(`crawling_idx: ${current_crawling_index}, concurrent_id: 0, canister: ${canisterId}, now deal: ${linked_url_count} ,rest unsaerch: ${unsearch.length} \n`)
    };

    // Save the result
    // fs.writeFile(`src/scripts/crawler/word_chunks/idx_${Math.floor(current_crawling_index/1000)}K/idx_${current_crawling_index}_${canisterId}.json`, JSON.stringify({"canisterId": canisterId, "collection": collection, "lastseen": crawling_date}, null, '    '), err => {
    //   if (err) console.log(err.message);
    // });
    console.log(collection)

  }

  return;

};

let start_crawling_index = process.argv[2]
if (start_crawling_index == undefined) start_crawling_index = 0;

await main(start_crawling_index);
