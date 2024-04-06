#!/bin/bash
# # #   Stop Voting   # # # # # # # # # # # # # # # # # # # # #
source $HOME/.profile

solana-keygen new -s --force --no-bip39-passphrase -o $HOME/solana/unstaked-identity.json

ln -sf ~/solana/unstaked-identity.json ~/solana/identity.json

command_output=$(solana-validator -l ~/solana/ledger set-identity ~/solana/unstaked-identity.json 2>&1)
command_exit_status=$?
echo $command_output
if [ $command_exit_status -eq 0 ]; then   echo -e "\033[32m set empty identity successful \033[0m"
else                                      echo -e "\033[31m can not set empty identity \033[0m"
fi

echo -e "\033[31m vote OFF\033[0m"
