#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${1:-$(pwd)}"

cd "$APP_DIR"

mkdir -p storage/app/autom8/builds
mkdir -p storage/app/autom8/artifacts
mkdir -p storage/logs
mkdir -p bootstrap/cache

chown -R www-data:www-data storage bootstrap/cache || true
chmod -R 775 storage bootstrap/cache || true

echo "Permissões ajustadas em: $APP_DIR"