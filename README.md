# INFRA VPS INIT

Базовая настройка VPS-сервера (Ubuntu/Debian).  
Цель — запуск приложений с проксированием через NGINX по доменам.
Подключение SSL. Гибкая настройка

---

## Step 1:
> выполнить:
```bash
 apt update && apt install -y git
 mkdir -p ~/services
 cd ~/services
 git clone https://github.com/AveryOn/infra-vps-init
 cd ~/services/infra-vps-init/
```

---

## Step 2:
> Запустить ./setup.sh

---

## Step 3:
 > Выполнить:
 ```bash
 cp ~/services/infra-vps-init/.env.example ~/services/infra-vps-init/.env
 ```

---

## Step 4:
 > Открыть через nano новый файл .env чтобы заполнить переменные:
 ```bash
nano ~/services/infra-vps-init/.env
 ```

 * После внесенный правок сохранить `Ctrl + O` -> `Ctrl + X`

---

## Step 5 - Работа со скриптом [`load-global-env`](./load-global-env.sh):
 Это скрипт для предварительной загрузки всех env переменных в файл `/etc/default/myenv`.
 Переменные читает из файла `.env` в той директории откуда вызывается скрипт:

  * Использование:
  
   1. Заполни `.env` файл в текущей директории откуда будешь вызывать [`load-global-env`](./load-global-env.sh). _(либо нужно знать путь до уже существующего .env)_
   
   2. Запусти:
```bash
sudo bash ~/services/infra-vps-init/load-global-env.sh
```

Либо явно передаем путь первым аргументом:

```bash
sudo bash ~/services/infra-vps-init/load-global-env.sh /path/to/other.env
```

---

## Step 6 - Стянуть и настроить deployments сервис:
```bash
git clone https://github.com/AveryOn/vps-api-handler ~/services/deployments/
cd ~/services/deployments/ && npm i
npm run build
```

* Добавить под него отдельный домен через nginx:
```bash
sudo cp ~/services/infra-vps-init/nginx_templates/deployments.conf /etc/nginx/conf.d/
```

* !!! Перед дальнейшими махинациями убедись что в провайдере твоего домена есть A запись с * -> 123.1.2.3 (your_ip)

* Выписать сертификаты под этот сервис чтобы получать доступ через https по url:
```bash
sudo systemctl stop nginx
export $(grep -v '^#' /etc/default/myenv | xargs) \
&& sudo certbot certonly --standalone -d "${DEPLOYMENTS_SUBDOMAIN}.${SERVER_NAME_BASE}"
sudo systemctl start nginx
```

* Сгенерировать nginx конфиг с подставленными env переменными для deployments.conf:
```bash
sudo bash ~/services/infra-vps-init/nginx-env-render.sh
```

* Запустить сервис deployments:
```bash
cd ~/services/deployments/
mkdir -p ~/services/deployments/dist/tmp
export $(grep -v '^#' /etc/default/myenv | xargs)
envsubst < ~/services/deployments/dist/deploy/production.env > ~/services/deployments/dist/tmp/production.resolved.env
set -o allexport
. ~/services/deployments/dist/tmp/production.resolved.env
set +o allexport
rm -rf ~/services/deployments/dist/tmp/production.resolved.env
npm run pm2:start
```

---



# Как работать с подстановкой ENV переменных в NGINX-конфиги:

### 1. Работа со скриптом [`load-global-env`](./load-global-env.sh):

 Это скрипт для предварительной загрузки всех env переменных в файл `/etc/default/myenv`.
 Переменные читает из файла `.env` в той директории откуда вызывается скрипт:

  * Использование:
  
   1. Заполни `.env` файл в текущей директории откуда будешь вызывать [`load-global-env`](./load-global-env.sh). _(либо нужно знать путь до уже существующего .env)_
   
   2. Запусти:
```bash
sudo bash load-global-env.sh
```

Либо явно передаем путь первым аргументом:

```bash
sudo bash load-global-env.sh /path/to/other.env
```


### 2. Работа со скриптом [`nginx-env-render.sh`](./nginx-env-render.sh):

 — утилита для автоматической подстановки значений переменных из `/etc/default/myenv` в конфиги Nginx и их перезагрузки.

 Как работает:
 * Ищет во всех `.conf` плейсхолдеры вида `${VAR}`.
 * При первом запуске сохраняет оригинал с плейсхолдерами в `.bak`.
 * При каждом запуске берёт `.bak` как шаблон, подставляет новые значения из `/etc/default/myenv`, перезаписывает `.conf` и выполняет nginx reload.
 * Можно менять .env сколько угодно раз — плейсхолдеры не теряются.
 
 * Использование:
 
  1. Выполни скрипт [`load-global-env`](./load-global-env.sh)
  
  2. В конфиг Nginx вставь плейсхолдеры ${VAR} вместо значений, которые хочешь менять.

  3. Запусти:
   ```bash
   sudo nginx-env-render.sh             # возьмёт /etc/default/myenv по умолчанию
   ```

  4. Скрипт обновит конфиги и перезагрузит Nginx.
 
---
 
# Как вручную перезагружать службу NGINX:

 Для этого есть утилита - [`restart-nginx`](./restart-nginx.sh)
 чтобы ее использовать, нужно сделать скрипт исполняемым и вызывать его где угодно в терминале как `restart-nginx`

 * TODO: внедрить создание скрипта в setup стадию