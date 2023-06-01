#! /bin/bash

PROPOSAL_ID=$1
YES_OR_NO=$2
NEURON_ID=$3

echo "proposal Id is $PROPOSAL_ID"
echo "vote - $YES_OR_NO"
echo "proposer is $NEURON_ID"

MSG_PATH="$PJ_ROOT/sns/proposal_msg/vote_to_id_${PROPOSAL_ID}_by_${NEURON_ID}.json"

bin/quill sns \
  --canister-ids-file ./sns_canister_ids.json \
  --pem-file ~/.config/dfx/identity/$DEV_IDENTITY_NAME/identity.pem \
  register-vote \
  --vote $YES_OR_NO \
  --proposal-id $PROPOSAL_ID \
  $NEURON_ID > $MSG_PATH
bin/quill send --insecure-local-dev-mode --yes $MSG_PATH
