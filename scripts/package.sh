#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUITE_DIR="$PROJECT_ROOT/suite"
DIST_DIR="$PROJECT_ROOT/dist"

VERSION="$(tr -d '[:space:]' < "$SUITE_DIR/VERSION")"

mkdir -p "$DIST_DIR"

PACKAGE_VERSIONED="$DIST_DIR/autom8-${VERSION}.tar.gz"
PACKAGE_LATEST="$DIST_DIR/autom8-latest.tar.gz"

tar \
  --exclude='logs/*' \
  --exclude='tmp/*' \
  --exclude='backups/*' \
  --exclude='reports/*' \
  -czf "$PACKAGE_VERSIONED" \
  -C "$SUITE_DIR" .

cp "$PACKAGE_VERSIONED" "$PACKAGE_LATEST"

mkdir -p "$PROJECT_ROOT/site/public/downloads"
cp "$PACKAGE_VERSIONED" "$PROJECT_ROOT/site/public/downloads/"
cp "$PACKAGE_LATEST" "$PROJECT_ROOT/site/public/downloads/"

echo "Pacotes gerados:"
echo "$PACKAGE_VERSIONED"
echo "$PACKAGE_LATEST"
echo
echo "Copiados para:"
echo "$PROJECT_ROOT/site/public/downloads/"
