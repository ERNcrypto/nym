#!/bin/bash

# Функция для проверки существования команды
exists()
{
  command -v "$1" >/dev/null 2>&1
}

# Проверка, установлен ли curl, и его установка, если он отсутствует
if ! exists curl; then
  sudo apt update && sudo apt install curl -y < "/dev/null"
fi

# Определение пути к .bash_profile и его загрузка, если файл существует
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi

# Кратковременная пауза и выполнение скрипта, загружаемого с nodes.guru
sleep 1 && curl -s https://api.nodes.guru/logo.sh | bash && sleep 1

# Проверка, установлен ли node_id; если нет, запрос имени узла у пользователя
if [ -z "$node_id" ]; then
  read -p "Введите имя узла: " node_id
  echo 'export node_id='\"${node_id}\" >> $HOME/.bash_profile
fi

# Загрузка переменных окружения
echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
. $HOME/.bash_profile
echo 'Имя вашего узла: ' $node_id

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

# Получение публичного IP-адреса
public_ip=$(curl -s ipinfo.io/ip)

# Создание папки конфигурации и файла config.toml
mkdir -p /root/.nym/nym-nodes/$node_id/config
cat <<EOL > /root/.nym/nym-nodes/$node_id/config/config.toml
id = "$node_id"
host = "$public_ip"

[mixnet]
port = 1789

[storage_paths]
keys = "/root/.nym/nym-nodes/$node_id/keys"
clients = "/root/.nym/nym-nodes/$node_id/clients"
EOL

# Настройка брандмауэра
sudo ufw allow 1789,1790,8000,22,80,443/tcp

# Настройка хранения логов в systemd и перезагрузка systemd-journald
sudo tee /etc/systemd/journald.conf <<EOF >/dev/null
Storage=persistent
EOF
sudo systemctl restart systemd-journald

# Создание и настройка сервиса systemd для управления узлом Nym
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

# Проверка статуса узла и вывод информации о состоянии установки
echo -e '\n\e[42mПроверка состояния узла\e[0m\n' && sleep 1
if systemctl is-active --quiet nym-node; then
  echo -e "Ваш узел Nym \e[32mустановлен и работает\e[39m!"
  echo -e "Вы можете проверить состояние узла с помощью команды \e[7msystemctl status nym-node\e[0m"
  echo -е "Нажмите \e[7mQ\e[0m для выхода из меню состояния"
else
  echo -е "Ваш узел Nym \e[31mне был установлен корректно\e[39m, пожалуйста, проверьте конфигурацию."
fi