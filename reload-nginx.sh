#!/usr/bin/env bash
set -e

echo "[*] Проверка конфига nginx..."
nginx -t

echo "[*] Перезагрузка nginx..."
systemctl reload nginx

echo "[✓] Готово"
