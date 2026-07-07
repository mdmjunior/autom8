#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${AUTOM8_REPO_DIR:-/opt/oslabs/repos/autom8}"
BRANCH="${AUTOM8_BRANCH:-main}"

log() {
  printf '\033[1;34m[AutoM8 Deploy]\033[0m %s\n' "$1"
}

error() {
  printf '\033[1;31m[AutoM8 Deploy]\033[0m %s\n' "$1" >&2
}

log "Repo: $REPO_DIR"
log "Branch: $BRANCH"

if [[ ! -d "$REPO_DIR/.git" ]]; then
  error "Diretório informado não parece ser um repositório Git: $REPO_DIR"
  exit 1
fi

cd "$REPO_DIR"

log "Branch atual no servidor: $(git rev-parse --abbrev-ref HEAD)"

if [[ -n "$(git status --porcelain)" ]]; then
  error "O repositório remoto possui alterações locais não commitadas."
  error "Resolva antes de fazer deploy:"
  git status --short
  exit 1
fi

log "Atualizando código."
git fetch origin "$BRANCH"
git checkout "$BRANCH"
git pull --ff-only origin "$BRANCH"

log "Garantindo permissão dos scripts."
chmod +x infra/deploy-site.sh

log "Delegando deploy para infra/deploy-site.sh."
exec ./infra/deploy-site.sh
