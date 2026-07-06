#!/usr/bin/env bash

autom8_update_apt() {
  autom8_sudo "atualizar repositórios APT" apt update || return 1

  if [[ "${AUTOM8_DRY_RUN:-false}" == "true" ]]; then
    apt list --upgradable 2>/dev/null || true
    return 0
  fi

  autom8_sudo "atualizar pacotes APT" apt upgrade -y
}

autom8_update_dnf() {
  if [[ "${AUTOM8_DRY_RUN:-false}" == "true" ]]; then
    dnf check-update || true
    return 0
  fi

  autom8_sudo "atualizar pacotes DNF" dnf upgrade -y
}

autom8_update_zypper() {
  autom8_sudo "atualizar repositórios Zypper" zypper refresh || return 1

  if [[ "${AUTOM8_DRY_RUN:-false}" == "true" ]]; then
    zypper list-updates || true
    return 0
  fi

  autom8_sudo "atualizar pacotes Zypper" zypper update -y
}

autom8_update_pacman() {
  if [[ "${AUTOM8_DRY_RUN:-false}" == "true" ]]; then
    pacman -Qu || true
    return 0
  fi

  autom8_sudo "atualizar pacotes Pacman" pacman -Syu --noconfirm
}

autom8_module_update() {
  autom8_title "Atualização do sistema"

  if ! autom8_is_supported_or_diagnostic_only; then
    autom8_error_ui "Distro não suportada oficialmente. Apenas diagnóstico está liberado."
    autom8_summary_fail "Atualização bloqueada em distro não suportada"
    return 1
  fi

  autom8_require_admin "atualizar o sistema" || {
    autom8_summary_fail "Sem permissão para atualizar"
    return 1
  }

  if [[ "${AUTOM8_DRY_RUN:-false}" != "true" ]]; then
    autom8_confirm "Deseja atualizar os pacotes do sistema agora?" || {
      autom8_warn_ui "Atualização cancelada pelo usuário."
      autom8_log_warn "updates" "System update canceled by user"
      autom8_summary_warn "Atualização cancelada"
      return 0
    }
  fi

  autom8_log_info "updates" "Starting system update using $AUTOM8_PACKAGE_MANAGER"

  case "$AUTOM8_PACKAGE_MANAGER" in
    apt) autom8_update_apt ;;
    dnf) autom8_update_dnf ;;
    zypper) autom8_update_zypper ;;
    pacman) autom8_update_pacman ;;
    *)
      autom8_error_ui "Gerenciador de pacotes não reconhecido."
      autom8_log_error "updates" "Unknown package manager"
      autom8_summary_fail "Gerenciador de pacotes desconhecido"
      return 1
      ;;
  esac

  local status=$?

  if [[ "$status" -eq 0 ]]; then
    autom8_success "Atualização concluída."
    autom8_log_info "updates" "System update completed"
    autom8_summary_ok "Sistema atualizado"
  else
    autom8_error_ui "Atualização terminou com erro."
    autom8_log_error "updates" "System update failed"
    autom8_summary_fail "Atualização com erro"
  fi

  return "$status"
}
