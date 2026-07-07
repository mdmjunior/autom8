#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="${AUTOM8_GITHUB_REPO:-mdmjunior/autom8}"
VERSION="$(tr -d '[:space:]' < "$PROJECT_ROOT/suite/VERSION")"
TAG="v${VERSION}"

log() {
  printf '\033[1;34m[AutoM8 Release]\033[0m %s\n' "$1"
}

warn() {
  printf '\033[1;33m[AutoM8 Release]\033[0m %s\n' "$1"
}

error() {
  printf '\033[1;31m[AutoM8 Release]\033[0m %s\n' "$1" >&2
}

cd "$PROJECT_ROOT"

if [[ -z "$VERSION" ]]; then
  error "suite/VERSION está vazio."
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  error "Existem alterações locais não commitadas."
  git status --short
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  error "GitHub CLI não encontrado. Instale e autentique com: gh auth login"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  error "GitHub CLI não está autenticado. Rode: gh auth login"
  exit 1
fi

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$CURRENT_BRANCH" != "main" ]]; then
  error "Releases estáveis devem ser publicados a partir da branch main."
  error "Branch atual: $CURRENT_BRANCH"
  exit 1
fi

log "Atualizando main..."
git fetch origin main
git pull --ff-only origin main

log "Validando build do site antes da release..."
./scripts/build-site.sh

PACKAGE_DIR="$(mktemp -d /tmp/autom8-release-${VERSION}-XXXXXX)"
cleanup() {
  rm -rf "$PACKAGE_DIR"
}
trap cleanup EXIT

log "Gerando pacotes temporários em $PACKAGE_DIR..."
AUTOM8_PACKAGE_OUTPUT_DIR="$PACKAGE_DIR" ./scripts/package.sh

PACKAGE_VERSIONED="$PACKAGE_DIR/autom8-${VERSION}.tar.gz"
PACKAGE_LATEST="$PACKAGE_DIR/autom8-latest.tar.gz"

test -f "$PACKAGE_VERSIONED"
test -f "$PACKAGE_LATEST"

log "Pacotes gerados:"
ls -lah "$PACKAGE_DIR"

if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  warn "Release $TAG já existe."
  warn "Os assets serão substituídos."
  gh release upload "$TAG" "$PACKAGE_VERSIONED" "$PACKAGE_LATEST" --repo "$REPO" --clobber
else
  log "Criando release $TAG..."
  gh release create "$TAG" \
    "$PACKAGE_VERSIONED" \
    "$PACKAGE_LATEST" \
    --repo "$REPO" \
    --target main \
    --title "AutoM8 ${VERSION}" \
    --notes "Release estável do AutoM8 ${VERSION}."
fi

log "Validando assets publicados..."
gh release view "$TAG" --repo "$REPO" --json tagName,name,isLatest,url

log "Release estável publicada."
log "URL estável usada pelo install.sh:"
echo "https://github.com/${REPO}/releases/latest/download/autom8-latest.tar.gz"
