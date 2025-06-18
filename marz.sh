#!/bin/bash

# Проверка на выполнение от root
if [ "$EUID" -ne 0 ]; then
  echo "Пожалуйста, запустите скрипт от имени root (sudo)." >&2
  exit 1
fi

# Обновление системы и установка необходимых пакетов
echo "Обновление пакетов и установка Docker..."
apt update -y && apt install -y docker.io docker-compose curl

# Установка Marzban
echo "Установка Marzban в фоновом режиме..."
bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install > /dev/null 2>&1 &

# Ожидание запуска Marzban
echo -n "Ожидание запуска Marzban..."
while ! docker ps | grep -q marzban; do
    echo -n "."
    sleep 2
done
echo -e "\nMarzban успешно запущен!"

# Создание администратора
echo "Создание администратора..."
ADMIN_PASSWORD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)

if ! command -v marzban >/dev/null 2>&1; then
  echo "Ошибка: CLI Marzban не найден. Убедитесь, что установка завершилась корректно." >&2
  exit 1
fi

marzban cli admin create --username admin --sudo --password "$ADMIN_PASSWORD" --telegram-id 0 --discord-webhook 0

# Получение IP-адреса сервера
SERVER_IP=$(curl -s ifconfig.me)

# Создание файла с данными
OUTPUT_FILE="marzban.txt"

{
  echo -e "\nПанель Marzban доступна по ссылке: http://localhost:8000/dashboard/#/login"
  echo -e "Логин: admin"
  echo -e "Пароль: $ADMIN_PASSWORD"
  echo -e "\nДля доступа к панели выполните на локальном компьютере:"
  echo -e "ssh -L 8000:localhost:8000 root@$SERVER_IP"
  echo -e "\nПосле этого откройте в браузере: http://localhost:8000/dashboard/#/login"
  echo -e "\nИнструкция по настройке Marzban: https://wiki.aeza.net/razvertyvanie-proksi-protokola-vless-s-pomoshyu-marzban"
} | tee "$OUTPUT_FILE"

echo -e "\nУстановка завершена. Данные сохранены в '$OUTPUT_FILE'."
