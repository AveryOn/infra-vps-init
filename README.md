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

   sudo nginx -t

6. Получить SSL-сертификат (если не получен):

   sudo apt install -y certbot python3-certbot-nginx
   sudo certbot --nginx -d your-domain.com

7. Перезагрузить nginx:

   sudo systemctl reload nginx

8. Убедиться, что работает:

   curl -I https://your-domain.com
