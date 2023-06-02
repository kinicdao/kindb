#!/usr/local/bin/ic-repl -r http://localhost:8080

identity user "~/.config/dfx/identity/$DFX_USER/identity.pem";

import index = "rrkah-fqaaa-aaaaa-aaaaq-cai";

let wasm = file("build/outputs/candb_service.wasm");

call index.upgradeServiceCanisterByPk("kinicdb", wasm, vec {})
