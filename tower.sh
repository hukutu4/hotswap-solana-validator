#!/bin/bash
# # #   send / get   tower   # # # # # # # # # # # #
source ./env_loader.sh
if [ -z "$1" ]; then
  echo "warning! Input IP, like: ./tower.sh to user@XXX.XX.XX.XX"
  exit 1
fi
DIR=$1  # transfer direction ('to' / 'from')
SERV=$2 # transfer server addr (root@xxx.xx.xx.xx)

# ssh connection
if [ -f $IDENTITY_FILE_PATH ]; then chmod 600 $IDENTITY_FILE_PATH
  else echo -e "\033[31m - WARNING !!! no any ssh-identity files in $IDENTITY_FILE_PATH - \033[0m"
fi 

# wait for window
solana-validator -l $SOLANA_LEDGER_PATH wait-for-restart-window --min-idle-time 2 --skip-new-snapshot-check

# read current keys status
validator=$(solana address -k $VALIDATOR_IDENTITY)

# get tower from Secondary server
if [[ $DIR == 'from' ]]; then 
  echo -e "\033[31m get tower from\033[0m" $SERV; 
  read -p "are you ready? " RESP; if [ "$RESP" != "y" ]; then exit 1; fi
  scp -P $SSH_REMOTE_PORT -i $IDENTITY_FILE_PATH $SERV:$SOLANA_LEDGER_PATH/tower-1_9-$validator.bin $SOLANA_LEDGER_PATH
fi

# send tower to Secondary server
if [[ $DIR == 'to' ]]; then 
  echo -e "\033[32m send tower to\033[0m" $SERV; 
  read -p "are you ready? " RESP; if [ "$RESP" != "y" ]; then exit 1; fi
  scp -P $SSH_REMOTE_PORT -i $IDENTITY_FILE_PATH $SOLANA_LEDGER_PATH/tower-1_9-$validator.bin $SERV:$SOLANA_LEDGER_PATH
fi
