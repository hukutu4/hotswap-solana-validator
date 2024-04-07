#!/bin/bash
source ./env_loader.sh

send_tg_message() {
  TG_MESSAGE=$1
#  echo "$TG_MESSAGE"

  if [ ! -z "$CHAT_ID" ] && [ "$CHAT_ID" != "-1234567876543" ] && [ ! -z "$API_KEY" ] && [ "$API_KEY" != "12345:AAHt2xxxxxxxxxxxxxxxxxxxxxxxxT2g" ]; then
    curl --get \
     --data-urlencode "chat_id=$CHAT_ID" \
     --data-urlencode "parse_mode=HTML" \
     --data-urlencode "text=$TG_MESSAGE" \
     -s "https://api.telegram.org/bot$API_KEY/sendMessage" \
     -o /dev/null
  fi
}
