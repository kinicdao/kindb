import fs from 'fs'

const aid_to_pid = JSON.parse(fs.readFileSync("./airdrop_target.json", 'utf8'))

let read_options = {
  encoding: 'utf-8',
  flag: 'r'
};

const nft_holders = fs.readFileSync("./nfthodlers_row.txt", 'utf8')

let pattern = /"([a-f0-9]{64})"/g;
let ids = [];
let pid_map = new Map();
let match;
while ((match = pattern.exec(nft_holders)) !== null) {
  let aid = match[1]
  let pid = aid_to_pid[aid]
  if (!pid) pid = "null"
  // console.log(aid, pid)
  let data = pid_map.get(pid)
  if(data) pid_map.set(pid, data+1)
  else pid_map.set(pid, 1)
}

const e8s = 100_000_000
let res = []
for (let item of pid_map.entries()) {
  let pid = item [0]
  let count = item[1]
  let amount =  1_600 * e8s * count
  let bucket1 = `- controller: ${pid}\n  stake_e8s: ${amount*0.25}\n  memo: 0\n  dissolve_delay_seconds: 2628000 # 1 month\n  vesting_period_seconds: 0`
  let bucket2 = `- controller: ${pid}\n  stake_e8s: ${amount*0.25}\n  memo: 1\n  dissolve_delay_seconds: 2628000 # 1 month\n  vesting_period_seconds: 31536000 # 1 year`
  let bucket3 = `- controller: ${pid}\n  stake_e8s: ${amount*0.50}\n  memo: 2\n  dissolve_delay_seconds: 2628000 # 1 month\n  vesting_period_seconds: 63072000 # 2 year`
  res.push(bucket1)
  res.push(bucket2)
  res.push(bucket3)
}


let write_options = {
  encoding: 'utf-8',
  flag: 'w',
  mode: 0o666
};
fs.writeFile('output.txt', res.join("\n\n"), write_options, err => {
  if (err) {
    console.log("Error writing file: " + err);
  } else {
    console.log("Success! Strings: \n" + res.join("\n\n"));
  }
});