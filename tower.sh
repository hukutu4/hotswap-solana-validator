#!/bin/bash
# # #   send / get   tower   # # # # # # # # # # # #
SOL_USER="solana"
SSH_REMOTE_PORT=22

IDENTITY_FILE_PATH="$HOME/.ssh/id_rsa"
SOLANA_USER_HOME=$HOME

source $HOME/.profile
if [ -z "$1" ]; then
  echo "warning! Input IP, like: ./tower.sh to user@XXX.XX.XX.XX"
  exit 1
fi
DIR=$1  # transfer direction ('to' / 'from')
SERV=$2 # transfer server addr (root@xxx.xx.xx.xx)

# ssh connection
if [ -f $IDENTITY_FILE_PATH ]; then chmod 600 $IDENTITY_FILE_PATH
  else echo -e '\033[31m - WARNING !!! no any ssh-identity files in $HOME/.ssh/ - \033[0m'
fi 

# wait for window
solana-validator -l $HOME/solana/ledger wait-for-restart-window --min-idle-time 10 --skip-new-snapshot-check

# read current keys status
empty=$(solana address -k $HOME/solana/unstaked-identity.json)
link=$(solana address -k $HOME/solana/identity.json)
validator=$(solana address -k $HOME/solana/mnt/validator-keypair.json)

# get tower from Secondary server
if [[ $DIR == 'from' ]]; then 
  echo -e "\033[31m get tower from\033[0m" $SERV; 
  read -p "are you ready? " RESP; if [ "$RESP" != "y" ]; then exit 1; fi
  scp -P $SSH_REMOTE_PORT -i $IDENTITY_FILE_PATH $SERV:$SOLANA_USER_HOME/solana/ledger/tower-1_9-$validator.bin $SOLANA_USER_HOME/solana/ledger
fi

# send tower to Secondary server
if [[ $DIR == 'to' ]]; then 
  echo -e "\033[32m send tower to\033[0m" $SERV; 
  read -p "are you ready? " RESP; if [ "$RESP" != "y" ]; then exit 1; fi
  scp -P $SSH_REMOTE_PORT -i $IDENTITY_FILE_PATH $HOME/solana/ledger/tower-1_9-$validator.bin $SERV:$SOLANA_USER_HOME/solana/ledger
fi
