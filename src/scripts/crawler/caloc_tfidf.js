import fs from 'fs'

// const collection = JSON.parse(fs.readFileSync("src/scripts/crawler/words.json", 'utf8'))
// const links = collection["/blog/communities"]["link_set"]
// collection["/blog/communities"]["link_set"] = links.filter(item => item !== '/faq')
// console.log(collection["/blog/communities"]["link_set"])

const url = new URL("https://7mzuj-xaaaa-aaaai-acojq-cai.raw.icp0.io/how-to-use")
console.log(url)

