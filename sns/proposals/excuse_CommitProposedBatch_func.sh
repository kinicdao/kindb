#!/bin/sh

export COMMAND_ROOT=$(pwd)

NEURON_ID=$1
BATCH_ID=$2
EVIDENCE_BLOB=$3
CID=${4:-"74iy7-xqaaa-aaaaf-qagra-cai"}
FUNCTION_ID=${5:-1003}
EVIDENCE_BLOB=$(bin/didc decode "4449444c016d7b010020${EVIDENCE}" | grep "^  blob " | sed -e "s/  blob //; s/,//; s/\"//g; ")


# Set current directory to the directory this script is in
SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT")
cd $SCRIPT_DIR

TITLE="🤖 Excuse CommitProposedBatch function"
URL="https://dashboard.internetcomputer.org/sns/7jkta-eyaaa-aaaaq-aaarq-cai/proposal/8"
SUMMARY="This proposal excuses CommitProposedBatch function witch allows SNS to commit proposed batch."
BLOB="$(${COMMAND_ROOT}/bin/didc encode --format blob "(record { batch_id = ${BATCH_ID}; evidence = blob \"${EVIDENCE_BLOB}\"})")"

../scripts/create_proposal_ExcuseGenericNervousSystemFunction.sh "${TITLE}" "${URL}" "${SUMMARY}" "${FUNCTION_ID}" "${BLOB}" $NEURON_ID