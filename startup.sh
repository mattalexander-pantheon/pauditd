#!/bin/sh

set -xeou pipefail

PUBLIC_IP=$(jq .public_ip < /etc/pantheon/settings.json)
mkdir -p /config
cp /configmap/pauditd.yaml /config/pauditd.yaml
sed -i -e "s/__PUBLIC_IP__/${PUBLIC_IP}/g" /config/pauditd.yaml

exec /opt/pauditd/pauditd -config /config/pauditd.yaml
