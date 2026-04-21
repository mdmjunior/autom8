#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/autom8-dev/app"
COMPOSE_FILE="docker-compose.dev.yml"
PROJECT_NAME="autom8_dev"
BRANCH="develop"

echo "[1/10] Entrando em ${APP_DIR}"
cd "${APP_DIR}"

echo "[2/10] Atualizando código..."
git fetch origin
git checkout "${BRANCH}"
git pull origin "${BRANCH}"

echo "[3/10] Subindo/reconstruindo containers..."
docker compose -p "${PROJECT_NAME}" -f "${COMPOSE_FILE}" up -d --build

echo "[4/10] Instalando dependências PHP..."
docker compose -p "${PROJECT_NAME}" -f "${COMPOSE_FILE}" exec -T app composer install --optimize-autoloader

echo "[5/10] Garantindo permissões..."
if [ -x ./fix-permissions.sh ]; then
  ./fix-permissions.sh "${APP_DIR}"
fi

echo "[6/10] Buildando frontend..."
docker compose -p "${PROJECT_NAME}" -f "${COMPOSE_FILE}" exec -T app bash -lc "npm install && npm run build"

echo "[7/10] Gerando APP_KEY se necessário..."
docker compose -p "${PROJECT_NAME}" -f "${COMPOSE_FILE}" exec -T app php artisan key:generate --force || true

echo "[8/10] Rodando migrations..."
docker compose -p "${PROJECT_NAME}" -f "${COMPOSE_FILE}" exec -T app php artisan migrate --force

echo "[9/10] Sincronizando catálogo..."
docker compose -p "${PROJECT_NAME}" -f "${COMPOSE_FILE}" exec -T app php artisan autom8:sync-catalog || true

echo "[10/10] Limpando caches e exibindo status..."
docker compose -p "${PROJECT_NAME}" -f "${COMPOSE_FILE}" exec -T app php artisan optimize:clear
docker compose -p "${PROJECT_NAME}" -f "${COMPOSE_FILE}" ps

echo
echo "Deploy de DESENVOLVIMENTO concluído."