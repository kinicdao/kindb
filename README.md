### How to start

1. Start dfx

    `dfx start --clean --background`

1. Deploy index canister & Create service canister by PK: test from index canister

    `dfx deploy candb_index && dfx canister call candb_index createServiceCanisterByPk '("test")'`

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
