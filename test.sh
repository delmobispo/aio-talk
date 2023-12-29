#!/bin/bash

BACKENDS=delmo,victor,wenisson
URLS=https://intranet.paqti.com.br,http://intranet.nutrip.com.br,https://intranet.nefrostar.com.br
SECRETS=1112,22234,44555

IFS=',' read -r -a BACKENDS <<< "$BACKENDS"
IFS=',' read -r -a URLS <<< "$URLS"
IFS=',' read -r -a SECRETS <<< "$SECRETS"

index=0
BACKEND_FORMAT=""

for BACKEND in "${BACKENDS[@]}"; do
  BACKEND_FORMAT+="[$BACKEND]\n"
  BACKEND_FORMAT+="url = ${URLS[$index]}\n"
  BACKEND_FORMAT+="secret = ${SECRETS[$index]}\n"
  index=$((index + 1))
done

echo $BACKEND_FORMAT