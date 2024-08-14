#!/bin/sh

export COMMAND_ROOT=$(pwd)

NEURON_ID=$1
BATCH_ID=$2
EVIDENCE=$3
FUNCTION_ID=1006
EVIDENCE_BLOB=$(bin/didc decode "4449444c016d7b010020${EVIDENCE}" | sed -e "s/(blob //; s/,//; s/\"//g; s/)//")


# Set current directory to the directory this script is in
SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT")
cd $SCRIPT_DIR

TITLE="🤖 Excuse CommitProposedBatch function of KinicUI asset canister"
URL="ai.kinic.io"
SUMMARY="This proposal excuses CommitProposedBatch function of KinicUI asset canister, which allows SNS to commit proposed batch."
BLOB="$(${COMMAND_ROOT}/bin/didc encode --format blob "(record { batch_id = ${BATCH_ID}:nat; evidence = blob \"${EVIDENCE_BLOB}\"})")"

../scripts/create_proposal_ExcuseGenericNervousSystemFunction.sh "${TITLE}" "${URL}" "${SUMMARY}" "${FUNCTION_ID}" "${BLOB}" $NEURON_ID