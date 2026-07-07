#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${AUTOM8_REPO_DIR:-/opt/oslabs/repos/autom8}"
BRANCH="${AUTOM8_BRANCH:-main}"
DOMAIN="${AUTOM8_DOMAIN:-https://autom8.oslabs.com.br}"
SERVICE_NAME="${AUTOM8_SERVICE_NAME:-}"
RESTART_SERVICE="${AUTOM8_RESTART_SERVICE:-1}"

log() {
  printf '\033[1;34m[AutoM8 Deploy]\033[0m %s\n' "$1"
}

warn() {
  printf '\033[1;33m[AutoM8 Deploy]\033[0m %s\n' "$1"
}

error() {
  printf '\033[1;31m[AutoM8 Deploy]\033[0m %s\n' "$1" >&2
}

log "Repo: $REPO_DIR"
log "Branch: $BRANCH"
log "Domínio: $DOMAIN"

if [[ ! -d "$REPO_DIR/.git" ]]; then
  error "Diretório informado não parece ser um repositório Git: $REPO_DIR"
  exit 1
fi

cd "$REPO_DIR"

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
log "Branch atual no servidor: $CURRENT_BRANCH"

if [[ -n "$(git status --porcelain)" ]]; then
  error "O repositório remoto possui alterações locais não commitadas."
  error "Resolva antes de fazer deploy:"
  git status --short
  exit 1
fi

log "Atualizando código..."
git fetch origin "$BRANCH"
git checkout "$BRANCH"
git pull --ff-only origin "$BRANCH"

log "Garantindo permissão dos scripts..."
chmod +x scripts/build-site.sh
chmod +x scripts/deploy-site-vps.sh

log "Gerando build do site..."
./scripts/build-site.sh

log "Validando artefatos do site..."

if [[ ! -d "$REPO_DIR/site/dist" ]]; then
  error "Build não gerou site/dist"
  exit 1
fi

if [[ ! -f "$REPO_DIR/site/dist/install.sh" ]]; then
  error "Build não gerou site/dist/install.sh"
  exit 1
fi

if [[ -d "$REPO_DIR/site/dist/downloads" ]]; then
  warn "Diretório site/dist/downloads encontrado."
  warn "Pacotes da suíte não devem mais ser publicados pela VPS."
  warn "Revise se há arquivos legados no site/public/downloads."
fi

log "Artefatos do site validados:"
ls -lah "$REPO_DIR/site/dist" | head

if [[ "$RESTART_SERVICE" == "1" ]]; then
  if [[ -n "$SERVICE_NAME" ]]; then
    log "Reiniciando serviço Docker Swarm informado: $SERVICE_NAME"
    docker service update --force "$SERVICE_NAME"
    docker service ps "$SERVICE_NAME" --no-trunc | head -20
  else
    warn "AUTOM8_SERVICE_NAME não foi informado."
    warn "Build concluído, mas nenhum serviço foi reiniciado."
    warn "Para reiniciar no deploy, use:"
    warn "AUTOM8_SERVICE_NAME=nome_do_servico ./scripts/deploy-site-vps.sh"
  fi
else
  warn "Reinício de serviço desativado por AUTOM8_RESTART_SERVICE=0."
fi

log "Testando domínio..."
curl -I "$DOMAIN" || true
curl -I "$DOMAIN/install.sh" || true

log "Deploy finalizado."
