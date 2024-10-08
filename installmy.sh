#!/bin/bash

# Запрос ID для миксноды
echo "Введите ID для миксноды:"
read NODE_ID

# Обновление системы и установка необходимых пакетов
sudo apt update < "/dev/null"
sudo dpkg --configure -a
sudo apt install ufw make clang pkg-config libssl-dev build-essential git -y -qq < "/dev/null"

# Установка Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
rustup update

# Клонирование репозитория Nym и компиляция
cd $HOME
rm -rf nym
git clone https://github.com/nymtech/nym.git
cd nym
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/nymtech/nym/releases/latest" | grep '"tag_name":' | awk -F '"' '{print $4}')
git checkout $LATEST_RELEASE
cargo build --release --bin nym-node
sudo mv target/release/nym-node /usr/local/bin/

# Открытие необходимых портов
sudo ufw allow 1789/tcp
sudo ufw allow 1790/tcp
sudo ufw allow 8080/tcp
sudo ufw allow 8000/tcp
sudo ufw allow 22/tcp
sudo ufw enable

nym-node run --id $NODE_ID --init-only --mode mixnode --verloc-bind-address 0.0.0.0:1790 --public-ips "$(curl -4 https://ifconfig.me)" --accept-operator-terms-and-conditions

echo "[Unit]
Description=Nym Node
StartLimitInterval=350
StartLimitBurst=10

[Service]
User=root
LimitNOFILE=65536
ExecStart=/usr/local/bin/nym-node run --id $NODE_ID --deny-init --mode mixnode --accept-operator-terms-and-conditions
KillSignal=SIGINT
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/nym-node.service

systemctl enable nym-node
systemctl start nym-node && journalctl -u nym-node -f