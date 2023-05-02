import { Actor, HttpAgent } from "@dfinity/agent";
import { IDL } from "@dfinity/candid";
import crypto from "isomorphic-webcrypto";
import fetch from "node-fetch";
import protobuf from "protobufjs";
import extendProtobuf from "../lib/index.js";
import { Principal } from "@dfinity/principal";
import axios from 'axios';
import delayAdapterEnhancer from 'axios-delay';
const agent = new HttpAgent({ host: "https://ic0.app" });
import { createActor as canDBService } from "../candbservice/index.js";
import { createActor as canDBIndex } from "../candbindex/index.js";

global.window = global;
global.fetch = fetch;
global.crypto = crypto;

let root;
let dbIndexCanisterId = 'rkp4c-7iaaa-aaaaa-aaaca-cai'
let dbServiceCanisterId;

let host = 'http://127.0.0.1:8080' //'https://ic0.app'

let dbIndex = canDBIndex(dbIndexCanisterId, {agentOptions: {host}})
let dbService;

// User can check the current numbers of canisters here https://dashboard.internetcomputer.org/subnets
let subs = [
  {id: 'qdvhd-os4o2-zzrdw-xrcv4-gljou-eztdp-bj326-e6jgr-tkhuc-ql6v2-yqe', current: 52130, diff: 1000},
  {id: 'mpubz-g52jc-grhjo-5oze5-qcj74-sex34-omprz-ivnsm-qvvhr-rfzpv-vae', current: 29466, diff: 1000},
  {id: 'brlsh-zidhj-3yy3e-6vqbz-7xnih-xeq2l-as5oc-g32c4-i5pdn-2wwof-oae', current: 4602, diff: 1000},
  {id: 'lhg73-sax6z-2zank-6oer2-575lz-zgbxx-ptudx-5korm-fy7we-kh4hl-pqe', current: 3729, diff: 1000},
  {id: 'lspz2-jx4pu-k3e7p-znm7j-q4yum-ork6e-6w4q6-pijwq-znehu-4jabe-kqe', current: 2429, diff: 1000},
  {id: 'shefu-t3kr5-t5q3w-mqmdq-jabyv-vyvtf-cyyey-3kmo4-toyln-emubw-4qe', current: 526, diff: 100},
  {id: 'pae4o-o6dxf-xki7q-ezclx-znyd6-fnk6w-vkv5z-5lfwh-xym2i-otrrw-fqe', current: 442, diff: 100},
  {id: 'ejbmu-grnam-gk6ol-6irwa-htwoj-7ihfl-goimw-hlnvh-abms4-47v2e-zqe', current: 237, diff: 100},
  {id: 'w4asl-4nmyj-qnr7c-6cqq4-tkwmt-o26di-iupkq-vx4kt-asbrx-jzuxh-4ae', current: 167, diff: 100},
  {id: 'qxesv-zoxpm-vc64m-zxguk-5sj74-35vrb-tbgwg-pcird-5gr26-62oxl-cae', current: 134, diff: 100},
  {id: 'snjp4-xlbw4-mnbog-ddwy6-6ckfd-2w5a2-eipqo-7l436-pxqkh-l6fuv-vae', current: 150, diff: 100},
  {id: 'io67a-2jmkw-zup3h-snbwi-g6a5n-rm5dn-b6png-lvdpl-nqnto-yih6l-gqe', current: 123, diff: 100},
  {id: 'eq6en-6jqla-fbu5s-daskr-h6hx2-376n5-iqabl-qgrng-gfqmv-n3yjr-mqe', current: 81663, diff: 1000},
  {id: 'o3ow2-2ipam-6fcjo-3j5vt-fzbge-2g7my-5fz2m-p4o2t-dwlc4-gt2q7-5ae', current: 17769, diff: 10000},
  {id: 'k44fs-gm4pv-afozh-rs7zw-cg32n-u7xov-xqyx3-2pw5q-eucnu-cosd4-uqe', current: 8925, diff: 1000},
  {id: '5kdm2-62fc6-fwnja-hutkz-ycsnm-4z33i-woh43-4cenu-ev7mi-gii6t-4ae', current: 8454, diff: 1000},
  {id: 'pjljw-kztyl-46ud4-ofrj6-nzkhm-3n4nt-wi3jt-ypmav-ijqkt-gjf66-uae', current: 5691, diff: 1000},
  {id: 'gmq5v-hbozq-uui6y-o55wc-ihop3-562wb-3qspg-nnijg-npqp5-he3cj-3ae', current: 4588, diff: 1000},
  {id: '6pbhf-qzpdk-kuqbr-pklfa-5ehhf-jfjps-zsj6q-57nrl-kzhpd-mu7hc-vae', current: 3713, diff: 1000},
  {id: 'e66qm-3cydn-nkf4i-ml4rb-4ro6o-srm5s-x5hwq-hnprz-3meqp-s7vks-5qe', current: 2791, diff: 1000},
  {id: 'yinp6-35cfo-wgcd2-oc4ty-2kqpf-t4dul-rfk33-fsq3r-mfmua-m2ngh-jqe', current: 2067, diff: 1000},
  {id: 'cv73p-6v7zi-u67oy-7jc3h-qspsz-g5lrj-4fn7k-xrax3-thek2-sl46v-jae', current: 6727, diff: 1000},
  {id: 'opn46-zyspe-hhmyp-4zu6u-7sbrh-dok77-m7dch-im62f-vyimr-a3n2c-4ae', current: 3814, diff: 1000},
  {id: '4ecnw-byqwz-dtgss-ua2mh-pfvs7-c3lct-gtf4e-hnu75-j7eek-iifqm-sqe', current: 2303, diff: 1000},
  {id: 'nl6hn-ja4yw-wvmpy-3z2jx-ymc34-pisx3-3cp5z-3oj4a-qzzny-jbsv3-4qe', current: 2136, diff: 1000},
  {id: 'jtdsg-3h6gi-hs7o5-z2soi-43w3z-soyl3-ajnp3-ekni5-sw553-5kw67-nqe', current: 1501, diff: 1000},
  {id: '3hhby-wmtmw-umt4t-7ieyg-bbiig-xiylg-sblrt-voxgt-bqckd-a75bf-rqe', current: 1850, diff: 1000},
  {id: 'csyj4-zmann-ys6ge-3kzi6-onexi-obayx-2fvak-zersm-euci4-6pslt-lae', current: 564, diff: 1000},
  {id: '4zbus-z2bmt-ilreg-xakz4-6tyre-hsqj4-slb4g-zjwqo-snjcc-iqphi-3qe', current: 103, diff: 100},
];

// Other subnets
//fuqsr-in2lc-zbcjj-ydmcw-pzq7h-4xm2z-pto4i-dcyee-5z4rz-x63ji-nae 0
//2fq7c-slacv-26cgz-vzbx2-2jrcs-5edph-i5s2j-tck77-c3rlz-iobzx-mqe 0
//x33ed-h457x-bsgyx-oqxqf-6pzwv-wkhzr-rm2j3-npodi-purzm-n66cg-gae 34 SNS
//tdb26-jop6k-aogll-7ltgs-eruif-6kk7m-qpktf-gdiqx-mxtrf-vb5e6-eqe 40 NNS


const showRegistry = async (entry, end) => {
  let canisters = [];
  const registry = Actor.createActor(() => IDL.Service({}), {
    agent,
    canisterId: "rwlgt-iiaaa-aaaaa-aaaaa-cai",
  });
  extendProtobuf.default(registry, root.lookupService("Registry"));

  //const { deltas } = await registry.get_changes_since({});
  let routingTableResponse = await registry.get_value({
    key: Buffer.from('routing_table'),
  });
  let output = root.lookupType('RoutingTable').decode(routingTableResponse.value);
  //let tmp = output.entries[0].subnetId.principalId.raw;
  output.entries.forEach(async (ent) => {
      if (Principal.fromUint8Array(ent.subnetId.principalId.raw).toText() === entry.id) {
        let aa = Principal.fromUint8Array(ent.range.endCanisterId.principalId.raw).toText()
        let bb = Principal.fromUint8Array(ent.range.startCanisterId.principalId.raw).toText()
        let aaArray = Principal.fromText(aa).toUint8Array();
        let bbArray = Principal.fromText(bb).toUint8Array();

        let sumEnd = aaArray[5] + aaArray[6] + aaArray[7]
        let sumStart = bbArray[5] + bbArray[6] + bbArray[7]

        let counter = Array((entry.current + entry.diff)).fill(0)
        let cc = 0;
        counter.forEach(async (canister) => {
          cc++;
          if (cc > (entry.current - entry.diff)) {
            canisters.push({canisterID: Principal.fromUint8Array(bbArray).toText(), subnetID: Principal.fromUint8Array(ent.subnetId.principalId.raw).toText()})
          }
          if (bbArray[7] < 255) {
            bbArray[7] = bbArray[7] + 1
          } else if (bbArray[6] < 255) {
            if (bbArray[7] === 255) {
              bbArray[7] = 0
            }
            bbArray[6] = bbArray[6] + 1
          } else {
            if (bbArray[7] === 255) {
              bbArray[7] = 0
            }
            if (bbArray[6] === 255) {
              bbArray[6] = 0
            }
            bbArray[5] = bbArray[5] + 1
          }
        });

      }

  });
  end(canisters);
};

const getCanisterInfo = (canister) => {
  return new Promise ((resolve, reject) => {
    axios
    .get('https://'+canister.canisterID+'.raw.ic0.app')
    .then(res => {
      canister.title = ""
      canister.subtitle = ""
      canister.content = ""
      canister.apptype = ""
      canister.status = ""

      if (res.data.length == 2185) {
        canister.type = "wallet"
      } else if (res.data.length == 3367) {
        canister.type = "wallet"
      } else if (res.data.length == 2130) {
        canister.type = "wallet"
      } else if (res.data.length == 1723) {
        canister.type = "wallet"
      } else if (res.data.length == 1477) {
        canister.type = "wallet"
      } else {
        canister.type = "app"
      }
      canister.dataLength = res.data.length;
      canister.lastSeen = new Date()
      resolve(canister);
    }).catch(error => {
    });
  });
}

const findCanister = async (canisterID) => {
    try {
        let res = await dbService.searchCanisterId(canisterID, '')
        let response = JSON.parse(res)
        return response;
    } catch (error) {
        console.error(error.stack);
        return false;
    }
};

const setUp = async (cb) => {
  const bundle = await import("./bundle.json", { assert: { type: "json" } });
  root = protobuf.Root.fromJSON(bundle.default);

  let indexId = await dbIndex.getCanistersByPK('test')
  if (indexId && indexId[0]) {
      dbServiceCanisterId = indexId[0]
      dbService = canDBService(dbServiceCanisterId, {agentOptions: {host}})
  }
  cb()
};


setUp(() => {
  subs.forEach((entry) => {
    showRegistry(entry, async (canisters) => {
      canisters.forEach(async (canister) => {
        let can = await getCanisterInfo(canister);
        let endCan = await findCanister(can.canisterID);
        if (endCan.rows[0].count === '0') {
            console.log(JSON.stringify(can) + ',');
        }
      })
    });
  });
});
