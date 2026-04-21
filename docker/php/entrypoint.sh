#!/usr/bin/env bash
set -euo pipefail

cd /var/www/html

mkdir -p storage/app/autom8/builds
mkdir -p storage/app/autom8/artifacts
mkdir -p storage/logs
mkdir -p storage/framework/cache
mkdir -p storage/framework/sessions
mkdir -p storage/framework/views
mkdir -p bootstrap/cache

chown -R www-data:www-data storage bootstrap/cache || true
chmod -R 775 storage bootstrap/cache || true

if [ -f artisan ]; then
  php artisan optimize:clear || true
fi

exec php-fpm