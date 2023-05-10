# Summary

This proposal offers Kinic Search Engine to the NNS to be turned into a decentralized service by creation of an SNS to govern the Kinic dApp canisters.

# Who sent this proposal ?
This proposal is sent by the Kinic Developer Organization. Kinic is a fully on-chain and open source [BE](https://github.com/kinicdao/kindb) [FE](https://github.com/kinicdao/kinic) Search technology platform running end-to-end on the Internet Computer. The project is presented in this [whitepaper](https://74iy7-xqaaa-aaaaf-qagra-cai.ic0.app/whitepaper) and related technical docs.

# What is the purpose of this proposal?
The Kinic Development Organization offers the Kinic dApp to the NNS to be turned into a decentralized service by creation of a [Service Nervous System (SNS) DAO](https://internetcomputer.org/sns) to govern Kinic. The Kinic platform consists of 3 dapp canisters and 1 asset canister. The following Kinic canisters would be directly controlled by the SNS:

Kinic frontend canister 74iy7-xqaaa-aaaaf-qagra-cai
Kinic app utility and analytics canister ny7ej-oaaaa-aaaaf-qaj5a-cai
Kinic search index canister msqgt-mqaaa-aaaaf-qaj2a-cai
Kinic search service canister  nw5jb-vqaaa-aaaaf-qaj4a-cai

Any and all other canisters are in turn controlled by one of the above listed canisters and would thus also be indirectly controlled by the SNS.

If this proposal is approved, the NNS mandates that the necessary steps to create a [Service Nervous System (SNS) DAO](https://internetcomputer.org/sns) to govern Kinic are taken.

# What is the technical effect of this proposal?
By adopting the proposal, Kinic will be required to install the necessary SNS canisters on the SNS subnet. These canisters will initially be in a pre-decentralization-sale mode, limiting their capabilities and preventing token movement until the decentralization sale is finalized. Essentially, the proposal grants the identity, with principal ID kavk3-oyaaa-aaaao-ajihq-cai and controlled by Kinic, the ability to make a call to the SNS wasm modules canister (SNS-W) for the purpose of installing SNS canisters. This privilege is a one-time occurrence, as it will be revoked after the call is made.

# What is this proposal not about / what will be decided in a second, future proposal?
This proposal does not address specific aspects such as parameter choices for the Kinic SNS. Those details will be covered in a separate future proposal. The upcoming proposal will focus on initiating the Kinic decentralization sale and establishing the SNS DAO. It will encompass decisions related to parameter choices, conditions for the decentralization sale, and other pertinent matters.