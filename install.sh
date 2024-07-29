#!/bin/bash
exists()
{
  command -v "$1" >/dev/null 2>&1
}
if exists curl; then
echo ''
else
  sudo apt update && sudo apt install curl -y < "/dev/null"
fi
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi
sleep 1 && curl -s https://api.nodes.guru/logo.sh | bash && sleep 1

if [ ! $node_id ]; then
read -p "Enter node name: " node_id
echo 'export node_id='\"${node_id}\" >> $HOME/.bash_profile
fi
echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
. $HOME/.bash_profile
echo 'Your node name: ' $node_id

sudo apt update < "/dev/null"

sleep 1

sudo dpkg --configure -a
sudo apt install ufw make clang pkg-config libssl-dev build-essential git -y -qq < "/dev/null"
sudo curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env
rustup update
cd $HOME
rm -rf nym
git clone https://github.com/nymtech/nym.git
cd nym
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/nymtech/nym/releases" | grep '"tag_name": "nym-binaries' | awk -F '"' {'print $4'} | head -1)
git checkout $LATEST_RELEASE
cargo build --release --bin nym-mixnode
sudo mv target/release/nym-mixnode /usr/local/bin/
#nym-mixnode init --id $node_id --host $(curl ifconfig.me) --wallet-address $wallet
nym-mixnode init --id $node_id --host $(curl ipinfo.io/ip)
sudo ufw allow 1789,1790,8000,22,80,443/tcp
#sed -i.def "s|validator_api_urls.*|validator_api_urls = [\
#	'https://validator.nymtech.net/api/'|" $HOME/.nym/mixnodes/*/config/config.toml
sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF
sudo systemctl restart systemd-journald
sudo tee <<EOF >/dev/null /etc/systemd/system/nym-mixnode.service
[Unit]
Description=Nym Mixnode

[Service]
User=$USER
ExecStart=/usr/local/bin/nym-mixnode run --id '$node_id'
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
sudo systemctl enable nym-mixnode
sudo systemctl restart nym-mixnode
echo -e '\n\e[42mCheck node status\e[0m\n' && sleep 1
if [[ service nym-mixnode status | grep active =~ "running" ]]; then
  echo -e "Your Nym node \e[32minstalled and works\e[39m!"
  echo -e "You can check node status by the command \e[7mservice nym-mixnode status\e[0m"
  echo -e "Press \e[7mQ\e[0m for exit from status menu"
else
  echo -e "Your Nym node \e[31mwas not installed correctly\e[39m, please reinstall."
fi
