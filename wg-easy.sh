#!/bin/bash

# Проверка запуска от root
if [ "$(id -u)" -ne 0 ]; then
    echo "Этот скрипт нужно запускать от root (используйте sudo)." >&2
    exit 1
fi

# Получение IP-адреса сервера
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "Обновление пакетов и установка Docker..."
apt update -y && apt install -y docker.io curl

if ! command -v docker >/dev/null 2>&1; then
    echo "Ошибка: Docker не установлен или не найден." >&2
    exit 1
fi

echo "Удаление старого контейнера и конфигурации..."
docker rm -f wg-easy 2>/dev/null || true
rm -rf ~/.wg-easy 2>/dev/null

# Генерация пароля и его хеша
PASSWORD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 10)
echo "Генерация хеша пароля..."

RAW_HASH=$(docker run --rm ghcr.io/wg-easy/wg-easy wgpw "$PASSWORD")
PASSWORD_HASH=$(echo "$RAW_HASH" | awk -F"'" '{print $2}')

if [[ -z "$PASSWORD_HASH" ]]; then
    echo "Ошибка генерации хеша пароля." >&2
    exit 1
fi

echo "Хеш успешно сгенерирован."

echo "Запуск контейнера WG-Easy..."
docker run -d \
  --name=wg-easy \
  -e LANG=en \
  -e WG_HOST="$SERVER_IP" \
  -e PASSWORD_HASH="$PASSWORD_HASH" \
  -e PORT=51821 \
  -e WG_PORT=51820 \
  -v ~/.wg-easy:/etc/wireguard \
  -p 51820:51820/udp \
  -p 51821:51821/tcp \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
  --sysctl="net.ipv4.ip_forward=1" \
  --restart unless-stopped \
  ghcr.io/wg-easy/wg-easy:latest

# Вывод в файл
OUTPUT_FILE="wg-easy.txt"

{
  echo "***************************************************************"
  echo "Панель WG-Easy доступна по ссылке: http://$SERVER_IP:51821"
  echo "Пароль: $PASSWORD"
} | tee "$OUTPUT_FILE"

echo -e "\nУстановка завершена. Информация сохранена в '$OUTPUT_FILE'."
