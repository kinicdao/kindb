
# How to Setup OpenSale

## Set environment

1. Set environment

    ```bash
    export IC_COMMIT=1aa7f0b5d7f3bf58fd42b0be895f070cdd5f8492
    export OS=darwin # linux or darwin, you can check uname -rs
    export PJ_ROOT=$(pwd)
    export NETWORK="ic"

    export DEV_PID="dl4qi-ihmtt-ug3sl-bnick-g4c2c-kmux5-whva5-mtdst-pbbmh-vkcpf-bae"
    export DEV_IDENTITY_NAME=
    export PEM_FILE="~/.config/dfx/identity/$DEV_IDENTITY_NAME/identity.pem"

    export CANDB_INDEX_PID="msqgt-mqaaa-aaaaf-qaj2a-cai"
    export CANDB_SERVICE_PID="nw5jb-vqaaa-aaaaf-qaj4a-cai"
    export FRONTEND_PID="74iy7-xqaaa-aaaaf-qagra-cai"
    export MAIN_PID="ny7ej-oaaaa-aaaaf-qaj5a-cai"

    export CANISTER_IDS_PATH=".dfx/ic/canister_ids.json"
    ```

## Reproducible build canisters and deploy it

1. Compile binaries with reproducible builds

1. Upgrade candb_index

    candb_index
    ```bash
    cp build/outpus/candb_index.wasm .dfx/ic/canisters/candb_index/candb_index.wasm
    dfx deploy --network ic $CANDB_INDEX_PID
    dfx canister --network ic info $CANDB_INDEX_PID
    ```

    candb_service
    ```bash
    upgradeServiceCanisterCall.sh
    dfx canister --network ic info $CANDB_SERVICE_PID
    ```

## Deploy SNS canisters

1. Install tools
    1. Make bin directory
        ```bash
        mkdir $PJ_ROOT/bin
        ```
    1. Install sns-cli, quill and sns-quill to deploy SNS canisters and make a proposal
        ```bash
        ./sns/init_config/install_tools.sh
        ```

1. Deploy sns canister
    
    1. Download sns canister wasm binaries

        ```bash
        mkdir $PR_ROOT/sns/init_config/sns_wasms
        DFX_IC_COMMIT=IC_COMMIT dfx sns download --wasms-dir $PR_ROOT/sns/init_config/sns_wasms
        DFX_IC_COMMIT=IC_COMMIT dfx sns import
        ```


    1. Check your [NNS](https://nns.ic0.app/) neuron hotkey 
        ```bash
        dfx identity use <Your pId likned to hotkey>
        ```

    1. Deploy SNS canisters and save the ids to `sns/canister_ids.json`
        
        **Warning**
        Ensure you have enough cycles. 180T cycles

        ```bash
        bin/sns-cli deploy \
          --network "${NETWORK}" \
          --init-config-file $PR_ROOT/sns/init_config/sns-kinic.yaml \
          --wasms-dir $PR_ROOT/sns/init_config/sns_wasms \
          --save-to $CANISTER_IDS_PATH
        ```
    
    1. Make sns_canister_ids.json
        ```bash
        echo "{
        \"governance_canister_id\": \"$(dfx canister --network "${NETWORK}" id sns_governance)\",
        \"index_canister_id\": \"$(dfx canister --network "${NETWORK}" id sns_index)\",
        \"ledger_canister_id\": \"$(dfx canister --network "${NETWORK}" id sns_ledger)\",
        \"root_canister_id\": \"$(dfx canister --network "${NETWORK}" id sns_root)\",
        \"swap_canister_id\": \"$(dfx canister --network "${NETWORK}" id sns_swap)\"
        }" > $PJ_ROOT/sns/sns_canister_ids.json
        ```


## Register dapps

1. Update controllers

    candb_index
    ```bash
    dfx canister --network "${NETWORK}" update-settings --set-controller $(dfx canister --network "${NETWORK}" id sns_root) $CANDB_INDEX_PID
    dfx canister --network "${NETWORK}" info $CANDB_INDEX_PID
    ```

    candb_service
    Remove only the dev team pid from the controller.
    ```bash
    dfx canister --network "${NETWORK}" update-setting --add-controller $(dfx canister --network "${NETWORK}" id sns_root) $CANDB_SERVICE_PID
    dfx canister --network "${NETWORK}" update-setting --remove-controller $DEV_PID $CANDB_SERVICE_PID
    dfx canister --network "${NETWORK}" info $CANDB_SERVICE_PID
    ```

    Do same for frontend and main.

    ```bash
    dfx canister --network "${NETWORK}" update-settings --set-controller $(dfx canister --network "${NETWORK}" id sns_root) $FRONTEND_PID
    dfx canister --network "${NETWORK}" info $FRONTEND_PID
    ```

    ```bash
    dfx canister --network "${NETWORK}" update-settings --set-controller $(dfx canister --network "${NETWORK}" id sns_root) $MAIN_PID
    dfx canister --network "${NETWORK}" info $MAIN_PID
    ```

1. Register dapps to Kinic SNS

    1. Get your SNS neuron ids

        ```bash
        IDS="$(dfx canister call sns_governance list_neurons "(record {of_principal = opt principal\"$DEV_PID\"; limit = 0})" | grep "^          id = blob" | sed "s/^ *id = \(.*\);$/'(\1)'/" | xargs -L1 bin/didc encode | sed 's/^.\{20\}//')" && \
        export NEURON_ID_LIST=(`echo $IDS|xargs`)
        ```
    1. Submit Register Dapps Proposal
        

        ```bash
        mkdir $PJ_ROOT/sns/proposal_msg
        ```

        candb_index
        ```bash
        $PJ_ROOT/sns/scripts/register_dapp_proposal.sh $CANDB_INDEX_PID $NEURON_ID_LIST[1]
        ```

        candb_service
        ```bash
        $PJ_ROOT/sns/scripts/register_dapp_proposal.sh $CANDB_SERVICE_PID $NEURON_ID_LIST[1]
        ```

        frontend canister
        ```bash
        $PJ_ROOT/sns/scripts/register_dapp_proposal.sh $FRONTEND_PID $NEURON_ID_LIST[1]
        ```

        main canister
        ```bash
        $PJ_ROOT/sns/scripts/register_dapp_proposal.sh $MAIN_PID $NEURON_ID_LIST[1]
        ```

    1. Vote

        candb_index
        ```bash
        $PJ_ROOT/sns/scripts/vote.sh 1 y $NEURON_ID_LIST[2]
        $PJ_ROOT/sns/scripts/vote.sh 1 y $NEURON_ID_LIST[3]
        ```

        candb_service
        ```bash
        $PJ_ROOT/sns/scripts/vote.sh 2 y $NEURON_ID_LIST[2]
        $PJ_ROOT/sns/scripts/vote.sh 2 y $NEURON_ID_LIST[3]
        ```

        frontend canister
        ```bash
        $PJ_ROOT/sns/scripts/vote.sh 3 y $NEURON_ID_LIST[2]
        $PJ_ROOT/sns/scripts/vote.sh 3 y $NEURON_ID_LIST[3]
        ```

        main canister
        ```bash
        $PJ_ROOT/sns/scripts/vote.sh 4 y $NEURON_ID_LIST[2]
        $PJ_ROOT/sns/scripts/vote.sh 4 y $NEURON_ID_LIST[3]
        ```
    
    1. Check Status

        Proposalas
        ```bash
        dfx canister --network "${NETWORK}" call sns_governance list_proposals '(record {include_reward_status = vec {}; limit = 0; exclude_type = vec {}; include_status = vec {};})'
        ```

        Parameters
        ```bash
        quill sns  \
          --canister-ids-file ./sns_canister_ids.json  \
          --pem-file $PEM_FILE  \
          status
        ```