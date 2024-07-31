#!/bin/bash

# Установка уникального идентификатора узла (замените "Unicombase" на ваш идентификатор)
node_id="Unicombase"

# Создание папки конфигурации, если она не существует
mkdir -p /root/.nym/nym-nodes/$node_id/config

# Получение публичного IP-адреса
public_ip=$(curl -s ipinfo.io/ip)

# Создание файла конфигурации с корректными параметрами
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

# Перезапуск службы nym-node
sudo systemctl daemon-reload
sudo systemctl restart nym-node

# Проверка статуса узла и вывод информации о состоянии установки
echo -e '\n\e[42mПроверка состояния узла\e[0m\n' && sleep 1
if systemctl is-active --quiet nym-node; then
  echo -e "Ваш узел Nym \e[32mустановлен и работает\e[39m!"
  echo -e "Вы можете проверить состояние узла с помощью команды \e[7msystemctl status nym-node\e[0m"
  echo -e "Нажмите \e[7mQ\e[0m для выхода из меню состояния"
else
  echo -e "Ваш узел Nym \e[31mне был установлен корректно\e[39m, пожалуйста, переустановите."
fi