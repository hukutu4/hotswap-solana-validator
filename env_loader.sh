#!/bin/bash
#set -x  # Uncomment for debug mode

# Function for loading .env file
while read -r line; do
  # Skip empty lines and lines starting with #
  if [[ "$line" = \#* ]] || [ -z "$line" ]; then
    continue
  fi
  export "$line"
done < .env
