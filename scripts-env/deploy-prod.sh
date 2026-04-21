#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/autom8-prod/app"
COMPOSE_FILE="docker-compose.prod.yml"
PROJECT_NAME="autom8_prod"
BRANCH="main"

echo "[1/11] Entrando em ${APP_DIR}"
cd "${APP_DIR}"

echo "[2/11] Atualizando código..."
git fetch origin
git checkout "${BRANCH}"
git pull origin "${BRANCH}"

echo "[3/11] Subindo/reconstruindo containers..."
docker compose -p "${PROJECT_NAME}" -f "${COMPOSE_FILE}" up -d --build

echo "[4/11] Instalando dependências PHP..."
docker compose -p "${PROJECT_NAME}" -f "${COMPOSE_FILE}" exec -T app composer install --no-dev --optimize-autoloader

echo "[5/11] Garantindo permissões..."
if [ -x ./fix-permissions.sh ]; then
  sudo ./fix-permissions.sh "${APP_DIR}"
fi

echo "[6/11] Buildando frontend..."
docker compose -p "${PROJECT_NAME}" -f "${COMPOSE_FILE}" exec -T app bash -lc "npm install && npm run build"

echo "[7/11] Gerando APP_KEY se necessário..."
docker compose -p "${PROJECT_NAME}" -f "${COMPOSE_FILE}" exec -T app php artisan key:generate --force || true

echo "[8/11] Rodando migrations..."
docker compose -p "${PROJECT_NAME}" -f "${COMPOSE_FILE}" exec -T app php artisan migrate --force

echo "[9/11] Sincronizando catálogo..."
docker compose -p "${PROJECT_NAME}" -f "${COMPOSE_FILE}" exec -T app php artisan autom8:sync-catalog || true

echo "[10/11] Otimizando Laravel..."
docker compose -p "${PROJECT_NAME}" -f "${COMPOSE_FILE}" exec -T app php artisan optimize:clear
docker compose -p "${PROJECT_NAME}" -f "${COMPOSE_FILE}" exec -T app php artisan config:cache
docker compose -p "${PROJECT_NAME}" -f "${COMPOSE_FILE}" exec -T app php artisan route:cache
docker compose -p "${PROJECT_NAME}" -f "${COMPOSE_FILE}" exec -T app php artisan view:cache

echo "[11/11] Status final"
docker compose -p "${PROJECT_NAME}" -f "${COMPOSE_FILE}" ps

echo
echo "Deploy de PRODUÇÃO concluído."