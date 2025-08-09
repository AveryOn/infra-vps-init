#!/usr/bin/env bash
set -euo pipefail

# Загрузить NVM окружение, если есть
if [ -s "/root/.nvm/nvm.sh" ]; then
  source /root/.nvm/nvm.sh
fi

TARGET_USER="root"
# ENV_SRC="$(dirname "$0")/.env"
ENV_SRC="${1:-.env}"

# Проверка .env
if [[ ! -f "$ENV_SRC" ]]; then
  echo "❌ Файл .env не найден рядом со скриптом: $ENV_SRC"
  exit 1
fi

# Определяем путь для EnvironmentFile
ENV_DIR="/etc/default"
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  if [[ "${ID_LIKE:-}" =~ (rhel|fedora|centos) || "${ID:-}" =~ (rhel|fedora|centos) ]]; then
    ENV_DIR="/etc/sysconfig"
  fi
fi
ENV_FILE="${ENV_DIR}/myenv"

# Проверка pm2
command -v pm2 >/dev/null || { echo "❌ pm2 не установлен для root"; exit 1; }

# Находим unit-файл
SERVICE_NAME="pm2-${TARGET_USER}.service"
UNIT_FILE="/etc/systemd/system/${SERVICE_NAME}"
[[ -f "$UNIT_FILE" ]] || { echo "❌ systemd unit не найден: $SERVICE_NAME"; exit 1; }

# Копируем .env в глобальный env
echo "-> Пишу глобальный env: ${ENV_FILE}"
install -m 0644 -D "$ENV_SRC" "$ENV_FILE"

# Прописываем EnvironmentFile в unit
if ! grep -qE "^\s*EnvironmentFile=.*myenv" "$UNIT_FILE"; then
  echo "-> Прописываю EnvironmentFile в ${UNIT_FILE}"
  sed -i "/^\[Service\]/a EnvironmentFile=-${ENV_FILE}" "$UNIT_FILE"
fi

# Перезапускаем PM2 сервис
echo "-> Перезапуск PM2 и обновление env"
systemctl daemon-reload
systemctl enable "${SERVICE_NAME}" >/dev/null
systemctl restart "${SERVICE_NAME}"
pm2 reload all --update-env || pm2 resurrect --update-env || true

echo "✅ Готово. Файл env: ${ENV_FILE}, юнит: ${SERVICE_NAME}"
