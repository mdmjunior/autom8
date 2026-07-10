#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="${AUTOM8_GITHUB_REPO:-mdmjunior/autom8}"
VERSION="$(tr -d '[:space:]' < "$PROJECT_ROOT/suite/VERSION")"
TAG="v${VERSION}"
EXPECTED_BRANCH="${AUTOM8_RC_BRANCH:-feature/apps-v0.2}"

log() {
  printf '\033[1;34m[AutoM8 RC]\033[0m %s\n' "$1"
}

warn() {
  printf '\033[1;33m[AutoM8 RC]\033[0m %s\n' "$1"
}

error() {
  printf '\033[1;31m[AutoM8 RC]\033[0m %s\n' "$1" >&2
}

cd "$PROJECT_ROOT"

if [[ -z "$VERSION" ]]; then
  error "suite/VERSION está vazio."
  exit 1
fi

if [[ "$VERSION" != *"-rc"* ]]; then
  error "Versão RC deve conter -rc. Versão atual: $VERSION"
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  error "Existem alterações locais não commitadas."
  git status --short
  exit 1
fi

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

if [[ "$CURRENT_BRANCH" != "$EXPECTED_BRANCH" ]]; then
  error "RC deve ser publicado a partir da branch $EXPECTED_BRANCH."
  error "Branch atual: $CURRENT_BRANCH"
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

log "Atualizando branch $EXPECTED_BRANCH..."
git fetch origin "$EXPECTED_BRANCH"
git pull --ff-only origin "$EXPECTED_BRANCH"

log "Executando smoke test local..."
./scripts/smoke-ubuntu-desktop.sh

log "Validando build do site..."
./scripts/build-site.sh

PACKAGE_DIR="$(mktemp -d /tmp/autom8-rc-${VERSION}-XXXXXX)"

cleanup() {
  rm -rf "$PACKAGE_DIR"
}

trap cleanup EXIT

log "Gerando pacote RC temporário em $PACKAGE_DIR..."
AUTOM8_PACKAGE_OUTPUT_DIR="$PACKAGE_DIR" ./scripts/package.sh

PACKAGE_VERSIONED="$PACKAGE_DIR/autom8-${VERSION}.tar.gz"
PACKAGE_GENERATED_LATEST="$PACKAGE_DIR/autom8-latest.tar.gz"
PACKAGE_RC_LATEST="$PACKAGE_DIR/autom8-rc-latest.tar.gz"

test -f "$PACKAGE_VERSIONED"
test -f "$PACKAGE_GENERATED_LATEST"

cp "$PACKAGE_VERSIONED" "$PACKAGE_RC_LATEST"
rm -f "$PACKAGE_GENERATED_LATEST"

log "Validando conteúdo do pacote RC..."
tar -tzf "$PACKAGE_VERSIONED" | grep -E '(^./bin/autom8$|bin/autom8$)' >/dev/null
tar -tzf "$PACKAGE_VERSIONED" | grep -E '(^./catalog/apps.json$|catalog/apps.json$)' >/dev/null
tar -tzf "$PACKAGE_VERSIONED" | grep -E '(^./catalog/profiles.json$|catalog/profiles.json$)' >/dev/null
tar -tzf "$PACKAGE_VERSIONED" | grep -E '(^./modules/apps.sh$|modules/apps.sh$)' >/dev/null
tar -tzf "$PACKAGE_VERSIONED" | grep -E '(^./modules/profiles.sh$|modules/profiles.sh$)' >/dev/null
tar -tzf "$PACKAGE_VERSIONED" | grep -E '(^./lib/apps/catalog.sh$|lib/apps/catalog.sh$)' >/dev/null

log "Pacotes RC gerados:"
ls -lah "$PACKAGE_DIR"

RELEASE_NOTES_FILE="$PROJECT_ROOT/docs/releases/${VERSION}.md"

if [[ ! -f "$RELEASE_NOTES_FILE" ]]; then
  error "Notas de release não encontradas: $RELEASE_NOTES_FILE"
  exit 1
fi

if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  warn "Release $TAG já existe."
  warn "Os assets RC serão substituídos."
  gh release upload "$TAG" "$PACKAGE_VERSIONED" "$PACKAGE_RC_LATEST" --repo "$REPO" --clobber
else
  log "Criando prerelease $TAG..."
  gh release create "$TAG" \
    "$PACKAGE_VERSIONED" \
    "$PACKAGE_RC_LATEST" \
    --repo "$REPO" \
    --target "$EXPECTED_BRANCH" \
    --title "AutoM8 ${VERSION}" \
    --notes-file "$RELEASE_NOTES_FILE" \
    --prerelease
fi

log "Validando prerelease publicada..."
gh release view "$TAG" \
  --repo "$REPO" \
  --json tagName,name,url,isDraft,isPrerelease,publishedAt

log "Assets publicados:"
gh release view "$TAG" \
  --repo "$REPO" \
  --json assets \
  --jq '.assets[].name'

log "RC publicado."
log "Instalação manual do RC em VM descartável:"
echo "curl -fsSL https://autom8.oslabs.com.br/install.sh -o /tmp/autom8-install.sh"
echo "AUTOM8_PACKAGE_URL=https://github.com/${REPO}/releases/download/${TAG}/autom8-${VERSION}.tar.gz bash /tmp/autom8-install.sh"
