#!/bin/sh

PROPOSAL="${1}"
NEURON_ID=$2

cd $COMMAND_ROOT

bin/quill sns   \
  --canister-ids-file ./sns_canister_ids.json  \
  --pem-file ~/.config/dfx/identity/$(dfx identity whoami)/identity.pem \
  make-proposal \
  --proposal "${PROPOSAL}"  \
  "${NEURON_ID}" > msg.json
bin/quill send --yes msg.json
rm -f msg.json