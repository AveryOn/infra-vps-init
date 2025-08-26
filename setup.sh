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
apt install -y docker.io docker-compose-plugin

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

npm install -g pm2

# Установка nginx и certbot
apt install -y nginx certbot python3-certbot-nginx

echo "[*] starting interactive installer..."
# node installer/index.js
