#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_VERSION="${AUTOM8_TARGET_VERSION:-0.2.0}"
CURRENT_BRANCH_EXPECTED="${AUTOM8_STABLE_SOURCE_BRANCH:-feature/apps-v0.2}"
RESULT_FILE="${AUTOM8_RC_RESULT_FILE:-$PROJECT_ROOT/docs/releases/results/0.2.0-rc2-ubuntu-desktop.md}"

log() {
  printf '\033[1;34m[AutoM8 Stable Prep]\033[0m %s\n' "$1"
}

error() {
  printf '\033[1;31m[AutoM8 Stable Prep]\033[0m %s\n' "$1" >&2
}

cd "$PROJECT_ROOT"

current_branch="$(git rev-parse --abbrev-ref HEAD)"

if [[ "$current_branch" != "$CURRENT_BRANCH_EXPECTED" ]]; then
  error "Execute na branch $CURRENT_BRANCH_EXPECTED."
  error "Branch atual: $current_branch"
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  error "Existem alterações locais não commitadas."
  git status --short
  exit 1
fi

if [[ ! -f "$RESULT_FILE" ]]; then
  error "Resultado de teste do RC não encontrado:"
  error "$RESULT_FILE"
  error "Crie a partir do template e aprove o RC antes de promover."
  exit 1
fi

if ! grep -qiE 'Resultado geral:.*aprovado|Aprovado|Promover para v0\.2\.0 estável' "$RESULT_FILE"; then
  error "Resultado do RC não indica aprovação clara."
  error "Revise: $RESULT_FILE"
  exit 1
fi

log "RC aprovado encontrado em: $RESULT_FILE"

log "Executando gate obrigatório da stable."
./scripts/verify-stable-gate.sh

printf '%s\n' "$TARGET_VERSION" > suite/VERSION

log "Versão ajustada para $TARGET_VERSION."

log "Gerando e validando catálogos."
./scripts/build-apps-catalog.sh
./scripts/validate-apps-catalog.sh
./scripts/validate-profiles-catalog.sh

log "Validando instalador."
./scripts/verify-installer.sh

log "Executando smoke."
./scripts/smoke-ubuntu-desktop.sh

log "Gerando build do site."
./scripts/build-site.sh

log "Gerando pacote local."
./scripts/package.sh

log "Preparação estável concluída."
echo
echo "Revise o diff:"
echo "  git status"
echo "  git diff --stat"
echo "  git diff --check"
echo
echo "Depois faça commit:"
echo "  git add suite/VERSION docs/releases/0.2.0.md docs/releases/0.2.0-stable-checklist.md scripts/prepare-stable-release.sh"
echo "  git commit -m \"Prepare v0.2.0 stable release\""
