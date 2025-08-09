# INFRA VPS INIT

Базовая настройка VPS-сервера (Ubuntu/Debian).  
Цель — запуск приложений с проксированием через NGINX по доменам.
Подключение SSL. Гибкая настройка

---

## Step 1:
> Запустить ./setup.sh

# Установка и настройка nginx конфига для Node.js с HTTPS

1. Установить nginx (если не установлен):

   sudo apt update
   sudo apt install -y nginx

2. Проверить, что nginx работает:

   sudo systemctl status nginx

3. Убедиться, что домен указывает на сервер (A-запись DNS)

4. Создать конфигурационный файл для домена:

   sudo nano /etc/nginx/conf.d/your-domain.conf

   Пример содержимого:

   ---
   server {
       listen 80;
       server_name your-domain.com;

       return 301 https://$host$request_uri;
   }

   server {
       listen 443 ssl;
       server_name your-domain.com;

       ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
       ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

       ssl_protocols TLSv1.2 TLSv1.3;
       ssl_ciphers HIGH:!aNULL:!MD5;

       location / {
           proxy_pass http://127.0.0.1:3000;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
       }
   }
   ---

5. Проверить корректность конфигурации:

    ```
    sudo nginx -t
    ```

6. Получить SSL-сертификат (если не получен):

    ```
   sudo apt install -y certbot python3-certbot-nginx
   sudo certbot --nginx -d your-domain.com
   ```

7. Перезагрузить nginx:

    ```
   sudo systemctl reload nginx
    ```

8. Убедиться, что работает:

    ```
   curl -I https://your-domain.com
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
   sudo ./nginx-env-render.sh             # возьмёт /etc/default/myenv по умолчанию
   ```

  4. Скрипт обновит конфиги и перезагрузит Nginx.
 
---

# Как вручную перезагружать службу NGINX:

 Для этого есть уталита - [`restart-nginx`](./restart-nginx.sh)
 чтобы ее использовать, нужно сделать скрипт исполняемым и вызывать его где угодно в терминале как `restart-nginx`

 * TODO: внедрить создание скрипта в setup стадию