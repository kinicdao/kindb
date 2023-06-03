# Summary

This is the proposal for the NNS to create an SNS DAO to govern the [Kinic dapp](https://kinic.io).

# Purpose

Kinic is a decentralized search engine which takes the concept of "dont't be evil" and transforms it into "can't be evil". Open-sourced and transparent SEO, machine learning and search algorithms, power a new paradigm in freedom to information-access. 

It is fully featured and runs on the Internet Computer blockchain. Kinic is [open source](https://github.com/kinicdao) and the code running on any canister smart contract [verifiably links back a particular version](https://github.com/kinicdao/kindb/tree/main/build) of the code. Web3 projects benefit from increased discoverability for their content. Furthermore, increased data accessiblity is valuable for researchers.

Kinic won its category in the [Supernova hackathon](https://supernova.devpost.com/) in summer 2022. Its development has often been community driven: with new features ideas and requests for data access coming from members of the Kinic community. Development has often been done by community developers and teams across organizations. Dfinity has used Kinic in the past to help discover phishing and scam sites hosted on the IC. Increased API access is a common request from prominent projects. Kinic is very suitable to become a public-good for these reasons. 

The Kinic DAO’s two million ICP funding target is based on comparable funding rounds for closed sourced or private companies:

- Privacy-focused search engine DuckDuckGo has raised a total of $172 million across four funding rounds, the most recent of which was $100 million in late 2020.
- In January 2022, The Graph Foundation raised $50 million to build an indexing protocol for querying data on networks like Ethereum and IPFS.
- In March 2023, Kaito raised $5.3 million to transform crypto search with ChatGPT.

The Kinic DAO is being formed to operate and steer the direction of Kinic, owned by the community, with no central controller. Holders of KINIC tokens can stake them as neurons which allow them to make and vote on proposals to change the Kinic dapp.

The SNS DAO will hold a treasury of KINIC tokens and ICP which can be used to fund the on-going development of the dapp. Future proposals will aim to incentive community grants and development. Here are a few areas that the treasury might be active:

- Development grants for increased utility for KINIC tokens.
- Better search algorithms and API.
- Open-sourced Motoko and Rust code that any developer can leverage.
- Zero-knowledge machine learning research and development that draws the interest and envy of tradional tech, while forming a net-positive impact for society.

For more information on the Kinic SNS please read the [whitepaper here](https://74iy7-xqaaa-aaaaf-qagra-cai.icp0.io/whitepaper).

# Proposed Token Distribution

Total token supply: 6 million Kinic tokens

Initially distributed:

- 51%: Reserved for the SNS treasury & under control of the Kinic DAO
- 25%: To be distributed by the NNS run decentralization sale which includes the Community Fund
- 10%: Allocated to the Kinic Developer Organization which vested over 3 years
- 10%: Allocated to seed funders and tecnology partners.
- 4% Kinic NFT holders.

Ledger transaction fee: 0.001 Kinic token

For more information on the initial token allocation please [read here](https://74iy7-xqaaa-aaaaf-qagra-cai.icp0.io/whitepaper).

# Governance

- Each decentralization sale participant (including the Community Fund) will receive their tokens in a basket of 5 equal value KINIC neurons with dissolve delays of 0, 3, 6, 9 and 12 months respectively
- The Kinic Developer Organization will receive its tokens in a basket of 3 neurons, each with a 1 month dissolve delay, but with vesting periods of 1, 2, 3 years.
- Seed investors and Kinic NFT holders will receive 3 neurons all with a dissolve delay of 1 month but with vesting periods of 0, 1, 2 years respectively.

The governance parameters for Kinic are proposed to be initially set as:

- Min stake: 0.1 KINIC tokens
- Min staking period for voting: 1 month

Voting Rewards: 2.5% of KINIC token supply minted annually

- Max staking bonus (for 1 year): 2x
- Max age for age bonus: 6 months
- Max age bonus: 1.25x

These parameters can be verified by querying the governance canister's get_nervous_system_parameters method at https://dashboard.internetcomputer.org/canister/74ncn-fqaaa-aaaaq-aaasa-cai

# Decentralization Sale

25% of the total supply of tokens are proposed to be distributed via an SNS decentralization sale. If the proposal is adopted, the sale will start after the specified delay. If the maximum number of ICP configured below is raised before that date the sale will conclude earlier.

Sale participation parameters:

- Min participation: 1 ICP
- Max participation: 100,000 ICP
- Max to be raised: 1,500,000 ICP
- Min to be raised: 500,000 ICP
- From Community Fund: 252,000 ICP
- Min participants: 300
- Sale due: 2 weeks
- Sale delay: 1 day

The sale is open to anyone, excluding US residents or citizens. Participation is either via the launchpad in the NNS front end: https://nns.ic0.app/ or on the command line using [quill](https://wiki.internetcomputer.org/wiki/How-To:_Participate_in_the_SNS_decentralization_sale_via_quill).

# Kinic dapp

The Kinic platform consists of 3 dapp canisters and 1 asset canister.

- Kinic frontend canister: `74iy7-xqaaa-aaaaf-qagra-cai`
- Kinic app utility and analytics canister: `ny7ej-oaaaa-aaaaf-qaj5a-cai`
- Kinic search index canister: `msqgt-mqaaa-aaaaf-qaj2a-cai` 
- Kinic search service canister: `nw5jb-vqaaa-aaaaf-qaj4a-cai`

- sns_governance: `74ncn-fqaaa-aaaaq-aaasa-cai`
- sns_index:  `7vojr-tyaaa-aaaaq-aaatq-cai`
- sns_ledger: `73mez-iiaaa-aaaaq-aaasq-cai`
- sns_root: `7jkta-eyaaa-aaaaq-aaarq-cai`
- sns_swap: `7sppf-6aaaa-aaaaq-aaata-cai`


# Verification

All the details above can be verified, by examining the initialized Kinic SNS canisters. [More detailed instructions here](https://wiki.internetcomputer.org/wiki/How-to:_Verify_SNS_decentralization_sale_proposal).