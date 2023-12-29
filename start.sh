#!/bin/bash

# Variables
if [ -z "$NC_DOMAINS" ]; then
    echo "You need to provide the NC_DOMAINS."
    exit 1
elif [ -z "$TALK_PORT" ]; then
    echo "You need to provide the TALK_PORT."
    exit 1
elif [ -z "$TURN_SECRET" ]; then
    echo "You need to provide the TURN_SECRET."
    exit 1
elif [ -z "$SIGNALING_SECRETS" ]; then
    echo "You need to provide the SIGNALING_SECRETS."
    exit 1
elif [ -z "$INTERNAL_SECRET" ]; then
    echo "You need to provide the INTERNAL_SECRET."
    exit 1
elif [ -z "$BACKENDS" ]; then
    echo "You need to provide the BACKENDS."
    exit 1
fi

set -x
IPv4_ADDRESS_TALK_RELAY="$(hostname -i | grep -oP '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
IPv4_ADDRESS_TALK="$(dig nextcloud-aio-talk IN A +short +search | grep '^[0-9.]\+$' | sort | head -n1)"
IPv6_ADDRESS_TALK="$(dig nextcloud-aio-talk AAAA +short +search | grep '^[0-9a-f:]\+$' | sort | head -n1)"
set +x

if [ -n "$IPv4_ADDRESS_TALK" ] && [ "$IPv4_ADDRESS_TALK_RELAY" = "$IPv4_ADDRESS_TALK" ]; then
    IPv4_ADDRESS_TALK=""
fi

# Turn
cat << TURN_CONF > "/conf/eturnal.yml"
eturnal:
  listen:
    - ip: "::"
      port: $TALK_PORT
      transport: udp
    - ip: "::"
      port: $TALK_PORT
      transport: tcp
  log_dir: stdout
  log_level: warning
  secret: "$TURN_SECRET"
  relay_ipv4_addr: "$IPv4_ADDRESS_TALK_RELAY"
  relay_ipv6_addr: "$IPv6_ADDRESS_TALK"
  blacklist_peers:
  - recommended
  whitelist_peers:
  - 127.0.0.1
  - ::1
  - "$IPv4_ADDRESS_TALK_RELAY"
  - "$IPv4_ADDRESS_TALK"
  - "$IPv6_ADDRESS_TALK"
TURN_CONF

# Remove empty lines so that the config is not invalid
sed -i '/""/d' /conf/eturnal.yml

IFS=',' read -r -a BACKENDS_IN <<< "$BACKENDS"
IFS=',' read -r -a URLS <<< "$NC_DOMAINS"
IFS=',' read -r -a SECRETS <<< "$SIGNALING_SECRETS"

index=0
BACKEND_FORMAT=""

for BACKEND in "${BACKENDS_IN[@]}"; do
  BACKEND_FORMAT+="[$BACKEND]\n"
  BACKEND_FORMAT+="url = ${URLS[$index]}\n"
  BACKEND_FORMAT+="secret = ${SECRETS[$index]}\n"
  index=$((index + 1))
done

# Signling
cat << SIGNALING_CONF > "/conf/signaling.conf"
[http]
listen = 0.0.0.0:8081

[app]
debug = false

[sessions]
hashkey = $(openssl rand -hex 16)
blockkey = $(openssl rand -hex 16)

[clients]
internalsecret = ${INTERNAL_SECRET}

[backend]
backends = ${BACKENDS}
allowall = false
timeout = 10
connectionsperhost = 8

${BACKEND_FORMAT}

[nats]
url = nats://127.0.0.1:4222

[mcu]
type = janus
url = ws://127.0.0.1:8188
SIGNALING_CONF

exec "$@"