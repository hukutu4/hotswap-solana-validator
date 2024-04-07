#!/bin/bash
# # #   Stop Voting   # # # # # # # # # # # # # # # # # # # # #
source ./env_loader.sh

solana-keygen new -s --force --no-bip39-passphrase -o $UNSTAKED_IDENTITY_FILE

ln -sf $UNSTAKED_IDENTITY_FILE $IDENTITY_LINK_FILE

command_output=$(solana-validator -l $SOLANA_LEDGER_PATH set-identity $UNSTAKED_IDENTITY_FILE 2>&1)
command_exit_status=$?
echo $command_output
if [ $command_exit_status -eq 0 ]; then   echo -e "\033[32m set empty identity successful \033[0m"
else                                      echo -e "\033[31m can not set empty identity \033[0m"
fi

echo -e "\033[31m vote OFF\033[0m"
