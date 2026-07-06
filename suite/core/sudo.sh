#!/usr/bin/env bash

AUTOM8_CAN_SUDO="false"
AUTOM8_READ_ONLY="false"

autom8_block_root() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    autom8_error_ui "Não execute o AutoM8 diretamente como root. Use um usuário comum com sudo."
    autom8_log_error "security" "Execution blocked because user is root"
    exit 1
  fi
}

autom8_detect_sudo() {
  if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
    AUTOM8_CAN_SUDO="true"
    AUTOM8_READ_ONLY="false"
    return 0
  fi

  if groups "$USER" 2>/dev/null | grep -Eq '\b(sudo|wheel|admin)\b'; then
    AUTOM8_CAN_SUDO="true"
    AUTOM8_READ_ONLY="false"
    return 0
  fi

  AUTOM8_CAN_SUDO="false"
  AUTOM8_READ_ONLY="true"
}

autom8_require_admin() {
  local action="${1:-esta ação}"

  if [[ "$AUTOM8_READ_ONLY" == "true" || "$AUTOM8_CAN_SUDO" != "true" ]]; then
    autom8_error_ui "Modo somente leitura: o usuário atual não tem permissão sudo para executar $action."
    autom8_log_error "security" "Admin action blocked: $action"
    return 1
  fi

  return 0
}

autom8_sudo() {
  local action="$1"
  shift

  autom8_require_admin "$action" || return 1

  autom8_log_info "actions" "Running admin action: $action"
  sudo "$@"
}
