#!/usr/local/bin/ic-repl -r http://localhost:8080

identity user "~/.config/dfx/identity/$DFX_USER/identity.pem";

import index = "rrkah-fqaaa-aaaaa-aaaaq-cai";

let wasm = file("build/outputs/candb_service.wasm");

call index.upgradeServiceCanisterByPk("kindb", wasm, vec {principal "dl4qi-ihmtt-ug3sl-bnick-g4c2c-kmux5-whva5-mtdst-pbbmh-vkcpf-bae"})
