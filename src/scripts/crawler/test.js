// Public Lib
import puppeteer from 'puppeteer';
import fs from 'fs'

// Local scrips
import scraper from './scraper.js';
import {isSubnetId} from './utils.js';


async function main() {

  const browser = await puppeteer.launch({
    headless : true,
    channel: 'chrome' // use local chrome app
  });
  
  const old_DB = JSON.parse(fs.readFileSync("KinicDB.json", 'utf8'));
  
  const new_DB = {};
  
  let limit = 0;
  let collection = {};
  const canisterId = 'y7klb-lqaaa-aaaai-aa3va-cai';
  await scraper(browser, `https://${canisterId}.raw.icp0.io`, collection)
  
  // for (const r of old_DB) {
  //   if (limit > 10) break;
  
  //   if (!isSubnetId(r["subnetid"])) continue;
  //   const canisterId = r["canisterid"];
  //   const collection = {}
  //   // try {
  //     await scraper(browser, `https://${canisterId}.raw.icp0.io`, collection)
  //   // }
  //   // catch (e) {
  //   //   console.log("err: " + e);
  //   //   new_DB[canisterId] = {"err": '${e}'};
  //   // };
  //   new_DB[canisterId] = collection;
  //   limit += 1;
  // }

  browser.close()
  
    
  // Save
  // let write_options = {
  //   encoding: 'utf-8',
  //   flag: 'w',
  //   mode: 0o666
  // };
  // fs.writeFile(`src/scripts/crawler/words.json`, JSON.stringify(new_DB, null, '    '), write_options, err => {
  //   if (err) {
  //     console.log("Error writing file: " + err);
  //   } else {
  //     console.log("Success");
  //   }
  // });

  fs.writeFileSync('src/scripts/crawler/words.json', JSON.stringify(new_DB, null, '    '));

  console.log("finish")
}

await main()




// const collection = {}

// await scraper(browser, 'https://7mzuj-xaaaa-aaaai-acojq-cai.raw.icp0.io', collection)