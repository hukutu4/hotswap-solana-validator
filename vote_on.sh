#!/bin/bash
# # #   Start Voting   # # # # # # # # # # # # # # # # # # # # #
source ./env_loader.sh
rpcURL=$(solana config get | grep "RPC URL" | awk '{print $3}')
PUB_KEY=$(solana-keygen pubkey $VALIDATOR_IDENTITY)

FORCE=$1
if [ -z "$FORCE" ]; then # no 'force' flag, so waiting for 'delinquent' status
  Delinquent=false
  until [[ $Delinquent == true ]]; do
    JSON=$(solana validators --url $rpcURL --output json-compact 2>/dev/null | jq '.validators[] | select(.identityPubkey == "'"${PUB_KEY}"'" )')
    LastVote=$(echo "$JSON" | jq -r '.lastVote')
    Delinquent=$(echo "$JSON" | jq -r '.delinquent')
    echo -ne "Looking for "$PUB_KEY". LastVote="$LastVote" \r"
    sleep 3
  done
fi

if [ -f $SOLANA_LEDGER_PATH/tower-1_9-$PUB_KEY.bin ];
  then  TOWER_STATUS=' with existing tower'; TOWER_FLAG="--require-tower"
  else  TOWER_STATUS=' without tower';       TOWER_FLAG=""
fi

command_output=$(solana-validator -l $SOLANA_LEDGER_PATH set-identity $TOWER_FLAG $VALIDATOR_IDENTITY 2>&1)
command_exit_status=$?
echo $command_output 
if [ $command_exit_status -eq 0 ];
  then echo -e "\033[32m set validator-keypair successful \033[0m"
  else echo -e "\033[31m can not set validator-keypair \033[0m"
fi

ln -sfn $VALIDATOR_IDENTITY $IDENTITY_LINK_FILE

echo -e "\033[32m vote ON\033[0m"$TOWER_STATUS
