### How to start

1. Start dfx

    `dfx start --clean --background`

1. Deploy index canister & Create service canister by PK:"kinicdb" from index canister. owners are index canister and installer of it. If you want to add more owners, you can add them by `vec {<extra prinicpals>}`

    `dfx deploy candb_index && dfx canister call candb_index createServiceCanisterByPk '("kinicdb", vec {principal <extra prinicpals>; principal <extra prinicpals>;})'`

1. Generate candid types

    `dfx canister create candb_service && dfx deploy main && npm run generate-declarations`


1. Upload JSON(text) to service canister. it takes few minutes.

    `node src/scripts/upload/uploader.js <the service canisterid> $(dfx identity whoami) <json(text) file path>`


### IndexCanister.mo

For Only Owner
- `createServiceCanisterByPk : Text -> asyc ?Text`

- `autoScaleServiceCanister : Text -> async Text`

### ServiceCanister.mo

For Only Owner
- `upload : Text -> async ()`

For Web Client
- `searchCategory : (Text, ?Text) -> async (Text, ?Text)`

    Usage:  `searchCategory(<Category>, null)`
    Return: `(<JSON_TEXT>, ?<NEXT_KEY>)`

- `categorySearchNewest : (Text, ?Text) -> async (Text, ?Text)`

    Usage:  `categorySearchNewest(<Category>, null)`
    Return: `(<JSON_TEXT>, ?<NEXT_KEY>)`

- `searchTerm : (Text, ?Text) -> async (Text, ?Text)`

    Usage:  `searchTerm(<Term>, null)`
    Return: `(<JSON_TEXT>, ?<NEXT_KEY>)`

- `searchCanisterId : Text -> async Text`

    Usage:  `searchCanisterId(<CanisterId>)`
    Return: `(<JSON_TEXT>)`


### How add controllers to service canisters

1. add controller by dfx command

    `dfx canister update-settings nw5jb-vqaaa-aaaaf-qaj4a-cai --add-controller SOMTHINGHERERER`

1. add them as owner
    - `dfx build candb_service`

    - `export DFX_USER=$(dfx identity whoami)`

    - `ic-repl -r https://ic0.app`

    - \> `identity user "~/.config/dfx/identity/$DFX_USER/identity.pem"`

    - \> `import index = "<index canister id>"`

    - \> `let wasm = file(".dfx/local/canisters/candb_service/candb_service.wasm")`

    - \> `call index.upgradeServiceCanisterByPk("knicdb", wasm, vec {principal "<extra owner id>"})`

