#! /bin/sh

vessel install
$(vessel bin)/moc -o build/outputs/main.wasm $(vessel sources) -c canisters/main.mo
# $(vessel bin)/moc -o build/outputs/candb_index.wasm $(vessel sources) -c /project_root/canisters/candb_index.mo
# $(vessel bin)/moc -o build/outputs/candb_service.wasm $(vessel sources) -c /project_root/canisters/candb_service.mo

# chmod +x /project_root/build/outputs/main.wasm
# chmod +x /project_root/build/outputs/candb_index.wasm
# chmod +x /project_root/build/outputs/candb_service.wasm