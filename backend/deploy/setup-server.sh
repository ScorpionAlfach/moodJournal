#!/bin/bash
# ============================================================
# Скрипт установки MoodJournal Backend на Ubuntu 22.04
# Запускать от root: bash setup-server.sh
# ============================================================

set -e

echo "=== 1/7 Обновление системы ==="
apt update && apt upgrade -y

echo "=== 2/7 Установка Node.js 20 ==="
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs
echo "Node.js: $(node -v)"
echo "npm: $(npm -v)"

echo "=== 3/7 Установка MongoDB 7 ==="
apt install -y gnupg curl
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
apt update
apt install -y mongodb-org
systemctl start mongod
systemctl enable mongod
echo "MongoDB: $(mongod --version | head -1)"

echo "=== 4/7 Установка nginx ==="
apt install -y nginx
systemctl enable nginx

echo "=== 5/7 Установка PM2 ==="
npm install -g pm2

echo "=== 6/7 Установка Certbot (Let's Encrypt) ==="
apt install -y certbot python3-certbot-nginx

echo "=== 7/7 Создание директории проекта ==="
mkdir -p /var/www/mood-journal
mkdir -p /var/www/certbot

echo ""
echo "============================================"
echo "  Установка завершена!"
echo "============================================"
echo ""
echo "Следующие шаги:"
echo "1. Скопируйте backend на сервер:"
echo "   scp -r backend/ root@193.187.94.244:/var/www/mood-journal/"
echo ""
echo "2. На сервере:"
echo "   cd /var/www/mood-journal/backend"
echo "   npm install --production"
echo "   cp deploy/.env.production .env"
echo "   # Отредактируйте .env (JWT_SECRET, SMTP)"
echo "   nano .env"
echo ""
echo "3. Настройте nginx:"
echo "   cp deploy/nginx.conf /etc/nginx/sites-available/moodjournal"
echo "   ln -s /etc/nginx/sites-available/moodjournal /etc/nginx/sites-enabled/"
echo "   rm -f /etc/nginx/sites-enabled/default"
echo "   nginx -t && systemctl reload nginx"
echo ""
echo "4. Получите SSL-сертификат:"
echo "   certbot --nginx -d moodjournal.ru -d www.moodjournal.ru"
echo ""
echo "5. Запустите приложение:"
echo "   cd /var/www/mood-journal/backend"
echo "   pm2 start deploy/ecosystem.config.js"
echo "   pm2 save"
echo "   pm2 startup"
echo ""
