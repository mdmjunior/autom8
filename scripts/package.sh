#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUITE_DIR="$PROJECT_ROOT/suite"

VERSION="$(tr -d '[:space:]' < "$SUITE_DIR/VERSION")"

if [[ -z "$VERSION" ]]; then
  echo "ERRO: suite/VERSION está vazio." >&2
  exit 1
fi

if [[ -x "$PROJECT_ROOT/scripts/build-apps-catalog.sh" && "${AUTOM8_SKIP_APPS_CATALOG_BUILD:-0}" != "1" ]]; then
  "$PROJECT_ROOT/scripts/build-apps-catalog.sh"
fi

if [[ -x "$PROJECT_ROOT/scripts/sync-docs.sh" && "${AUTOM8_SKIP_DOC_SYNC:-0}" != "1" ]]; then
  "$PROJECT_ROOT/scripts/sync-docs.sh"
fi

if [[ ! -f "$SUITE_DIR/catalog/apps.json" ]]; then
  echo "ERRO: catálogo consolidado não encontrado: suite/catalog/apps.json" >&2
  exit 1
fi

python3 -m json.tool "$SUITE_DIR/catalog/apps.json" >/dev/null

OUTPUT_DIR="${AUTOM8_PACKAGE_OUTPUT_DIR:-$(mktemp -d /tmp/autom8-package-${VERSION}-XXXXXX)}"

mkdir -p "$OUTPUT_DIR"

PACKAGE_VERSIONED="$OUTPUT_DIR/autom8-${VERSION}.tar.gz"
PACKAGE_LATEST="$OUTPUT_DIR/autom8-latest.tar.gz"

tar \
  --exclude='logs/*' \
  --exclude='tmp/*' \
  --exclude='backups/*' \
  --exclude='reports/*' \
  -czf "$PACKAGE_VERSIONED" \
  -C "$SUITE_DIR" .

cp "$PACKAGE_VERSIONED" "$PACKAGE_LATEST"

echo "Pacotes gerados temporariamente:"
echo "$PACKAGE_VERSIONED"
echo "$PACKAGE_LATEST"
echo
echo "Diretório temporário:"
echo "$OUTPUT_DIR"
echo
echo "Observação:"
echo "Os pacotes não são copiados para o site, VPS ou repositório local."
echo "Use scripts/release-stable.sh para publicar no GitHub Releases."
