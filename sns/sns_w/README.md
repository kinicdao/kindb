### How to submit SNS-W proposal

1. set your dev principal id as hotkey to NNS dapp.

1. set `NNS_URL` env. `export NNS_URL=https://nns.ic0.app/`

1. set wallet id. `export DEVELOPER_WALLET_ID=$(dfx identity --network ic get-wallet)`

1. set neuron id `export DEVELOPER_NEURON_ID=<your neuron id>`

1. make proposal `./proposal.sh`