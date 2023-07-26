import fs from 'fs';

export function caloc_tf(sites) {

  // delete empty word tf
  Object.entries(sites).forEach(([host, page_infos] = entry) => {
    Object.entries(page_infos).forEach(([path, info] = entry, index) => {
      if (info.word_tf.length == 0) {
        delete sites[host][path]
      }
    });
  });

  let res = Object.entries(sites).map(([host, page_infos] = entry) => {
    // console.log(host)
    let pages = [];
    let titles = [];
    let words = {};
    Object.entries(page_infos).forEach(([path, info] = entry, index) => {
      // console.log(" " + path)
      pages.push(path)
      titles.push(info.title)
      
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
      });
    });

    return [host, pages, titles, Object.entries(words)] // [ ((Host, [Path], [Title]), [(Word, [Tf], [PathIdx])]) ]
  });

  res = res.filter(([host, pages, titles]) => pages.length != 0);

  // console.log(res)

  return res;

};
