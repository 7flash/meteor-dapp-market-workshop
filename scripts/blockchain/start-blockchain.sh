#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ACCOUNT_PASSWORD="$(cat "${DIR}/password")"
NOHUP_LOCATION="${DIR}/nohup.out"

NETWORK_ID=$1;
IDENTITY=$2;

tmpdir="tmp${NETWORK_ID}"

# create start scripts
baseCommand="geth \
--datadir=${DIR}/${tmpdir}/ \
--logfile=${DIR}/${tmpdir}/blockchain.log \
--rpc \
--rpcaddr localhost \
--rpccorsdomain \"*\" \
--genesis=${DIR}/genesis.json \
--password ${DIR}/password"

# append network id if it's set, disable dev mode
if [ $NETWORK_ID ]; then
  baseCommand+=" --networkid $NETWORK_ID"
  if [ $IDENTITY ]; then
    baseCommand+=" --identity $IDENTITY"
  fi
else
  baseCommand+=" --dev"
fi

echo $baseCommand
# append account details
accountList="${baseCommand} account list"
accountNew="${baseCommand} account new"

# create temp directory and empty log file
mkdir -p "${DIR}/${tmpdir}/" && touch "${DIR}/${tmpdir}/blockchain.log"

# check if we have any accounts
if [[ "$(${accountList})" =~ \{([^}]*)\} ]]; then
  ETH_ACCOUNT="${BASH_REMATCH[1]}"
else
  echo "No Accounts found, creating a new one"
  eval $accountNew
  # try agian
  if [[ "$(${accountList})" =~ \{([^}]*)\} ]]; then
    ETH_ACCOUNT="${BASH_REMATCH[1]}"
  else
    echo "Failed creating account"
    exit
  fi
fi

# create minin command
miningScript="${baseCommand} --unlock ${ETH_ACCOUNT}"

if [ ! $NETWORK_ID ]; then
  miningScript+=" js ${DIR}/miner.js"
fi

function cleanup () {
  echo ' Interrupted: killing geth'
  pkill geth
}

trap cleanup INT

echo $miningScript
echo ""

nohup $(eval $miningScript) > $NOHUP_LOCATION & tail -n 0 -f $NOHUP_LOCATION




