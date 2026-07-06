#!/usr/bin/env bash
set -euo pipefail

AUTOM8_SITE_URL="${AUTOM8_SITE_URL:-https://autom8.oslabs.com.br}"
AUTOM8_PACKAGE_URL="${AUTOM8_PACKAGE_URL:-$AUTOM8_SITE_URL/downloads/autom8-latest.tar.gz}"
AUTOM8_INSTALL_DIR="${AUTOM8_INSTALL_DIR:-/opt/autom8}"

info() {
  printf '\033[1;34m[AutoM8]\033[0m %s\n' "$1"
}

warn() {
  printf '\033[1;33m[AutoM8]\033[0m %s\n' "$1"
}

error() {
  printf '\033[1;31m[AutoM8]\033[0m %s\n' "$1" >&2
}

require_not_root() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    error "Não execute este instalador diretamente como root."
    error "Use um usuário comum com sudo."
    exit 1
  fi
}

detect_pm() {
  if command -v apt >/dev/null 2>&1; then
    echo "apt"
  elif command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  elif command -v zypper >/dev/null 2>&1; then
    echo "zypper"
  elif command -v pacman >/dev/null 2>&1; then
    echo "pacman"
  else
    echo "unknown"
  fi
}

install_deps() {
  local pm="$1"

  info "Instalando dependências essenciais..."

  case "$pm" in
    apt)
      sudo apt update
      sudo apt install -y curl tar gzip coreutils findutils gawk sed grep util-linux procps iproute2 sudo
      if ! command -v gum >/dev/null 2>&1; then
        warn "gum não encontrado nos repositórios padrão. O AutoM8 funcionará com fallback simples."
      fi
      ;;
    dnf)
      sudo dnf install -y curl tar gzip coreutils findutils gawk sed grep util-linux procps-ng iproute sudo
      if ! command -v gum >/dev/null 2>&1; then
        sudo dnf install -y gum || warn "Não foi possível instalar gum. O AutoM8 usará fallback simples."
      fi
      ;;
    zypper)
      sudo zypper refresh
      sudo zypper install -y curl tar gzip coreutils findutils gawk sed grep util-linux procps iproute2 sudo
      if ! command -v gum >/dev/null 2>&1; then
        sudo zypper install -y gum || warn "Não foi possível instalar gum. O AutoM8 usará fallback simples."
      fi
      ;;
    pacman)
      sudo pacman -Sy --needed --noconfirm curl tar gzip coreutils findutils gawk sed grep util-linux procps-ng iproute2 sudo
      if ! command -v gum >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm gum || warn "Não foi possível instalar gum. O AutoM8 usará fallback simples."
      fi
      ;;
    *)
      error "Gerenciador de pacotes não reconhecido."
      exit 1
      ;;
  esac
}

ask_scope() {
  echo
  echo "Como deseja disponibilizar o comando autom8?"
  echo "1) Apenas para o usuário atual"
  echo "2) Para todos os usuários"
  echo

  read -r -p "Escolha [1/2]: " scope

  case "$scope" in
    2) echo "global" ;;
    *) echo "user" ;;
  esac
}

install_package() {
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  info "Baixando pacote: $AUTOM8_PACKAGE_URL"
  curl -fsSL "$AUTOM8_PACKAGE_URL" -o "$tmp_dir/autom8.tar.gz"

  info "Instalando em: $AUTOM8_INSTALL_DIR"
  sudo mkdir -p "$AUTOM8_INSTALL_DIR"
  sudo tar -xzf "$tmp_dir/autom8.tar.gz" -C "$AUTOM8_INSTALL_DIR"
  sudo chown -R root:root "$AUTOM8_INSTALL_DIR"
  sudo chmod +x "$AUTOM8_INSTALL_DIR/bin/autom8"

  if [[ ! -f "$AUTOM8_INSTALL_DIR/config/autom8.conf" && -f "$AUTOM8_INSTALL_DIR/config/autom8.conf.example" ]]; then
    sudo cp "$AUTOM8_INSTALL_DIR/config/autom8.conf.example" "$AUTOM8_INSTALL_DIR/config/autom8.conf"
  fi

  sudo mkdir -p "$AUTOM8_INSTALL_DIR/logs" "$AUTOM8_INSTALL_DIR/backups" "$AUTOM8_INSTALL_DIR/reports" "$AUTOM8_INSTALL_DIR/tmp"
  sudo chown -R "$USER:$USER" "$AUTOM8_INSTALL_DIR/logs" "$AUTOM8_INSTALL_DIR/backups" "$AUTOM8_INSTALL_DIR/reports" "$AUTOM8_INSTALL_DIR/tmp" "$AUTOM8_INSTALL_DIR/config"

  rm -rf "$tmp_dir"
}

add_path_user() {
  local shell_file="$HOME/.bashrc"

  if [[ -n "${ZSH_VERSION:-}" || "${SHELL:-}" == *"zsh"* ]]; then
    shell_file="$HOME/.zshrc"
  fi

  if ! grep -q "/opt/autom8/bin" "$shell_file" 2>/dev/null; then
    {
      echo
      echo "# AutoM8 - Linux Management Suite"
      echo 'export PATH="/opt/autom8/bin:$PATH"'
    } >> "$shell_file"
  fi

  info "PATH atualizado em: $shell_file"
}

add_path_global() {
  local profile_file="/etc/profile.d/autom8.sh"

  echo 'export PATH="/opt/autom8/bin:$PATH"' | sudo tee "$profile_file" >/dev/null
  sudo chmod 644 "$profile_file"

  info "PATH global criado em: $profile_file"
}

main() {
  require_not_root

  info "Iniciando instalação do AutoM8 - Linux Management Suite"

  local pm
  pm="$(detect_pm)"

  info "Gerenciador detectado: $pm"

  install_deps "$pm"
  install_package

  local scope
  scope="$(ask_scope)"

  if [[ "$scope" == "global" ]]; then
    add_path_global
  else
    add_path_user
  fi

  echo
  info "Instalação concluída."
  echo
  echo "Para usar agora nesta sessão, execute:"
  echo '  export PATH="/opt/autom8/bin:$PATH"'
  echo
  echo "Depois rode:"
  echo "  autom8"
  echo
}

main "$@"
