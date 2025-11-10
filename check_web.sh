#!/bin/bash

# Проверка: слушает ли nginx порт 80
if ! ss -tuln | grep -q ':80\s'; then
    exit 1
fi

# Проверка: существует ли index.html
if [ ! -f /var/www/html/index.html ]; then
    exit 1
fi

exit 0
