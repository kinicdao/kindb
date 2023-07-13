import puppeteer from 'puppeteer';
import { removeStopwords, eng, fra } from 'stopword'
import fs from 'fs';
import {extract as extractSentence} from "sentence-extractor";


const LAUNCH_OPTION = {
  headless : true,
  channel: 'chrome', // use local chrome app
};

const browser = await puppeteer.launch(LAUNCH_OPTION);

async function main() {
  try {
    // Open a new tab
    const page = await browser.newPage();
    // Got to the link
    const res = await page.goto('', {"waitUntil":"load"})
      .catch(e => { // if this page is broken, skip this page.
        console.log("catched error")
        return
      });
    
  
    console.log("never should come here")
  
    /*
  
    // Select same domain links
  
    // 
  
    同一階層以下かつ、同一ドメインのlinkを抜き出す。
    再帰的に全てのリンクを辿りながら、textを抽出する。
    link参照関係のグラフを作る。
    それぞれでTF-IDFを計算する。(参照リンク先のTFも加味させる。加重平均など)
    keyword listを作成して、page graphに保存する。
    keyword listから、その単語が含まれる最長の文章を切り出して、保存する。
  
    幅優先探索で、上位でヒットしなければ、次の層へ行く。
    word2vecで、類似度をスコアリング。(query wordが2つ以上の場合、類似度の平均)
    同一の層に複数ヒットした場合、それらをlistingする。
    その階層でヒットしないなら、それよりも下を探索する。
    全て探索して閾値を超えない場合、listingしない。
  
    検索時のクエリ範囲は、できるだけ同じ単語数になるようにすると並列性が上がる。
  
    func wide-search take page
      open this page
      extract text and links
      close this page
      pick only subdirectory links
      for the links
  
  
  
    go to root page
    extract text and links
    close this page
  
    wide-prime-search
      put the links to un-search-quene
      get a link of top and put the link to searched-quene
      
  
    for : go to the linked pages
  
  
    linkを抜き出して、未探索のlinkをqueueに入れる。
    queueから先頭をgetして、再帰する。
    この時、探索時ずみのlinkがある場合、探索はしないが、そのリストを保持する。
  
    search-a, search-b quene text type
    Map<link-name, set-array of sub-link>
    */
    
  
    // const selector = ".App-container a.App-link";
    // await page.waitForSelector(selector);
    // const urls = await page.$$eval(selector, (list) => list.map((a) => a.href));
    // console.log("This is a list of articles that was crawled from http://localhost:3000", urls);
  
  } finally {
   await browser.close();
  }
}

await main();


async function waitTillHTMLRendered(page, timeout = 30000) {
	const checkDurationMsecs = 1000;  // チェックする間隔(ミリ秒)
	const minStableSizeIterations = 3;  // ○回チェックしてサイズに変化がなければOKとする
	const maxChecks = timeout / checkDurationMsecs;
	let lastHTMLSize = 0;
	let checkCounts = 1;
	let countStableSizeIterations = 0;
  
	while(checkCounts++ <= maxChecks){
		let html = await page.content();
		let currentHTMLSize = html.length; 

		let bodyHTMLSize = await page.evaluate(() => document.body.innerHTML.length);

		if (lastHTMLSize == currentHTMLSize) {
			console.log('last: ', lastHTMLSize, ' == curr: ', currentHTMLSize, " body html size: ", bodyHTMLSize);
		} else {
			console.log('last: ', lastHTMLSize, ' <> curr: ', currentHTMLSize, " body html size: ", bodyHTMLSize);
		}

		if(lastHTMLSize != 0 && currentHTMLSize == lastHTMLSize) {
			countStableSizeIterations++;
		} else {
			countStableSizeIterations = 0; //reset the counter
		}

		if(countStableSizeIterations >= minStableSizeIterations) {
			console.log("Page rendered fully..");
			break;
		}

		  lastHTMLSize = currentHTMLSize;
		  await page.waitForTimeout(checkDurationMsecs);
	}
}