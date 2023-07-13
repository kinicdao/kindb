// Public Libs
import puppeteer from 'puppeteer';
import { removeStopwords, eng, fra } from 'stopword'
import {extract as extractSentence} from "sentence-extractor";

// Local scripts
import {caloc_tf, waitTillHTMLRendered} from './utils.js';


export default async function scraper(browser, root_link, collection) {
  let page;
  try {
    page = await browser.newPage();
    const unsearch_hrefs = [root_link];
  
    while (unsearch_hrefs.length > 0) {
      const working_href = unsearch_hrefs.shift()
      console.log(`working: ${working_href}, linkis: ` + unsearch_hrefs.length)
      await explore_one_page(page, working_href, unsearch_hrefs, collection)
    }
  
    // // Save
    // let write_options = {
    //   encoding: 'utf-8',
    //   flag: 'w',
    //   mode: 0o666
    // };
    // fs.writeFile(`src/scripts/crawler/words.json`, JSON.stringify(collection, null, '    '), write_options, err => {
    //   if (err) {
    //     console.log("Error writing file: " + err);
    //   } else {
    //     console.log("Success");
    //   }
    // });

  }
  finally{
    await page.close();
  }
}



async function explore_one_page(page, working_href, unsearch_hrefs, collection) {
  // Make URL object of current page link
  let working_url;
  try {
    working_url = new URL(working_href)
  }
  catch (e) { // if the URL is broken, skip this page.
    write_err_to_collection(`error in URL object: ${e}`, collection, working_url.pathname, "")
    return
  };

  // Go to this page
  let res;
  try {
    res = await page.goto(working_url.href, {"waitUntil":"load"})
  }
  catch (e) {
    write_err_to_collection(`error in goto page: ${e}`, collection, working_url.pathname, "")
    return
  };

  // リンク切れの場合は、何も記録しない
  // wip: tfを計算する場合は、空のページは無視する。文字数が0としてカウント
  if (res.status() >= 400) {
    write_err_to_collection(`error in 400: ${res.status()}`, collection, working_url.pathname, "")
    return
  }

  // Wait until this page finish loading
  try {
    await waitTillHTMLRendered(page);
  }
  catch (e) {
    write_err_to_collection(`error in waitTillHTMLRendered: ${e}`, collection, working_url.pathname, "")
    return
  };

  // Get title and lang
  let title = "";
  try {
    title = await page.title()
  }
  catch (e) {
    title = "";
    console.log("In title: " + e)
  };
  let lang = "";
  try {
    await page.evaluate('document.querySelector("html").getAttribute("lang")')
  }
  catch (e) {
    lang = "en"
    console.log("In lang: " + e)
  }

  // Currently this can parse only English pages
  if (!lang.includes("en") && lang.length != 0) {
    write_err_to_collection(`lang: ${lang}`, collection, working_url.pathname, title)
    return
  };


  // Count the number of words
  let body_element;
  let text_content = "";
  try {
    body_element = await page.$("body")
    text_content = await page.evaluate(elm => elm.innerText, body_element)
  } catch (e) {
    write_err_to_collection(`error in body_element or text_content: ${e}`, collection, working_url.pathname, title)
    return
  };
  if (text_content.length == 0) {
    write_err_to_collection(`error: text_content is empty`, collection, working_url.pathname, title)
    return
  };

  let words;
  let word_tf;
  try {
    const regex = /\b\w{6,}\b/g;
    words = removeStopwords(text_content.match(regex)).map((w) => w.toLowerCase());
    word_tf = caloc_tf(words);
  }
  catch (e) {
    write_err_to_collection(`error in match regex or removeStopwords func: ${e}`, collection, working_url.pathname, title)
    return
  };


  // Extract sentences including above words
  const sentences_per_word = {}
  try {
    const separate_newline = text_content.split("\n")
    let all_sentences = []
    for (const line of separate_newline) {
      all_sentences = all_sentences.concat(extractSentence(line))
    }
    for (const target_word of words) {
      let longest_sentence = ""
      for (const sentence of all_sentences) {
        if (sentence.match(target_word) && longest_sentence.length < sentence.length) {
          longest_sentence = sentence;
        }
      };
      sentences_per_word[target_word] = longest_sentence;
    }
  }
  catch (e) {
    sentences_per_word = {}
  };


  // Scrape all links
  let hrefs;
  try {
    hrefs = await page.$$eval('a', links => links.map(a => a.href))
  }
  catch (e) {
    write_err_to_collection(`lang: ${e}`, collection, working_url.pathname, title)
    return
  };
  let link_set = new Set()
  for (let href of hrefs) {
    try {
      const sub_url = new URL(href);
      if (sub_url.host != working_url.host) continue; // if it doesn't match current domain, skip this link
      if (sub_url.pathname == working_url.pathname) continue; // if it is same page, skip this link。
  
      if (!unsearch_hrefs.includes(sub_url.href) && collection[sub_url.pathname] == null) unsearch_hrefs.push(sub_url.href) // if the link is in collection or unsearch queue, push the link to unsearch queue
      link_set.add(sub_url.pathname) //  add urls linked from this page
    }
    catch (_) {
      continue
    };
  }

  // save
  collection[working_url.pathname] = {
    "title" : title,
    "lang" : lang,
    "word_tf" : word_tf, 
    "link_set" : Array.from(link_set),
    "sentence": sentences_per_word
  }


  console.log(`title: ${title}, lang: ${lang}, words: ${words.length}\n`)
};


function write_err_to_collection(err_msg, collection, pathname, title) {
  collection[pathname] = {
    "word_tf" : [], 
    "link_set" : [],
    "status" : err_msg,
    "title" : title
  }
};