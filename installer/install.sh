#!/usr/bin/env bash
set -euo pipefail

AUTOM8_SITE_URL="${AUTOM8_SITE_URL:-https://autom8.oslabs.com.br}"
AUTOM8_GITHUB_REPO="${AUTOM8_GITHUB_REPO:-mdmjunior/autom8}"
AUTOM8_PACKAGE_URL="${AUTOM8_PACKAGE_URL:-https://github.com/${AUTOM8_GITHUB_REPO}/releases/latest/download/autom8-latest.tar.gz}"
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

require_sudo() {
  if ! command -v sudo >/dev/null 2>&1; then
    error "sudo não está instalado. Instale sudo manualmente antes de continuar."
    exit 1
  fi

  if ! sudo -v; then
    error "O usuário atual não conseguiu autenticar com sudo."
    exit 1
  fi
}

detect_os() {
  AUTOM8_OS_NAME="unknown"

  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    AUTOM8_OS_NAME="${PRETTY_NAME:-${NAME:-unknown}}"
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

install_common_deps_apt() {
  sudo apt update
  sudo apt install -y \
    ca-certificates \
    curl \
    wget \
    git \
    tar \
    gzip \
    coreutils \
    findutils \
    gawk \
    sed \
    grep \
    util-linux \
    procps \
    iproute2 \
    net-tools \
    dnsutils \
    sudo \
    jq \
    rsync \
    lsof \
    nmap \
    gnupg \
    unzip \
    xz-utils \
    file \
    tree
}

install_common_deps_dnf() {
  sudo dnf install -y \
    ca-certificates \
    curl \
    wget \
    git \
    tar \
    gzip \
    coreutils \
    findutils \
    gawk \
    sed \
    grep \
    util-linux \
    procps-ng \
    iproute \
    net-tools \
    bind-utils \
    sudo \
    jq \
    rsync \
    lsof \
    nmap \
    gnupg2 \
    unzip \
    xz \
    file \
    tree
}

install_common_deps_zypper() {
  sudo zypper refresh
  sudo zypper install -y \
    ca-certificates \
    curl \
    wget \
    git \
    tar \
    gzip \
    coreutils \
    findutils \
    gawk \
    sed \
    grep \
    util-linux \
    procps \
    iproute2 \
    net-tools \
    bind-utils \
    sudo \
    jq \
    rsync \
    lsof \
    nmap \
    gpg2 \
    unzip \
    xz \
    file \
    tree
}

install_common_deps_pacman() {
  sudo pacman -Sy --needed --noconfirm \
    ca-certificates \
    curl \
    wget \
    git \
    tar \
    gzip \
    coreutils \
    findutils \
    gawk \
    sed \
    grep \
    util-linux \
    procps-ng \
    iproute2 \
    net-tools \
    bind \
    sudo \
    jq \
    rsync \
    lsof \
    nmap \
    gnupg \
    unzip \
    xz \
    file \
    tree
}

install_common_deps() {
  local pm="$1"

  info "Instalando dependências obrigatórias para $AUTOM8_OS_NAME..."

  case "$pm" in
    apt)
      install_common_deps_apt
      ;;
    dnf)
      install_common_deps_dnf
      ;;
    zypper)
      install_common_deps_zypper
      ;;
    pacman)
      install_common_deps_pacman
      ;;
    *)
      error "Gerenciador de pacotes não reconhecido."
      exit 1
      ;;
  esac
}

install_gum_apt() {
  sudo mkdir -p /etc/apt/keyrings

  if [[ ! -f /etc/apt/keyrings/charm.gpg ]]; then
    curl -fsSL https://repo.charm.sh/apt/gpg.key \
      | sudo gpg --dearmor --yes -o /etc/apt/keyrings/charm.gpg
  fi

  echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" \
    | sudo tee /etc/apt/sources.list.d/charm.list >/dev/null

  sudo apt update
  sudo apt install -y gum
}

install_gum_dnf() {
  if sudo dnf install -y gum; then
    return 0
  fi

  warn "gum não foi encontrado no repositório atual. Habilitando repositório Charm."

  cat <<'EOF_REPO' | sudo tee /etc/yum.repos.d/charm.repo >/dev/null
[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key
EOF_REPO

  sudo rpm --import https://repo.charm.sh/yum/gpg.key
  sudo dnf install -y gum
}

install_gum_zypper() {
  if sudo zypper install -y gum; then
    return 0
  fi

  warn "gum não foi encontrado no repositório atual. Habilitando repositório Charm."

  sudo rpm --import https://repo.charm.sh/yum/gpg.key
  sudo zypper addrepo -f https://repo.charm.sh/yum/ charm || true
  sudo zypper refresh
  sudo zypper install -y gum
}

install_gum_pacman() {
  sudo pacman -Sy --needed --noconfirm gum
}

install_gum() {
  local pm="$1"

  if command -v gum >/dev/null 2>&1; then
    info "gum já está instalado."
    return 0
  fi

  info "Instalando gum para interface interativa."

  case "$pm" in
    apt)
      install_gum_apt
      ;;
    dnf)
      install_gum_dnf
      ;;
    zypper)
      install_gum_zypper
      ;;
    pacman)
      install_gum_pacman
      ;;
    *)
      error "Não foi possível instalar gum: gerenciador desconhecido."
      exit 1
      ;;
  esac
}

verify_required_commands() {
  info "Validando dependências instaladas..."

  local missing=0
  local required_commands=(
    bash
    awk
    sed
    grep
    find
    tar
    gzip
    curl
    wget
    git
    sudo
    jq
    rsync
    lsof
    nmap
    ip
    ss
    ifconfig
    netstat
    dig
    nslookup
    unzip
    xz
    file
    tree
    gum
  )

  for cmd in "${required_commands[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
      printf '  [OK] %s\n' "$cmd"
    else
      printf '  [FALHA] %s\n' "$cmd"
      missing=$((missing + 1))
    fi
  done

  if [[ "$missing" -gt 0 ]]; then
    error "Existem $missing dependência(s) obrigatória(s) ausente(s)."
    error "A instalação foi interrompida para evitar uma instalação incompleta."
    exit 1
  fi
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
  local archive
  local extracted_dir
  local found_bin
  local found_root

  tmp_dir="$(mktemp -d)"
  archive="$tmp_dir/autom8.tar.gz"
  extracted_dir="$tmp_dir/extracted"

  info "Baixando pacote do AutoM8."
  info "Origem: $AUTOM8_PACKAGE_URL"

  if ! curl -fL "$AUTOM8_PACKAGE_URL" -o "$archive"; then
    error "Falha ao baixar pacote do AutoM8."
    error "URL: $AUTOM8_PACKAGE_URL"
    rm -rf "$tmp_dir"
    exit 1
  fi

  if ! tar -tzf "$archive" >/dev/null 2>&1; then
    error "Arquivo baixado não é um tar.gz válido."
    error "URL: $AUTOM8_PACKAGE_URL"
    error "Primeiros bytes do arquivo baixado:"
    head -c 200 "$archive" || true
    echo
    rm -rf "$tmp_dir"
    exit 1
  fi

  mkdir -p "$extracted_dir"

  info "Inspecionando pacote baixado."
  tar -tzf "$archive" | sed -n '1,40p'

  tar -xzf "$archive" -C "$extracted_dir"

  found_bin="$(find "$extracted_dir" -maxdepth 5 -type f -path '*/bin/autom8' | head -n 1 || true)"

  if [[ -z "$found_bin" ]]; then
    error "O pacote não contém bin/autom8."
    error "Conteúdo encontrado no pacote:"
    find "$extracted_dir" -maxdepth 4 -print | sed -n '1,120p'
    rm -rf "$tmp_dir"
    exit 1
  fi

  found_root="$(dirname "$(dirname "$found_bin")")"

  info "Raiz detectada do pacote: $found_root"
  info "Instalando em: $AUTOM8_INSTALL_DIR"

  sudo rm -rf "$AUTOM8_INSTALL_DIR"
  sudo mkdir -p "$AUTOM8_INSTALL_DIR"
  sudo rsync -a "$found_root"/ "$AUTOM8_INSTALL_DIR"/

  if [[ ! -f "$AUTOM8_INSTALL_DIR/bin/autom8" ]]; then
    error "Falha ao normalizar instalação."
    error "Executável esperado não encontrado: $AUTOM8_INSTALL_DIR/bin/autom8"
    error "Conteúdo de $AUTOM8_INSTALL_DIR:"
    sudo find "$AUTOM8_INSTALL_DIR" -maxdepth 4 -print | sed -n '1,120p'
    rm -rf "$tmp_dir"
    exit 1
  fi

  sudo chown -R root:root "$AUTOM8_INSTALL_DIR"
  sudo chmod +x "$AUTOM8_INSTALL_DIR/bin/autom8"

  if [[ ! -f "$AUTOM8_INSTALL_DIR/config/autom8.conf" && -f "$AUTOM8_INSTALL_DIR/config/autom8.conf.example" ]]; then
    sudo cp "$AUTOM8_INSTALL_DIR/config/autom8.conf.example" "$AUTOM8_INSTALL_DIR/config/autom8.conf"
  fi

  sudo mkdir -p \
    "$AUTOM8_INSTALL_DIR/logs" \
    "$AUTOM8_INSTALL_DIR/backups" \
    "$AUTOM8_INSTALL_DIR/reports" \
    "$AUTOM8_INSTALL_DIR/tmp" \
    "$AUTOM8_INSTALL_DIR/catalog"

  sudo chown -R "$USER:$USER" \
    "$AUTOM8_INSTALL_DIR/logs" \
    "$AUTOM8_INSTALL_DIR/backups" \
    "$AUTOM8_INSTALL_DIR/reports" \
    "$AUTOM8_INSTALL_DIR/tmp" \
    "$AUTOM8_INSTALL_DIR/config"

  rm -rf "$tmp_dir"
}

add_path_user() {
  local shell_file="$HOME/.bashrc"
  local path_entry="${AUTOM8_INSTALL_DIR}/bin"
  local literal_path="\$PATH"
  local path_line

  printf -v path_line     'export PATH="%s:%s"'     "$path_entry"     "$literal_path"

  if [[ -n "${ZSH_VERSION:-}" || "${SHELL:-}" == *"zsh"* ]]; then
    shell_file="$HOME/.zshrc"
  fi

  touch "$shell_file"

  if ! grep -Fq "$path_entry" "$shell_file" 2>/dev/null; then
    {
      echo
      echo "# AutoM8 - Linux Management Suite"
      printf '%s\n' "$path_line"
    } >> "$shell_file"
  fi

  info "PATH atualizado em: $shell_file"
}

add_path_global() {
  local profile_file="/etc/profile.d/autom8.sh"
  local path_entry="${AUTOM8_INSTALL_DIR}/bin"
  local literal_path="\$PATH"
  local path_line

  printf -v path_line     'export PATH="%s:%s"'     "$path_entry"     "$literal_path"

  printf '%s\n' "$path_line" |
    sudo tee "$profile_file" >/dev/null

  sudo chmod 644 "$profile_file"

  info "PATH global criado em: $profile_file"
}

run_post_install_check() {
  info "Executando validação pós-instalação..."

  if [[ ! -x "$AUTOM8_INSTALL_DIR/bin/autom8" ]]; then
    error "Executável não encontrado ou sem permissão: $AUTOM8_INSTALL_DIR/bin/autom8"
    exit 1
  fi

  "$AUTOM8_INSTALL_DIR/bin/autom8" --version
  "$AUTOM8_INSTALL_DIR/bin/autom8" doctor || {
    warn "O doctor encontrou avisos/falhas. Revise a saída acima."
  }
}

main() {
  require_not_root
  require_sudo
  detect_os

  local pm
  pm="$(detect_pm)"

  info "Iniciando instalação do AutoM8 - Linux Management Suite"
  info "Sistema detectado: $AUTOM8_OS_NAME"
  info "Gerenciador detectado: $pm"

  install_common_deps "$pm"
  install_gum "$pm"
  verify_required_commands
  install_package

  local scope
  scope="$(ask_scope)"

  if [[ "$scope" == "global" ]]; then
    add_path_global
  else
    add_path_user
  fi

  run_post_install_check

  echo
  info "Instalação concluída."
  echo
  local literal_path="\$PATH"

  echo "Para usar agora nesta sessão, execute:"
  printf '  export PATH="%s/bin:%s"\n'     "$AUTOM8_INSTALL_DIR"     "$literal_path"
  echo
  echo "Depois rode:"
  echo "  autom8"
  echo
}

main "$@"
