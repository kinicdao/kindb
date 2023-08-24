// Public Libs
import puppeteer from 'puppeteer';
import { removeStopwords, eng, fra } from 'stopword'
// import {extract as extractSentence} from "sentence-extractor";
import {franc} from 'franc';

// Local scripts
import {caloc_tf, waitTillHTMLRendered, delete_last_slash} from './utils.js';

export async function explore_one_page_V2(page, working_href, unsearch_hrefs, collection, current_crawling_index) {
  let working_url_pathname;
  let title;
  try {
    // Make URL object of current page link
    const working_url = new URL(working_href)
    working_url_pathname = delete_last_slash(working_url.pathname);
    const origin = working_url.origin;

    let res = await page.goto(working_href, {"waitUntil":"load"});
    if (res == null) return write_err_to_collection("page.got returns null", collection, working_url_pathname, title);
    if (res.status() >= 400) return write_err_to_collection(`the page response is over 400 code : ${res.status()}`, collection, working_url_pathname, title);

    await waitTillHTMLRendered(page);

    title = await page.title().catch((e) => {return ""});

    const body_element = await page.$("body");
    let text_content = await page.evaluate(elm => elm.innerText, body_element);

    if (text_content.length == 0) return write_err_to_collection("text_content is empty", collection, working_url_pathname, title);

    const lang = franc(text_content);

    let word_tf = [];
    let text = " ";
  
    if ("eng" && "spa" && "rus" && "por" && "fra" && "deu" && "ita") {
      let txt = text_content.toLowerCase();
      txt = txt.toLowerCase();
      txt = txt.replace(/[^!-~]/g,' ')
      txt = txt.replace(/[\s]+/g,' ')
      txt = txt.replace(/ +/g,' ')
      txt = txt.trim(); // trip head and tail space
      txt = txt.split(' '); // split by space

      // const regex = /\b\w{6,}\b/g;
      const words = removeStopwords(txt).map((w) => w.toLowerCase());

      word_tf = caloc_tf(words);
    }
    else {
      text = text_content;
    };

    const hrefs = await page.$$eval('a', links => links.map(a => a.href));
    let link_set = new Set()

    for (let href of hrefs) {
      try {
        const sub_url = new URL(href);
        const sub_url_pathname = delete_last_slash(sub_url.pathname);
        if (sub_url.host != working_url.host) continue; // if it doesn't match current domain, skip this link
        if (sub_url_pathname == working_url_pathname) continue; // if it is same page, skip this link。
        if (sub_url_pathname.split("/").length > 5) continue; // too deep link
        if ((unsearch_hrefs.length + Object.keys(collection).length) > 10) continue;
        const extention = sub_url_pathname.split('.')[1];
        if (extention != '' && extention != 'html') continue;

        /*
        メモ
        sub_url.pathnameは、oringin/path/　と oringin/pathを区別しないので、最後の/をとる。
        /pathname/#commentなどのアンカーが付いているリンクをunsearchに入れると壊れる。
        それ以降に無限にpathが続いてしまう。相対リンクで書いてあって、それが繰り返されてしまう。
        */
        
        const linked_href = `${origin}${sub_url_pathname}`;
        
        // if current path is not root, do not collect sub paths.
        if (working_url_pathname == '' && !unsearch_hrefs.includes(linked_href) && collection[sub_url_pathname] == null) {  // if the link is in collection or unsearch queue, push the link to unsearch queue
          unsearch_hrefs.push(linked_href);
          // console.log("add unsearch,   href: " + linked_href + "  path: " + sub_url_pathname)
        };
        link_set.add(sub_url_pathname) //  add urls linked from this page
      }
      catch (_) {
        continue
      };
    };

    console.log(`title: ${title}, path: ${working_url_pathname}`);

    collection[working_url_pathname] = {
      "title" : title,
      "lang" : lang,
      "word_tf" : word_tf, 
      "link_set" : Array.from(link_set),
      "text": text_content
    }

  }
  catch (e) { // if the URL is broken, skip this page.
    console.log(`error in ${working_url_pathname}: \n${e}`);
    write_err_to_collection(e, collection, working_url_pathname, title);
    if (e != "TimeoutError: Navigation timeout of 30000 ms exceeded") {
      console.log("Continued at page " + JSON.stringify(current_crawling_index))
      return;
    } else {
      console.log("Died at page " + JSON.stringify(current_crawling_index))
      throw(JSON.stringify(current_crawling_index));
    }
  };

};



function write_err_to_collection(err_msg, collection, pathname, title) {
  collection[pathname] = {
    "word_tf" : [], 
    "link_set" : [],
    "status" : err_msg.toString(),
    "title" : title
  }
};