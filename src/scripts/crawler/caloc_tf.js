import fs from 'fs';

export function caloc_tf(sites, page_count_include_the_word) {

  // delete empty word tf
  Object.entries(sites).forEach(([host, page_infos] = entry) => {
    Object.entries(page_infos).forEach(([path, info] = entry, index) => {
      if (info.word_tf.length == 0) {
        delete sites[host][path]
      }
    });
  });

  // 単語数と単語の種類の平均を求める用
  let total_page_count = 0;
  let total_word_cout = 0;
  let total_kind_word_count = 0;

  // 単語が含まれている文章数
  // let page_count_include_the_word = {};


  let res = Object.entries(sites).map(([host, page_infos] = entry) => {
    // console.log(host)
    let pages = [];
    let titles = [];
    let params = [];
    let words = {};
    Object.entries(page_infos).forEach(([path, info] = entry, index) => {
      total_page_count++;
      pages.push(path)
      titles.push(info.title)

      let kind_of_words = {};
      
      let total = 0;
      Object.entries(info.word_tf).forEach(([_, count] = entry) => {
        total += count;
      });
      Object.entries(info.word_tf).forEach(([word, count] = entry) => {
        let tf = count/total;
        let idx = index;
        if (words[word] == undefined) {
          words[word] = [[tf], [idx]]
        }
        else {
          words[word][0].push(tf)
          words[word][1].push(idx)
        };

        if (kind_of_words[word] == undefined) {
          kind_of_words[word] = count
        }
        else {
          kind_of_words[word] += count;
        };
      });
      
      // for idf
      let count_kind_of_words = Object.entries(kind_of_words).length;
      let cont_of_words = 0;
      Object.entries(kind_of_words).forEach(([w, count])=>{
        cont_of_words+=count; // このページにおける単語数

        //  単語が含まれている文章数をカウント
        if (page_count_include_the_word[w] == undefined) {
          page_count_include_the_word[w] = 1
        }
        else {
          page_count_include_the_word[w] += 1;
        };
      });
      params.push([cont_of_words, count_kind_of_words]);

      total_word_cout += cont_of_words;
      total_kind_word_count += count_kind_of_words;
    });
    
    return [host, pages, titles]
    // return [host, pages, titles, params] // [ ((Host, [Path], [Title]), [(Word, [Tf], [PathIdx])]) ]
  });

  // ToDo: そのwordが含まれている文章数

  res = res.filter(([host, pages, titles]) => pages.length != 0);

  // console.log(res)

  return [res, total_page_count, total_word_cout, total_kind_word_count]

};
