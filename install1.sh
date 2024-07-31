#!/bin/bash

# Уникальный идентификатор узла (замените "Unicombase" на ваш идентификатор)
node_id="Unicombase"

# Проверка и установка необходимых инструментов
exists() {
  command -v "$1" >/dev/null 2>&1
}

if ! exists curl; then
  sudo apt update && sudo apt install curl -y < "/dev/null"
fi

# Определение пути к .bash_profile и его загрузка, если файл существует
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi

# Загрузка профиля bash
echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
. $HOME/.bash_profile

# Обновление системы и установка необходимых пакетов
sudo apt update < "/dev/null"
sudo apt install ufw make clang pkg-config libssl-dev build-essential git -y -qq < "/dev/null"

# Установка Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
rustup update

# Клонирование репозитория Nym и компиляция узла
cd $HOME
rm -rf nym
git clone https://github.com/nymtech/nym.git
cd nym
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/nymtech/nym/releases/latest" | grep '"tag_name":' | awk -F '"' '{print $4}')
git checkout $LATEST_RELEASE
cargo build --release --bin nym-node
sudo mv target/release/nym-node /usr/local/bin/

# Получение публичного IP-адреса
public_ip=$(curl -s ipinfo.io/ip)

# Создание папки конфигурации и файла config.toml
mkdir -p /root/.nym/nym-nodes/$node_id/config
cat <<EOL > /root/.nym/nym-nodes/$node_id/config/config.toml
id = "$node_id"

[host]
public_ips = ["$public_ip"]

[logging]
level = "info"

[mixnet]
port = 1789

[storage_paths]
database_path = "/root/.nym/nym-nodes/$node_id/data/db.sqlite"
EOL

# Настройка брандмауэра
sudo ufw allow 1789,1790,8000,22,80,443/tcp

# Настройка systemd для узла Nym
sudo tee /etc/systemd/system/nym-node.service <<EOF >/dev/null
[Unit]
Description=Nym Node

[Service]
User=$USER
ExecStart=/usr/local/bin/nym-node run --id '$node_id' --hostname '$public_ip' --accept-operator-terms-and-conditions
KillSignal=SIGINT
Restart=on-failure
RestartSec=30
StartLimitInterval=350
StartLimitBurst=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sudo echo "DefaultLimitNOFILE=65535" >> /etc/systemd/system.conf
sudo systemctl daemon-reload
sudo systemctl enable nym-node
sudo systemctl start nym-node

# Проверка статуса узла
echo -e '\n\e[42mПроверка состояния узла\e[0m\n' && sleep 1
if systemctl is-active --quiet nym-node; then
  echo -e "Ваш узел Nym \e[32mустановлен и работает\e[39m!"
  echo -e "Вы можете проверить состояние узла с помощью команды \e[7msystemctl status nym-node\e[0m"
  echo -e "Нажмите \e[7mQ\e[0m для выхода из меню состояния"
else
  echo -e "Ваш узел Nym \e[31mне был установлен корректно\e[39m, пожалуйста, проверьте конфигурацию."
fi