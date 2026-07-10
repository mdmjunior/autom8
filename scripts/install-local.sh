#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$PROJECT_ROOT/suite/VERSION")"

INSTALL_DIR="${AUTOM8_INSTALL_DIR:-/opt/autom8}"
STAGING_DIR="${INSTALL_DIR}.new"
PREVIOUS_DIR="${INSTALL_DIR}.previous"
PACKAGE_DIR="$(mktemp -d "/tmp/autom8-local-${VERSION}-XXXXXX")"

cleanup() {
  rm -rf "$PACKAGE_DIR"
}

trap cleanup EXIT

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  echo "ERRO: não execute como root. Use usuário comum com sudo." >&2
  exit 1
fi

AUTOM8_PACKAGE_OUTPUT_DIR="$PACKAGE_DIR" \
  "$PROJECT_ROOT/scripts/package.sh"

PACKAGE="$PACKAGE_DIR/autom8-${VERSION}.tar.gz"

if [[ ! -f "$PACKAGE" ]]; then
  echo "ERRO: pacote não encontrado: $PACKAGE" >&2
  exit 1
fi

sudo rm -rf "$STAGING_DIR"
sudo mkdir -p "$STAGING_DIR"
sudo tar -xzf "$PACKAGE" -C "$STAGING_DIR"
sudo chmod +x "$STAGING_DIR/bin/autom8"

if [[ -f "$INSTALL_DIR/config/autom8.conf" ]]; then
  sudo cp \
    "$INSTALL_DIR/config/autom8.conf" \
    "$STAGING_DIR/config/autom8.conf"
elif [[ ! -f "$STAGING_DIR/config/autom8.conf" &&
        -f "$STAGING_DIR/config/autom8.conf.example" ]]; then
  sudo cp \
    "$STAGING_DIR/config/autom8.conf.example" \
    "$STAGING_DIR/config/autom8.conf"
fi

sudo mkdir -p \
  "$STAGING_DIR/logs" \
  "$STAGING_DIR/backups" \
  "$STAGING_DIR/reports" \
  "$STAGING_DIR/tmp"

sudo chown -R "$(id -un):$(id -gn)" \
  "$STAGING_DIR/logs" \
  "$STAGING_DIR/backups" \
  "$STAGING_DIR/reports" \
  "$STAGING_DIR/tmp" \
  "$STAGING_DIR/config"

sudo rm -rf "$PREVIOUS_DIR"

if [[ -d "$INSTALL_DIR" ]]; then
  sudo mv "$INSTALL_DIR" "$PREVIOUS_DIR"
fi

sudo mv "$STAGING_DIR" "$INSTALL_DIR"

if ! "$INSTALL_DIR/bin/autom8" --version >/dev/null; then
  echo "ERRO: nova instalação inválida. Restaurando anterior." >&2

  sudo rm -rf "$INSTALL_DIR"

  if [[ -d "$PREVIOUS_DIR" ]]; then
    sudo mv "$PREVIOUS_DIR" "$INSTALL_DIR"
  fi

  exit 1
fi

PATH_ENTRY="${INSTALL_DIR}/bin"

if ! grep -Fq "$PATH_ENTRY" "$HOME/.bashrc" 2>/dev/null; then
  {
    echo
    echo "# AutoM8 - Linux Management Suite"
    printf 'export PATH="%s:%s"\n' "$PATH_ENTRY" "\$PATH"
  } >> "$HOME/.bashrc"
fi

echo "Instalação local concluída."
echo "Versão: $VERSION"
echo "Diretório: $INSTALL_DIR"
