#!/bin/bash

# Проверка на запуск от root
if [ "$EUID" -ne 0 ]; then
  echo "Пожалуйста, запустите скрипт от имени root (sudo)." >&2
  exit 1
fi

echo "Установка 3x-ui..."
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)

# Проверка, что бинарник установлен
if [ ! -f /usr/local/x-ui/x-ui ]; then
  echo "Ошибка: 3x-ui не был установлен корректно." >&2
  exit 1
fi

echo "3x-ui успешно установлен!"

echo "Изменение учётных данных..."
PASSWORD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)
WEBPATH=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)

/usr/local/x-ui/x-ui setting -username "admin" -password "${PASSWORD}" -webBasePath "${WEBPATH}" -port "2053"

# Перезапуск 3x-ui
systemctl restart x-ui

# Получение IP-адреса сервера
SERVER_IP=$(hostname -I | awk '{print $1}')

# Вывод информации
OUTPUT_FILE="3x-ui.txt"

{
  echo -e "\nПанель 3x-ui доступна по ссылке: http://$SERVER_IP:2053/$WEBPATH"
  echo -e "Логин: admin"
  echo -e "Пароль: $PASSWORD"
  echo -e "\nИнструкция по настройке 3x-ui:"
  echo "https://wiki.aeza.net/razvertyvanie-proksi-protokola-vless-s-pomoshyu-3x-ui"
} | tee "$OUTPUT_FILE"

echo -e "\nУстановка завершена. Данные сохранены в '$OUTPUT_FILE'."
