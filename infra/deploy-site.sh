#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/autom8/site"
STACK_FILE="$APP_DIR/infra/docker-stack.yml"
STACK_NAME="autom8"

cd "$APP_DIR"

echo "Gerando pacote da suíte..."
./scripts/package.sh

echo "Sincronizando install.sh público..."
cp installer/install.sh site/public/install.sh
chmod +x site/public/install.sh

echo "Gerando package-lock se necessário..."
cd site
npm install
cd ..

echo "Construindo imagem Docker..."
docker build -t autom8-site:latest ./site

echo "Publicando stack no Docker Swarm..."
docker stack deploy -c "$STACK_FILE" "$STACK_NAME"

echo "Status:"
docker stack services "$STACK_NAME"
