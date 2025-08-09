#!/usr/bin/env bash
set -e

echo "[*] Проверка конфига nginx..."
nginx -t

echo "[*] Перезагрузка nginx..."
sudo systemctl restart nginx

echo "[✓] Готово"
