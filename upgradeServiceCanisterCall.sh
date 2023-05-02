#!/usr/local/bin/ic-repl -r http://localhost:8080

identity user "~/.config/dfx/identity/$DFX_USER/identity.pem";

import index = "bkyz2-fmaaa-aaaaa-qaaaq-cai";

call index.upgradeServiceCanisterByPk("test", file(".dfx/local/canisters/candb_service/candb_service.wasm"))
