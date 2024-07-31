#!/bin/bash

# Запрос адреса кошелька NYM
echo "Введите ваш адрес кошелька NYM:"
read NYM_WALLET

# Обновление системы и установка необходимых пакетов
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl jq

# Определение публичного IP-адреса
SERVER_IP=$(curl -s https://api.ipify.org)

# Скачивание и установка бинарного файла миксноды
curl -LO https://nymtech.net/download/nym-mixnode
chmod +x nym-mixnode
sudo mv nym-mixnode /usr/local/bin/

# Инициализация ноды
nym-mixnode init --id my-mixnode --host $SERVER_IP --wallet-address $NYM_WALLET

# Создание и активация системного сервиса
echo "[Unit]
Description=Nym Mixnode

[Service]
User=$USER
ExecStart=/usr/local/bin/nym-mixnode run --id my-mixnode
Restart=on-failure

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/nym-mixnode.service

sudo systemctl daemon-reload
sudo systemctl enable nym-mixnode
sudo systemctl start nym-mixnode

echo "Установка завершена. Проверьте статус ноды командой: systemctl status nym-mixnode"