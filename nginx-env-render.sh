#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${1:-/etc/nginx/.env}"
DIRS=("/etc/nginx/sites-available" "/etc/nginx/conf.d")

# envsubst нужен
command -v envsubst >/dev/null || { echo "installing gettext-base..."; apt-get update && apt-get install -y gettext-base; }

# грузим env
[ -f "$ENV_FILE" ] || { echo "No env file: $ENV_FILE"; exit 1; }
set -a; . "$ENV_FILE"; set +a

# список VAR для замены, ограничим только теми, что в env
VARS="$(grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "$ENV_FILE" | cut -d= -f1 | sed -E 's/^/\${/; s/$/}/' | tr '\n' ' ')"

changed=0
for d in "${DIRS[@]}"; do
  [ -d "$d" ] || continue
  while IFS= read -r -d '' conf; do
    bak="${conf}.bak"

    # если .bak ещё нет, но в файле есть плейсхолдеры — создаём .bak из текущего
    if [ ! -f "$bak" ]; then
      if grep -q '\${[A-Za-z_][A-Za-z0-9_]*}' "$conf"; then
        cp -a "$conf" "$bak"
        echo "[*] init .bak: $bak"
      else
        # нет плейсхолдеров и бэкапа — нечего рендерить
        continue
      fi
    fi

    tmp="$(mktemp)"
    if [ -n "$VARS" ]; then
      envsubst "$VARS" < "$bak" > "$tmp"
    else
      cp -a "$bak" "$tmp"
    fi

    if ! cmp -s "$conf" "$tmp"; then
      mv "$tmp" "$conf"
      echo "[*] updated: $conf"
      changed=1
    else
      rm -f "$tmp"
    fi
  done < <(find "$d" -type f -name '*.conf' -print0)
done

nginx -t
[ "$changed" -eq 1 ] && { systemctl reload nginx; echo "✔ reloaded"; } || echo "✓ no changes"
