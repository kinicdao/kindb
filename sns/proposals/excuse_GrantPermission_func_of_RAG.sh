#!/bin/sh

export COMMAND_ROOT=$(pwd)

NEURON_ID=$1
TARGET_PID=$2
PERMISSION=$3
FUNCTION_ID=1004

# Set current directory to the directory this script is in
SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT")
cd $SCRIPT_DIR


TITLE="🤖 Excuse GrantPermission function of RAG-Demo canister"
URL="https://va3nt-myaaa-aaaak-afjga-cai.icp0.io/"
SUMMARY="This proposal grants ${PERMISSION} permission of RAG-Demo canister to ${TARGET_PID}"
BLOB="$(${COMMAND_ROOT}/bin/didc encode --format blob "(record {to_principal = principal\"${TARGET_PID}\"; permission = variant {${PERMISSION}}})")"


../scripts/create_proposal_ExcuseGenericNervousSystemFunction.sh "${TITLE}" "${URL}" "${SUMMARY}" "${FUNCTION_ID}" "${BLOB}" $NEURON_ID