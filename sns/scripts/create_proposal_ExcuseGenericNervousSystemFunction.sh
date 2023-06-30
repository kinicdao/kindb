#!/bin/sh

TITLE=$1
URL=$2
SUMMARY=$3
FUNCTION_ID=$4
BLOB=$5
NEURON_ID=$6

# Set current directory to the directory this script is in
SCRIPT=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT")
cd $SCRIPT_DIR


PROPOSAL="(record {
  title=\"${TITLE}\";
  url=\"${URL}\";
  summary=\"${SUMMARY}\";
  action=opt variant {
    ExecuteGenericNervousSystemFunction = record {
      function_id=${FUNCTION_ID}:nat64;
      payload=${BLOB}
    }
  }
})"

./submit_proposal.sh "${PROPOSAL}" $NEURON_ID