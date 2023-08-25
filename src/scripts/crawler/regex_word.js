import fs from 'fs';
import { Principal } from "@dfinity/principal";
import { removeStopwords, eng, fra } from 'stopword'


// let txt = fs.readFileSync("src/scripts/crawler/log/sample.txt", 'utf8')
// console.log("\n\n============ raw text ============\n")
// console.log(txt)


// console.log("\n\n============ regexed word ============\n")

// txt = txt.toLowerCase();
// txt = txt.replace(/[^!-~]/g,' ')
// txt = txt.replace(/[\s]+/g,' ')
// txt = txt.replace(/ +/g,' ')
// txt = txt.trim(); // trip head and tail space
// let words = txt.split(' '); // split by space


// console.log(words)

function regex(words) {


  // console.log("\n\n============ delete word consits of num&symbol ============\n")

  const del_num = /^[!-9.-@¥[-`{-~]*$/gi
  words = words.filter((word) => {
    del_num.test("") //　連続でやると何故か壊れる...
    return (!del_num.test(word))
  })
  // console.log(words)

  // console.log("\n\n============ delete url ============\n")

  const url_regex = /(http|https):\/\//g
  words = words.filter((word) => {
    url_regex.test("")
    return (!url_regex.test(word))
  })
  // console.log(words)

  // console.log("\n\n============ delete prinipal id ============\n")
  const principal_regex = /([a-z0-9]{5}-){3,}/g
  words = words.filter((word) => {
    principal_regex.test("")
    return (!principal_regex.test(word))
  })
  // console.log(words)

  // console.log("\n\n============ delete long word ============\n")
  //　英単語の平均長は5文字弱
  // まず英数字のみで構成された10文字以上の単語は消していい
  const del_longword = /[0-9a-z]{20,}/g
  words = words.filter((word) => {
    del_longword.test("")
    return (!del_longword.test(word))
  })
  // console.log(words)


  // console.log("\n\n============ delete word begin num or symbol ============\n")

  const del_begin_num = /^[0-9|!-\/:-@¥[-`{-~]/g
  words = words.filter((word) => {
    del_begin_num.test("")
    return (!del_begin_num.test(word))
  })
  // console.log(words)


  // console.log("\n\n============ separate '-' or '_' ============\n")

  const separate_word = /[^a-z0-9]|,/g
  words = words.map((word) => {
    separate_word.test("")
    let tmp = word.replace(separate_word, ' ');
    tmp = tmp.replace(/[\s]+/g,' ') 
    tmp = tmp.trim(); // trip head and tail space
    return tmp.split(' ')
  })
  // console.log(words.flat())

  words =  words.flat()

  //============ delete 1 length word ============

  words = words.filter((word) => {
    if (word.length == 1) return null
    else return word
  })

   //============ delete num again ============

   words = words.filter((word) => {
     del_num.test("") //　連続でやると何故か壊れる...
     return (!del_num.test(word))
   })

  return words
}





// if (process.argv.length != 3) throw "regex_word.js <start index> <end index>"
// let start_index = process.argv[2]
// let end_index = process.argv[3]

// let start_index = 0
// let end_index = 3




let page_count_include_the_word = {};

let kinicDB = JSON.parse(fs.readFileSync('kinicDB.json', 'utf8'));



// Load word data files
const chunks = fs.readdirSync('src/scripts/crawler/word_chunks');
let l = 0;
for (const chunk of chunks) {
  if (chunk == ".gitkeep" || chunk == ".DS_Store") continue
  console.log("chunk: " + chunk)
  const filenames = fs.readdirSync('src/scripts/crawler/word_chunks/' + chunk);

  let sites = [];

  console.log("filenames length " + filenames.length);
  for (const filename of filenames) {
    // console.log(filename)
    if (filename == '.gitkeep' || filename == '.DS_Store') continue;
    let site = JSON.parse(fs.readFileSync(`src/scripts/crawler/word_chunks/${chunk}/${filename}`, 'utf8'));
    let host = site['canisterId'];
    let page_infos = site['collection'];
    // console.log(host)

    // collectionの中のそれぞれのpathのword-tfを更新して終わり。
    Object.entries(page_infos).forEach(([path, info]) => {
      if (path.split('.')[1] == 'xml') {
        delete site.collection[path]
        console.log("delete " + path)
        return
      };
      if (info.word_tf.length != 0) {
        let words = Object.entries(info.word_tf).map(([word, count]) => {
          // console.log(word)
          let arr =[];
          for (let i = 0; i<count; i++) {
            arr.push(word)
          };
          return arr
        })
        words = words.flat();

        // apply regexp
        words = regex(words);
        words = removeStopwords(words);


        let word_tf = {};
        words.forEach((word) => {
          if (word_tf[word] == undefined) {
            word_tf[word] = 1;
          }
          else {
            word_tf[word] += 1;
          }
        });

        Object.entries(word_tf).forEach(([w, count])=>{
          // cont_of_words+=count; // このページにおける単語数
  
          //  単語が含まれている文章数をカウント
          if (page_count_include_the_word[w] == undefined) {
            page_count_include_the_word[w] = 1
          }
          else {
            page_count_include_the_word[w] += 1;
          };
        });

        site.collection[path].word_tf = word_tf;
      }
    });

    let isOffcial = false

    kinicDB.forEach((md) => {
      if (md.canisterid == host && md.status == "official") {
        isOffcial = true;
      };
    });

    if (isOffcial) {
      fs.writeFile(`src/scripts/crawler/regulared_words_chunks/official/${chunk}/${filename}`, JSON.stringify(site, null, '    '), err => {
        if (err) console.log(err.message);
      });
      // console.log("official " + host)
    }
    else {
      fs.writeFile(`src/scripts/crawler/regulared_words_chunks/non_official/${chunk}/${filename}`, JSON.stringify(site, null, '    '), err => {
        if (err) console.log(err.message);
      });
      // console.log("non official " + host)
    }

  };

  fs.writeFile(`src/scripts/crawler/regulared_words_chunks/page_count_include_the_word.json`, JSON.stringify(page_count_include_the_word, null, '    '), err => {
    if (err) console.log(err.message);
  });

  
}