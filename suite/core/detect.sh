#!/usr/bin/env bash

AUTOM8_DISTRO_ID="unknown"
AUTOM8_DISTRO_NAME="unknown"
AUTOM8_DISTRO_VERSION="unknown"
AUTOM8_PACKAGE_MANAGER="unknown"
AUTOM8_SUPPORTED_DISTRO="false"
AUTOM8_DESKTOP_SESSION="${XDG_CURRENT_DESKTOP:-unknown}"
AUTOM8_SESSION_TYPE="${XDG_SESSION_TYPE:-unknown}"

autom8_detect_distro() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    AUTOM8_DISTRO_ID="${ID:-unknown}"
    AUTOM8_DISTRO_NAME="${PRETTY_NAME:-${NAME:-unknown}}"
    AUTOM8_DISTRO_VERSION="${VERSION_ID:-unknown}"
  fi

  case "$AUTOM8_DISTRO_ID" in
    ubuntu|debian|fedora|rocky|almalinux|opensuse*|arch|manjaro)
      AUTOM8_SUPPORTED_DISTRO="true"
      ;;
    *)
      AUTOM8_SUPPORTED_DISTRO="false"
      ;;
  esac

  if command -v apt >/dev/null 2>&1; then
    AUTOM8_PACKAGE_MANAGER="apt"
  elif command -v dnf >/dev/null 2>&1; then
    AUTOM8_PACKAGE_MANAGER="dnf"
  elif command -v zypper >/dev/null 2>&1; then
    AUTOM8_PACKAGE_MANAGER="zypper"
  elif command -v pacman >/dev/null 2>&1; then
    AUTOM8_PACKAGE_MANAGER="pacman"
  else
    AUTOM8_PACKAGE_MANAGER="unknown"
  fi
}

autom8_is_supported_or_diagnostic_only() {
  [[ "$AUTOM8_SUPPORTED_DISTRO" == "true" ]]
}

autom8_print_detection() {
  cat <<EOF_DETECT
Distro: $AUTOM8_DISTRO_NAME
ID: $AUTOM8_DISTRO_ID
Versão: $AUTOM8_DISTRO_VERSION
Gerenciador: $AUTOM8_PACKAGE_MANAGER
Suportada oficialmente: $AUTOM8_SUPPORTED_DISTRO
Desktop: $AUTOM8_DESKTOP_SESSION
Sessão: $AUTOM8_SESSION_TYPE
EOF_DETECT
}
