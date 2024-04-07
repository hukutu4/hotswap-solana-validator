#!/bin/bash
#set -x  # Uncomment for debug mode
source ~/.profile

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
