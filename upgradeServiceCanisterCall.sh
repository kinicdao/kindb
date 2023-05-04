#!/usr/local/bin/ic-repl -r http://localhost:8080

identity user "~/.config/dfx/identity/$DFX_USER/identity.pem";

import index = "rrkah-fqaaa-aaaaa-aaaaq-cai";

let wasm = file(".dfx/local/canisters/candb_service/candb_service.wasm");

call index.upgradeServiceCanisterByPk("knicdb", wasm, vec {principal "zs4e3-n56gl-pz5si-uglqd-eqttc-zr5o2-gcrlk-waeha-hhjbf-qfbap-fae"})
