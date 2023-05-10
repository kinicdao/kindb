#!/bin/bash

# cat ./sns/sns_w/title.md
# cat ./sns/sns_w/summary.md

$(dfx cache show)/ic-admin  \
  --secret-key-pem ~/.config/dfx/identity/$(dfx identity whoami)/identity.pem \
  --nns-url "${NNS_URL}" \
  propose-to-update-sns-deploy-whitelist \
  --added-principals "$DEVELOPER_WALLET_ID"  \
  --proposer "$DEVELOPER_NEURON_ID" \
  --proposal-title "$(cat ./sns/sns_w/title.md)"  \
  --summary "$(cat ./sns/sns_w/summary.md)"