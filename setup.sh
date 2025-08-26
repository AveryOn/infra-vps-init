#!/bin/bash
set -e

echo "[*] checking for sudo..."
if [ "$EUID" -ne 0 ]; then
  echo "[-] please run as root"
  exit 1
fi

echo "[*] installing dependencies..."

# Проверка и установка curl
if ! command -v curl &> /dev/null; then
  apt update && apt install -y curl
fi

# Docker и docker compose
# Установка Docker CE и compose plugin
apt update
apt install -y ca-certificates curl gnupg lsb-release

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin


# Установка NVM + Node.js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

nvm install --lts
nvm use --lts

node -v
npm -v

# Установка pm2
npm install -g pm2
TARGET_USER=$(whoami)
pm2 startup systemd -u $TARGET_USER --hp /home/$TARGET_USER
pm2 save
systemctl enable pm2-$TARGET_USER
systemctl start pm2-$TARGET_USER


# Установка nginx и certbot
apt install -y nginx certbot python3-certbot-nginx

echo "[*] starting interactive installer..."
# node installer/index.js
