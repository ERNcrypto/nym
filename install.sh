# Функция для проверки существования команды
exists()
{
  command -v "$1" >/dev/null 2>&1
}

# Проверка, установлен ли curl, и его установка, если он отсутствует
if exists curl; then
echo ''
else
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
if [ ! $node_id ]; then
read -p "Введите имя узла: " node_id
echo 'export node_id='\"${node_id}\" >> $HOME/.bash_profile
fi

# Добавление source .bashrc в .bash_profile и его загрузка
echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
. $HOME/.bash_profile
echo 'Имя вашего узла: ' $node_id

# Обновление системы
sudo apt update < "/dev/null"

# Пауза и установка необходимых пакетов
sleep 1
sudo dpkg --configure -a
sudo apt install ufw make clang pkg-config libssl-dev build-essential git -y -qq < "/dev/null"

# Установка Rust
sudo curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env
rustup update

# Клонирование репозитория Nym и компиляция
cd $HOME
rm -rf nym
git clone https://github.com/nymtech/nym.git
cd nym
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/nymtech/nym/releases" | grep '"tag_name":' | awk -F '"' {'print $4'} | head -1)
git checkout $LATEST_RELEASE
cargo build --release --bin nym-node
sudo mv target/release/nym-node /usr/local/bin/

# Инициализация узла Nym с использованием nym-node и настройка брандмауэра
nym-node init --id $node_id
sudo ufw allow 1789,1790,8000,22,80,443/tcp

# Настройка хранения логов в systemd и перезагрузка systemd-journald
sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF
sudo systemctl restart systemd-journald

# Создание и настройка сервиса systemd для управления узлом Nym
sudo tee <<EOF >/dev/null /etc/systemd/system/nym-node.service
[Unit]
Description=Nym Node

[Service]
User=$USER
ExecStart=/usr/local/bin/nym-node run --id '$node_id'
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
sudo systemctl restart nym-node

# Проверка статуса узла и вывод информации о состоянии установки
echo -e '\n\e[42mПроверка состояния узла\e[0m\n' && sleep 1
if service nym-node status | grep -q "active (running)"; then
  echo -e "Ваш узел Nym \e[32mустановлен и работает\e[39m!"
  echo -e "Вы можете проверить состояние узла с помощью команды \e[7mservice nym-node status\e[0m"
  echo -e "Нажмите \e[7mQ\e[0m для выхода из меню состояния"
else
  echo -e "Ваш узел Nym \e[31mне был установлен корректно\e[39m, пожалуйста, переустановите."
fi
