#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITE_DIR="$PROJECT_ROOT/site"
NODE_IMAGE="${AUTOM8_NODE_IMAGE:-node:22-alpine}"

log() {
  printf '\033[1;34m[AutoM8 Site Build]\033[0m %s\n' "$1"
}

warn() {
  printf '\033[1;33m[AutoM8 Site Build]\033[0m %s\n' "$1"
}

error() {
  printf '\033[1;31m[AutoM8 Site Build]\033[0m %s\n' "$1" >&2
}

cd "$PROJECT_ROOT"

./scripts/sync-docs.sh

cp installer/install.sh site/public/install.sh
chmod +x site/public/install.sh

if [[ ! -d "$SITE_DIR" ]]; then
  error "Diretório do site não encontrado: $SITE_DIR"
  exit 1
fi

run_build_with_local_npm() {
  log "npm encontrado no host. Gerando build local."
  cd "$SITE_DIR"
  npm install
  npm run build
}

run_build_with_docker_node() {
  if ! command -v docker >/dev/null 2>&1; then
    error "npm não foi encontrado e Docker também não está disponível."
    error "Instale npm no host ou execute em ambiente com Docker."
    exit 1
  fi

  log "npm não encontrado no host. Usando Docker com $NODE_IMAGE."

  docker run --rm \
    --user "$(id -u):$(id -g)" \
    -e npm_config_cache=/tmp/.npm \
    -v "$SITE_DIR:/app" \
    -w /app \
    "$NODE_IMAGE" \
    sh -lc 'npm install && npm run build'
}

if command -v npm >/dev/null 2>&1; then
  run_build_with_local_npm
else
  run_build_with_docker_node
fi

log "Site build concluído."
log "Observação: pacotes da suíte não são gerados no build do site."
log "Pacotes estáveis são publicados somente via GitHub Releases."
