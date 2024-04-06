#!/bin/bash
#set -x  # Uncomment for debug mode

# Function for loading .env file
load_env() {
  while read -r line; do
    # Skip empty lines and lines starting with #
    if [[ "$line" = \#* ]] || [ -z "$line" ]; then
  	continue
    fi
    export "$line"
  done < .env
}

load_env  # Invoke the function to load the variables

send_tg_message() {
  TG_MESSAGE=$1
  echo "$TG_MESSAGE"
  curl --get \
   --data-urlencode "chat_id=$CHAT_ID" \
   --data-urlencode "parse_mode=HTML" \
   --data-urlencode "text=$TG_MESSAGE" \
   -s "https://api.telegram.org/bot$API_KEY/sendMessage" \
   -o /dev/null
}
