#!/bin/sh

export COMMAND_ROOT=$(pwd)

NEURON_ID=$1
TARGET_PID=$2
PERMISSION=$3
CID=${4:-"74iy7-xqaaa-aaaaf-qagra-cai"}
FUNCTION_ID=${5:-1000}

# Set current directory to the directory this script is in
SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT")
cd $SCRIPT_DIR


TITLE="🤖 Excuse GrantPermission function"
URL="https://dashboard.internetcomputer.org/sns/7jkta-eyaaa-aaaaq-aaarq-cai/proposal/8"
SUMMARY="This proposal grants ${PERMISSION} permission to ${TARGET_PID}"
BLOB="$(${COMMAND_ROOT}/bin/didc encode --format blob "(record {to_principal = principal\"${TARGET_PID}\"; permission = variant {${PERMISSION}}})")"


../scripts/create_proposal_ExcuseGenericNervousSystemFunction.sh "${TITLE}" "${URL}" "${SUMMARY}" "${FUNCTION_ID}" "${BLOB}" $NEURON_ID