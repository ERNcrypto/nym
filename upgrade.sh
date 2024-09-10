#!/bin/bash

cd

wget https://github.com/nymtech/nym/releases/download/nym-binaries-v2024.10-caramello/nym-node

chmod +x nym-node

service nym-node stop

cp -i ./nym-node /usr/local/bin 

y

rm ./nym-node

service nym-node start

journalctl -u nym-node -f