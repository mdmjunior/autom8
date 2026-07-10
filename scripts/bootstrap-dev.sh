#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common/project.sh"

required_commands=(
  bash
  git
  python3
  node
  npm
  docker
  shellcheck
  curl
  jq
  tar
  gzip
)

missing=0

log "Projeto: ${PROJECT_ROOT}"
log "Verificando ambiente local..."

for command_name in "${required_commands[@]}"; do
  if command -v "$command_name" >/dev/null 2>&1; then
    printf '  [OK] %s\n' "$command_name"
  else
    printf '  [FALTA] %s\n' "$command_name"
    missing=1
  fi
done

if (( missing != 0 )); then
  error "Instale as dependências ausentes antes de continuar."
fi

printf '\nVersões detectadas:\n'
git --version
node --version
npm --version
docker --version
shellcheck --version | head -n 1
python3 --version

log "Ambiente local aprovado."
