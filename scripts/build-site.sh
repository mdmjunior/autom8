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

npm_install_command() {
  if [[ -f "$SITE_DIR/package-lock.json" ]]; then
    printf 'npm ci'
  else
    printf 'npm install'
  fi
}

sync_installer() {
  log "Sincronizando instalador público a partir do canônico."

  if [[ ! -f "$PROJECT_ROOT/installer/install.sh" ]]; then
    error "Instalador canônico não encontrado: installer/install.sh"
    exit 1
  fi

  mkdir -p "$PROJECT_ROOT/site/public"

  cp "$PROJECT_ROOT/installer/install.sh" "$PROJECT_ROOT/site/public/install.sh"
  chmod +x "$PROJECT_ROOT/installer/install.sh" "$PROJECT_ROOT/site/public/install.sh"

  bash -n "$PROJECT_ROOT/installer/install.sh"
  bash -n "$PROJECT_ROOT/site/public/install.sh"

  if ! cmp -s "$PROJECT_ROOT/installer/install.sh" "$PROJECT_ROOT/site/public/install.sh"; then
    error "site/public/install.sh divergiu de installer/install.sh após sincronização."
    exit 1
  fi

  if ! grep -q 'releases/latest/download/autom8-latest.tar.gz' "$PROJECT_ROOT/site/public/install.sh"; then
    error "Instalador público não aponta para GitHub Releases latest."
    exit 1
  fi

  log "Instalador público validado."
}

run_build_with_local_npm() {
  local install_cmd
  install_cmd="$(npm_install_command)"

  log "npm encontrado no host. Gerando build local com: $install_cmd"

  cd "$SITE_DIR"
  $install_cmd
  npm run build
}

run_build_with_docker_node() {
  local install_cmd
  install_cmd="$(npm_install_command)"

  if ! command -v docker >/dev/null 2>&1; then
    error "npm não foi encontrado e Docker também não está disponível."
    error "Instale npm no host ou execute em ambiente com Docker."
    exit 1
  fi

  log "npm não encontrado no host. Usando Docker com $NODE_IMAGE."
  log "Comando de dependências: $install_cmd"

  docker run --rm \
    --user "$(id -u):$(id -g)" \
    -e npm_config_cache=/tmp/.npm \
    -v "$SITE_DIR:/app" \
    -w /app \
    "$NODE_IMAGE" \
    sh -lc "$install_cmd && npm run build"
}

cd "$PROJECT_ROOT"

if [[ ! -d "$SITE_DIR" ]]; then
  error "Diretório do site não encontrado: $SITE_DIR"
  exit 1
fi

if [[ -x "$PROJECT_ROOT/scripts/build-apps-catalog.sh" ]]; then
  log "Gerando catálogo consolidado de apps."
  "$PROJECT_ROOT/scripts/build-apps-catalog.sh"
fi

if [[ -x "$PROJECT_ROOT/scripts/validate-profiles-catalog.sh" ]]; then
  "$PROJECT_ROOT/scripts/validate-profiles-catalog.sh"
fi

if [[ -x "$PROJECT_ROOT/scripts/validate-apps-catalog.sh" ]]; then
  log "Validando catálogo de apps."
  "$PROJECT_ROOT/scripts/validate-apps-catalog.sh"
fi

if [[ -x "$PROJECT_ROOT/scripts/sync-docs.sh" ]]; then
  log "Sincronizando documentação gerada."
  "$PROJECT_ROOT/scripts/sync-docs.sh"
fi

sync_installer

if command -v npm >/dev/null 2>&1; then
  run_build_with_local_npm
else
  run_build_with_docker_node
fi

log "Site build concluído."
log "Arquivos gerados esperados: site/public/install.sh, dados do site, documentação sincronizada e build do frontend."
log "Pacotes estáveis continuam sendo publicados somente via GitHub Releases."
