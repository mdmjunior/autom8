#!/usr/bin/env bash

autom8_clean_is_dry_run() {
  local arg

  if [[ "${AUTOM8_DRY_RUN:-false}" == "true" ]]; then
    return 0
  fi

  for arg in "$@"; do
    if [[ "$arg" == "--dry-run" ]]; then
      return 0
    fi
  done

  return 1
}

autom8_clean_package_cache() {
  case "$AUTOM8_PACKAGE_MANAGER" in
    apt)
      autom8_sudo "limpar cache APT" apt clean || return 1
      autom8_sudo "remover pacotes órfãos APT" apt autoremove -y || return 1
      ;;
    dnf)
      autom8_sudo "limpar cache DNF" dnf clean all || return 1
      autom8_sudo "remover pacotes não utilizados DNF" dnf autoremove -y || true
      ;;
    zypper)
      autom8_sudo "limpar cache Zypper" zypper clean --all || return 1
      ;;
    pacman)
      autom8_sudo "limpar cache Pacman mantendo versões recentes" pacman -Sc --noconfirm || true
      ;;
    *)
      autom8_warn_ui "Gerenciador de pacotes desconhecido. Pulando cache de pacotes."
      autom8_summary_warn "Cache de pacotes ignorado"
      ;;
  esac
}

autom8_clean_system_tmp() {
  autom8_sudo "limpar temporários antigos de /tmp" \
    find /tmp -mindepth 1 -xdev -type f -mtime +7 -print -delete || true

  autom8_sudo "limpar temporários antigos de /var/tmp" \
    find /var/tmp -mindepth 1 -xdev -type f -mtime +14 -print -delete || true
}

autom8_clean_old_logs() {
  autom8_sudo "limpar logs antigos rotacionados" \
    find /var/log -type f \
      \( -name "*.gz" -o -name "*.old" -o -name "*.1" -o -name "*.2" -o -name "*.3" -o -name "*.4" -o -name "*.5" \) \
      -mtime +7 \
      -print \
      -delete || true
}

autom8_clean_user_cache_safe() {
  autom8_section "Limpeza de cache/temp de usuários"

  awk -F: '($7 !~ /(nologin|false)$/ && $6 ~ /^\//) {print $1 ":" $6}' /etc/passwd | while IFS=: read -r username home_dir; do
    [[ -d "$home_dir" ]] || continue

    autom8_note "Usuário: $username | Home: $home_dir"
    autom8_log_info "clean" "Cleaning safe user cache for $username at $home_dir"

    if [[ -d "$home_dir/.cache" ]]; then
      sudo -u "$username" find "$home_dir/.cache" \
        -mindepth 1 \
        -type f \
        -mtime +7 \
        ! -path "$home_dir/.cache/mozilla/*" \
        ! -path "$home_dir/.cache/google-chrome/*" \
        ! -path "$home_dir/.cache/chromium/*" \
        ! -path "$home_dir/.cache/BraveSoftware/*" \
        ! -path "$home_dir/.cache/microsoft-edge/*" \
        -print \
        -delete 2>/dev/null || true
    fi

    if [[ -d "$home_dir/.local/share/Trash/files" ]]; then
      sudo -u "$username" find "$home_dir/.local/share/Trash/files" -mindepth 1 -mtime +30 -print -delete 2>/dev/null || true
    fi

    if [[ -d "$home_dir/.local/share/Trash/info" ]]; then
      sudo -u "$username" find "$home_dir/.local/share/Trash/info" -mindepth 1 -mtime +30 -print -delete 2>/dev/null || true
    fi
  done
}

autom8_clean_flatpak() {
  if command -v flatpak >/dev/null 2>&1; then
    autom8_note "Flatpak encontrado. Removendo runtimes não utilizados."
    autom8_sudo "remover Flatpak não utilizado" flatpak uninstall --unused -y || true
  else
    autom8_note "Flatpak não encontrado."
  fi
}

autom8_clean_snap() {
  if command -v snap >/dev/null 2>&1; then
    autom8_note "Snap encontrado. Listando revisões instaladas."
    snap list --all 2>/dev/null || true
    autom8_warn_ui "Remoção automática de revisões antigas do Snap ficará para limpeza avançada futura."
    autom8_summary_warn "Snap listado sem remoção automática"
  else
    autom8_note "Snap não encontrado."
  fi
}

autom8_clean_print_planned_actions() {
  autom8_section "Ações previstas"

  case "$AUTOM8_PACKAGE_MANAGER" in
    apt)
      autom8_status_ok "apt clean"
      autom8_status_ok "apt autoremove -y"
      ;;
    dnf)
      autom8_status_ok "dnf clean all"
      autom8_status_ok "dnf autoremove -y"
      ;;
    zypper)
      autom8_status_ok "zypper clean --all"
      ;;
    pacman)
      autom8_status_ok "pacman -Sc --noconfirm"
      ;;
    *)
      autom8_status_warn "Cache de pacotes ignorado: gerenciador desconhecido"
      ;;
  esac

  autom8_status_ok "remover temporários antigos de /tmp"
  autom8_status_ok "remover temporários antigos de /var/tmp"
  autom8_status_ok "remover logs rotacionados antigos"
  autom8_status_ok "limpar caches seguros de usuários"
  autom8_status_ok "verificar Flatpak quando disponível"
  autom8_status_warn "Snap será listado, mas não terá revisões removidas automaticamente"

  echo
  autom8_note "Documentos pessoais não serão removidos."
  autom8_note "Caches de navegadores conhecidos serão preservados."
}

autom8_clean_preview() {
  autom8_header "Limpeza segura · simulação" "Nada será removido neste modo."

  autom8_key_value "Gerenciador detectado" "$AUTOM8_PACKAGE_MANAGER"
  echo

  autom8_clean_print_planned_actions

  echo
  autom8_section "Prévia de arquivos temporários antigos em /tmp"
  find /tmp -mindepth 1 -xdev -type f -mtime +7 -print 2>/dev/null | head -n 30 || true

  echo
  autom8_section "Prévia de arquivos temporários antigos em /var/tmp"
  find /var/tmp -mindepth 1 -xdev -type f -mtime +14 -print 2>/dev/null | head -n 30 || true

  echo
  autom8_section "Prévia de logs rotacionados antigos em /var/log"
  find /var/log -type f \
    \( -name "*.gz" -o -name "*.old" -o -name "*.1" -o -name "*.2" -o -name "*.3" -o -name "*.4" -o -name "*.5" \) \
    -mtime +7 \
    -print 2>/dev/null | head -n 30 || true

  echo
  autom8_section "Usuários com login permitido e homes"
  awk -F: '($7 !~ /(nologin|false)$/ && $6 ~ /^\//) {print "  - " $1 " -> " $6}' /etc/passwd

  echo
  autom8_log_info "clean" "Dry-run safe clean executed"
  autom8_summary_ok "Simulação de limpeza segura concluída"
}

autom8_module_clean() {
  autom8_header "Limpeza segura do sistema" "Remove apenas caches, temporários antigos e resíduos controlados."

  if ! autom8_is_supported_or_diagnostic_only; then
    autom8_error_ui "Distro não suportada oficialmente. Apenas diagnóstico está liberado."
    autom8_summary_fail "Limpeza bloqueada em distro não suportada"
    return 1
  fi

  if autom8_clean_is_dry_run "$@"; then
    autom8_clean_preview
    return 0
  fi

  autom8_require_admin "limpar o sistema" || {
    autom8_summary_fail "Sem permissão para limpeza"
    return 1
  }

  autom8_clean_print_planned_actions

  echo
  if ! autom8_confirm "Deseja executar a limpeza segura agora?"; then
    autom8_warn_ui "Limpeza cancelada pelo usuário."
    autom8_log_warn "clean" "Safe clean canceled by user"
    autom8_summary_warn "Limpeza cancelada"
    return 0
  fi

  echo
  autom8_section "Executando limpeza"
  autom8_log_info "clean" "Starting safe clean"

  autom8_clean_package_cache || autom8_summary_fail "Falha ao limpar cache de pacotes"
  autom8_clean_system_tmp || autom8_summary_fail "Falha ao limpar temporários do sistema"
  autom8_clean_old_logs || autom8_summary_fail "Falha ao limpar logs antigos"
  autom8_clean_flatpak || true
  autom8_clean_snap || true
  autom8_clean_user_cache_safe || true

  autom8_success "Limpeza segura concluída."
  autom8_log_info "clean" "Safe clean completed"
  autom8_summary_ok "Limpeza segura concluída"
}
