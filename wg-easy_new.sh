#!/bin/bash

set -euo pipefail

# Функция для вывода ошибок
error() {
  echo "Ошибка: $1" >&2
  exit 1
}

# Генерация случайного пароля длиной 16 символов или указанной в аргументе
PASSWORD=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c${1:-16})
echo "Сгенерирован пароль: $PASSWORD"

# Обновление пакетов и установка apache2-utils для htpasswd
echo "Обновляем пакеты и устанавливаем apache2-utils..."
sudo apt-get update -y
sudo apt-get install -y apache2-utils

# Проверка наличия утилиты htpasswd
if ! command -v htpasswd &>/dev/null; then
  error "Утилита htpasswd не установлена. Установите apache2-utils."
fi

# Генерация bcrypt-хеша пароля (без имени пользователя)
hash=$(htpasswd -nbBC 10 "" "$PASSWORD" | tr -d ':\n')
echo "Сгенерирован bcrypt-хеш."

# Установка Docker и Docker Compose (если не установлены)
echo "Устанавливаем Docker и Docker Compose..."
sudo apt-get install -y docker.io docker-compose

# Запуск и включение Docker
sudo systemctl enable --now docker

# Проверка версии docker-compose
if ! docker-compose --version &>/dev/null; then
  error "Docker Compose не установлен или не работает."
fi

# Определение IP-адреса интерфейса ens3, если нет — fallback на первый IP
IP=$(ip -4 addr show ens3 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || true)
if [ -z "$IP" ]; then
  IP=$(hostname -I | awk '{print $1}')
fi
echo "Используется IP: $IP"

# Запуск Docker-контейнера wg-easy с параметрами
echo "Запускаем контейнер wg-easy..."
docker run -d \
  --name wg-easy \
  -e WG_HOST="$IP" \
  -e PASSWORD_HASH="$hash" \
  -e WG_MTU=1280 \
  -v ~/.wg-easy:/etc/wireguard \
  -p 51820:51820/udp \
  -p 51821:51821/tcp \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  --sysctl net.ipv4.conf.all.src_valid_mark=1 \
  --sysctl net.ipv4.ip_forward=1 \
  --restart unless-stopped \
  ghcr.io/wg-easy/wg-easy

# Вывод ссылки и пароля в файл и на экран
echo -e "Панель WG-Easy доступна по адресу:\nhttp://$IP:51821\nПароль: $PASSWORD" | tee wg-out.txt

# Дополнительный вывод содержимого файла сразу после выполнения
echo -e "\nСодержимое файла wg-out.txt:"
cat wg-out.txt
