#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE="$PROJECT_ROOT/dist/autom8-latest.tar.gz"
INSTALL_DIR="/opt/autom8"

if [[ ! -f "$PACKAGE" ]]; then
  echo "Pacote não encontrado: $PACKAGE"
  echo "Execute primeiro: ./scripts/package.sh"
  exit 1
fi

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  echo "Não rode este script como root. Use usuário comum com sudo."
  exit 1
fi

sudo rm -rf "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"
sudo tar -xzf "$PACKAGE" -C "$INSTALL_DIR"
sudo chmod +x "$INSTALL_DIR/bin/autom8"

if [[ ! -f "$INSTALL_DIR/config/autom8.conf" && -f "$INSTALL_DIR/config/autom8.conf.example" ]]; then
  sudo cp "$INSTALL_DIR/config/autom8.conf.example" "$INSTALL_DIR/config/autom8.conf"
fi

sudo mkdir -p "$INSTALL_DIR/logs" "$INSTALL_DIR/backups" "$INSTALL_DIR/reports" "$INSTALL_DIR/tmp"
sudo chown -R "$USER:$USER" "$INSTALL_DIR/logs" "$INSTALL_DIR/backups" "$INSTALL_DIR/reports" "$INSTALL_DIR/tmp" "$INSTALL_DIR/config"

if ! grep -q "/opt/autom8/bin" "$HOME/.bashrc" 2>/dev/null; then
  {
    echo
    echo "# AutoM8 - Linux Management Suite"
    echo 'export PATH="/opt/autom8/bin:$PATH"'
  } >> "$HOME/.bashrc"
fi

echo "Instalação local concluída."
echo 'Execute: export PATH="/opt/autom8/bin:$PATH"'
echo "Depois: autom8"
