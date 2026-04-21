#!/usr/bin/env bash
set -euo pipefail

cd /var/www/html

mkdir -p storage/app/autom8/builds
mkdir -p storage/app/autom8/artifacts
mkdir -p storage/logs
mkdir -p bootstrap/cache

chown -R www-data:www-data storage bootstrap/cache || true
chmod -R 775 storage bootstrap/cache || true

if [ ! -f .env ]; then
  echo ".env not found inside container."
fi

if [ -f artisan ]; then
  php artisan optimize:clear || true
fi

php-fpm