#!/bin/bash

cd

wget https://github.com/nymtech/nym/releases/download/nym-binaries-v2024.9-topdeck/nym-node

chmod +x nym-node

service nym-node stop

echo "Y" | cp -i ./nym-node /usr/local/bin 

rm ./nym-node

service nym-node start

journalctl -u nym-node -f