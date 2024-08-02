#!/bin/bash

# Запрос ID для миксноды
echo "Введите ID для миксноды:"
read NODE_ID

# Проверка текущей версии
CURRENT_VERSION=$(nym-node --version)
echo "Текущая версия: $CURRENT_VERSION"

# Скачивание последней версии бинарника
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/nymtech/nym/releases/latest" | grep '"tag_name":' | awk -F '"' '{print $4}')
wget https://github.com/nymtech/nym/releases/download/$LATEST_RELEASE/nym-node -O nym-node-latest

# Выдаем права на исполнение
chmod +x nym-node-latest

# Проверка версии нового бинарника
NEW_VERSION=$(./nym-node-latest --version)
echo "Новая версия: $NEW_VERSION"

# Остановка текущей ноды
sudo systemctl stop nym-node

# Замена бинарника
sudo cp -i ./nym-node-latest /usr/local/bin/nym-node

# Удаление временного бинарника
rm ./nym-node-latest

# Запуск ноды
sudo systemctl start nym-node

# Проверка статуса ноды
sudo systemctl status nym-node

# Проверка логов ноды
journalctl -u nym-node -f