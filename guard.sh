#!/bin/bash
source ./env_loader.sh

PUB_KEY=$(solana-keygen pubkey $VALIDATOR_IDENTITY)
rpcURL=$(solana config get | grep "RPC URL" | awk '{print $3}')
CUR_IP=$(wget -q -4 -O- http://icanhazip.com)
SITES=("www.google.com" "www.bing.com")
TG_PREFIX="<code>guard.sh</code> - current IP=<code>$CUR_IP</code> - <code>$PUB_KEY</code>: "

########################################
pushd `dirname ${0}` > /dev/null 2>&1
source ./telegram-sender.sh > /dev/null 2>&1

if [ ! -f "$UNSTAKED_IDENTITY_FILE" ]; then
  solana-keygen new -s --force --no-bip39-passphrase -o $UNSTAKED_IDENTITY_FILE
fi

DISCONNECT_COUNTER=0
echo ' == SOLANA GUARD =='
CHECK_CONNECTION() { # every $INTERVAL_CHECK_SECONDS seconds
    connection=false
    sleep $INTERVAL_CHECK_SECONDS
    for site in "${SITES[@]}"; do
        ping -c1 $site &> /dev/null # ping every site once
        if [ $? -eq 0 ]; then
            connection=true # good connection
            echo -ne "\033[32m check server connection $(TZ=Europe/Moscow date +"%H:%M:%S") MSK \r \033[0m"
            break
        fi
    done

    # connection losses counter
    if [ "$connection" = false ]; then
        let DISCONNECT_COUNTER=DISCONNECT_COUNTER+1
        echo "connection failed, attempt "$DISCONNECT_COUNTER
		send_tg_message "$TG_PREFIX connection failed, attempt $DISCONNECT_COUNTER $TG_HANDLES"
    else
	    if [ $DISCONNECT_COUNTER -ge 1 ]; then
		    send_tg_message "$TG_PREFIX connection succeed $TG_HANDLES"
	    fi
        DISCONNECT_COUNTER=0
    fi

    # connection loss for 30 seconds (5sec * 6)
    if [ $DISCONNECT_COUNTER -ge $CONNECTION_CHECK_ATTEMPTS ]; then
        echo "CONNECTION LOSS"
		send_tg_message "$TG_PREFIX CONNECTION LOSS $TG_HANDLES"
        bash "$CONNECTION_LOSS_SCRIPT"
        sudo systemctl restart $SOLANA_SERVICE && echo -e "\033[31m restart solana \033[0m" && send_tg_message "$TG_PREFIX restart solana $TG_HANDLES"
    fi
}


SERV=$1
if [ -z "$SERV" ]; then
  SERV=$SOL_USER'@'$(solana gossip | grep $PUB_KEY | awk '{print $1}')
fi
IP=$(echo "$SERV" | cut -d'@' -f2) # cut IP from $SOL_USER@IP
echo 'PUB_KEY: '$PUB_KEY
echo 'voting IP='$IP
echo 'current IP='$CUR_IP
if [ "$CUR_IP" == "$IP" ]; then
  echo -e "\n solana voting on current PRIMARY SERVER"
  send_tg_message "$TG_PREFIX solana voting on current PRIMARY SERVER"
  # CHECK_CONNECTION_LOOP 
  until [ $DISCONNECT_COUNTER -ge $CONNECTION_CHECK_ATTEMPTS ]; do
    CHECK_CONNECTION
  done
  exit
fi

echo -e "\n = SECONDARY SERVER ="
send_tg_message "$TG_PREFIX SECONDARY SERVER"
# you won’t need to enter your passphrase every time.
chmod 600 $IDENTITY_FILE_PATH
eval "$(ssh-agent -s)"  # Start ssh-agent in the background
ssh-add $IDENTITY_FILE_PATH # Add SSH private key to the ssh-agent

# create ssh alias for remote server
echo " 
Host REMOTE
HostName $IP
User $SOL_USER
Port $SSH_REMOTE_PORT
IdentityFile $IDENTITY_FILE_PATH
" > ~/.ssh/config

# check SSH connection
ssh REMOTE 'echo "SSH connection succesful" > ~/check_ssh'
scp -P $SSH_REMOTE_PORT -i $IDENTITY_FILE_PATH $SERV:~/check_ssh ~/
ssh REMOTE rm ~/check_ssh
echo -e "\033[32m$(cat ~/check_ssh)\033[0m"
send_tg_message "$TG_PREFIX$(cat ~/check_ssh)"
rm ~/check_ssh

echo "  Start monitoring $(TZ=Europe/Moscow date +"%Y-%m-%d %H:%M:%S") MSK"

# waiting remote server fail
Delinquent=false

until [[ $DISCONNECT_COUNTER -ge $DELINQUENT_CHECK_ATTEMPTS ]]; do
	JSON=$(solana validators --url $rpcURL --output json-compact 2>/dev/null | jq '.validators[] | select(.identityPubkey == "'"${PUB_KEY}"'" )')
	LastVote=$(echo "$JSON" | jq -r '.lastVote')
	Delinquent=$(echo "$JSON" | jq -r '.delinquent')
	echo -ne "Looking for $PUB_KEY. LastVote=$LastVote $(TZ=Europe/Moscow date +"%H:%M:%S") MSK \r"

    if [[ $Delinquent == true ]]; then
        let DISCONNECT_COUNTER=DISCONNECT_COUNTER+1
        echo "REMOTE server is delinquent, attempt "$DISCONNECT_COUNTER
		send_tg_message "$TG_PREFIX REMOTE server is delinquent, attempt , attempt $DISCONNECT_COUNTER $TG_HANDLES"
    else
	    if [ $DISCONNECT_COUNTER -ge 1 ]; then
		    send_tg_message "$TG_PREFIX connection succeed $TG_HANDLES"
	    fi
        DISCONNECT_COUNTER=0
    fi
    sleep $INTERVAL_CHECK_SECONDS
done

echo -e "\033[31m  REMOTE server fail at $(TZ=Europe/Moscow date +"%Y-%m-%d %H:%M:%S") MSK \033[0m"
send_tg_message "$TG_PREFIX REMOTE server fail at $(TZ=Europe/Moscow date +"%Y-%m-%d %H:%M:%S") MSK $TG_HANDLES"

# STOP SOLANA on REMOTE server
echo "  change validator link on REMOTE server "  
ssh REMOTE ln -sf $UNSTAKED_IDENTITY_FILE $IDENTITY_LINK_FILE
command_output=$(ssh REMOTE $SOL/solana-validator -l $SOLANA_LEDGER_PATH set-identity $UNSTAKED_IDENTITY_FILE 2>&1)
command_exit_status=$?
echo "  try to set unstaked identity on REMOTE server: $command_output" 
if [ $command_exit_status -eq 0 ]; then
   echo -e "\033[32m  set unstaked identity on REMOTE server successful \033[0m" 
else
  echo -e "\033[31m  restart solana on REMOTE server in NO_VOTING mode \033[0m"
  ssh REMOTE sudo systemctl restart $SOLANA_SERVICE
fi
echo "  move tower from REMOTE to LOCAL "
scp -P $SSH_REMOTE_PORT -i $IDENTITY_FILE_PATH $SERV:$SOLANA_LEDGER_PATH/tower-1_9-$PUB_KEY.bin $SOLANA_LEDGER_PATH

# START SOLANA on LOCAL server
if [ -f $SOLANA_LEDGER_PATH/tower-1_9-$PUB_KEY.bin ]; then 
  TOWER_STATUS=' with existing tower'
  solana-validator -l $SOLANA_LEDGER_PATH set-identity --require-tower $VALIDATOR_IDENTITY; 
else
  TOWER_STATUS=' without tower'
  solana-validator -l $SOLANA_LEDGER_PATH set-identity $VALIDATOR_IDENTITY;
fi
ln -sfn $VALIDATOR_IDENTITY $IDENTITY_LINK_FILE

echo -e "\033[31m vote ON\033[0m"$TOWER_STATUS
send_tg_message "$TG_PREFIX vote ON $TOWER_STATUS $TG_HANDLES"

solana-validator --ledger $SOLANA_LEDGER_PATH monitor
