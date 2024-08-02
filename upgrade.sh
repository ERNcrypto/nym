#!/bin/bash

wget https://github.com/nymtech/nym/releases/download/nym-binaries-v2024.8-wispa/nym-node

chmod +x nym-node

service nym-node stop

cp -i ./nym-node /usr/local/bin

rm ./nym-node

service nym-node start

journalctl -u nym-node -f