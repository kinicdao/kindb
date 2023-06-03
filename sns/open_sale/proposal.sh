#!/bin/bash

set -euo pipefail

export SNS_SWAP_ID="7sppf-6aaaa-aaaaq-aaata-cai"

export DEADLINE=$(($(date +%s) + 1209600 )) # 2 weeks
ic-admin   \
   --nns-url "https://nns.ic0.app/" propose-to-open-sns-token-swap  \
   --proposer $DEV_NEURON \
   --sns-token-e8s 150000000000000  \
   --min-icp-e8s 50000000000000  \
   --max-icp-e8s 150000000000000  \
   --min-participant-icp-e8s 100000000  \
   --max-participant-icp-e8s 10000000000000  \
   --community-fund-investment-e8s 25200000000000  \
   --swap-due-timestamp-seconds "${DEADLINE}"  \
   --target-swap-canister-id "${SNS_SWAP_ID}"  \
   --min-participants 300  \
   --neuron-basket-count 5  \
   --neuron-basket-dissolve-delay-interval-seconds 7889400  \
   --sale-delay-seconds 86400 \
   --proposal-title "$(cat ./sns/open_sale/title.md)"  \
   --summary "$(cat ./sns/open_sale/summary.md)"