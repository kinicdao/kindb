#! /bin/bash

CANISTER_PID=$1
NEURON_ID=$2

echo "canister is $CANISTER_PID"
echo "proposer is $NEURON_ID"

bin/quill sns   \
  --canister-ids-file  $PJ_ROOT/sns/sns_canister_ids.json  \
  --pem-file  $PEM_FILE  \
  make-proposal \
  --proposal "(record { title=\"Register dapps\"; url=\"https://kinic.io\"; summary=\"This proposal registers dapps with SNS\"; action=opt variant {RegisterDappCanisters = record {canister_ids=vec {principal\"$CANISTER_PID\"}}}})"   \
  $NEURON_ID > $PJ_ROOT/sns/proposal_msg/register_${CANISTER_PID}.json
bin/quill send --yes $PJ_ROOT/sns/proposal_msg/register_${CANISTER_PID}.json