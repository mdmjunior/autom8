#!/usr/bin/env bash

# AutoM8 Apps internal library.
# Este arquivo é carregado por suite/modules/apps.sh.

autom8_apps_remove() {
  autom8_apps_require_catalog || return 1

  local app_id="${1:-}"

  if [[ -z "$app_id" ]]; then
    autom8_error_ui "Informe o ID do app."
    autom8_note "Exemplo: autom8 apps remove git"
    autom8_summary_fail "Remoção sem app"
    return 1
  fi

  if ! autom8_is_supported_or_diagnostic_only; then
    autom8_error_ui "Distro não suportada oficialmente. Remoção de apps bloqueada."
    autom8_summary_fail "Remoção bloqueada em distro não suportada"
    return 1
  fi

  autom8_apps_is_installable "$app_id" || return 1

  
  local packages=()
  local installed_packages=()
  local package_name

  mapfile -t packages < <(autom8_apps_packages_for_current_pm "$app_id")

  if [[ "${#packages[@]}" -eq 0 ]]; then
    autom8_error_ui "Nenhum pacote disponível para '$app_id' usando $AUTOM8_PACKAGE_MANAGER."
    autom8_summary_fail "Pacote não disponível para a distro"
    return 1
  fi

  autom8_header "Apps · remoção" "$app_id"

  autom8_key_value "App" "$app_id"
  autom8_key_value "Gerenciador" "$AUTOM8_PACKAGE_MANAGER"
  autom8_key_value "Pacotes do catálogo" "${packages[*]}"

  echo
  autom8_section "Validação de pacotes instalados"

  for package_name in "${packages[@]}"; do
    if autom8_apps_package_installed "$package_name"; then
      autom8_status_ok "Pacote instalado: $package_name"
      installed_packages+=("$package_name")
    else
      autom8_status_warn "Pacote não instalado: $package_name"
    fi
  done

  if [[ "${#installed_packages[@]}" -eq 0 ]]; then
    echo
    autom8_warn_ui "Nenhum pacote deste app está instalado."
    autom8_summary_warn "Nada para remover: $app_id"
    return 0
  fi

  echo
  autom8_section "Comando previsto"
  autom8_note "$(autom8_apps_remove_command_preview "${installed_packages[@]}")"

  if [[ "${AUTOM8_DRY_RUN:-false}" == "true" ]]; then
    echo
    autom8_success "Simulação concluída. Nada foi removido."
    autom8_summary_ok "Simulação de remoção concluída"
    return 0
  fi

  echo
  autom8_warn_ui "A remoção pode afetar comandos ou aplicativos usados fora do AutoM8."

  if ! autom8_confirm "Deseja remover este app agora?"; then
    autom8_warn_ui "Remoção cancelada pelo usuário."
    autom8_summary_warn "Remoção cancelada"
    autom8_log_warn "apps" "App removal canceled: $app_id"
    return 0
  fi

  autom8_require_admin "remover apps" || {
    autom8_summary_fail "Sem permissão para remover apps"
    return 1
  }

  autom8_log_info "apps" "Removing app: $app_id packages: ${installed_packages[*]}"

  if autom8_apps_remove_packages "${installed_packages[@]}"; then
    autom8_success "App removido: $app_id"
    autom8_summary_ok "App removido: $app_id"
  else
    autom8_error_ui "Falha ao remover app: $app_id"
    autom8_summary_fail "Falha ao remover app: $app_id"
    return 1
  fi
}

autom8_apps_remove_many() {
  autom8_apps_require_catalog || return 1

  local ids=("$@")

  if [[ "${#ids[@]}" -eq 0 ]]; then
    mapfile -t ids < <(autom8_apps_prompt_many_ids "Selecione os apps para remover")
  fi

  if [[ "${#ids[@]}" -eq 0 ]]; then
    autom8_warn_ui "Nenhum app selecionado."
    autom8_summary_warn "Remoção múltipla sem seleção"
    return 0
  fi

  if ! autom8_is_supported_or_diagnostic_only; then
    autom8_error_ui "Distro não suportada oficialmente. Remoção de apps bloqueada."
    autom8_summary_fail "Remoção bloqueada em distro não suportada"
    return 1
  fi

  if ! autom8_apps_validate_ids_installable "${ids[@]}"; then
    autom8_summary_fail "Remoção múltipla bloqueada por status do app"
    return 1
  fi

  autom8_header "Apps · remoção múltipla" "Confirmação única para vários apps."

  autom8_key_value "Gerenciador" "$AUTOM8_PACKAGE_MANAGER"
  autom8_key_value "Apps" "${ids[*]}"

  echo
  if ! autom8_apps_validate_ids_have_packages "${ids[@]}"; then
    autom8_summary_fail "Remoção múltipla bloqueada por app inválido"
    return 1
  fi

  local catalog_packages=()
  local installed_packages=()
  local package_name

  mapfile -t catalog_packages < <(autom8_apps_collect_packages_for_ids "${ids[@]}")

  echo
  autom8_section "Validação de pacotes instalados"

  for package_name in "${catalog_packages[@]}"; do
    if autom8_apps_package_installed "$package_name"; then
      autom8_status_ok "Pacote instalado: $package_name"
      installed_packages+=("$package_name")
    else
      autom8_status_warn "Pacote não instalado: $package_name"
    fi
  done

  if [[ "${#installed_packages[@]}" -eq 0 ]]; then
    echo
    autom8_warn_ui "Nenhum pacote dos apps selecionados está instalado."
    autom8_summary_warn "Nada para remover"
    return 0
  fi

  echo
  autom8_section "Pacotes que serão removidos"
  printf '  - %s\n' "${installed_packages[@]}"

  echo
  autom8_section "Comando previsto"
  autom8_note "$(autom8_apps_remove_command_preview "${installed_packages[@]}")"

  if [[ "${AUTOM8_DRY_RUN:-false}" == "true" ]]; then
    echo
    autom8_success "Simulação concluída. Nada foi removido."
    autom8_summary_ok "Simulação de remoção múltipla concluída"
    return 0
  fi

  echo
  autom8_warn_ui "A remoção pode afetar comandos ou aplicativos usados fora do AutoM8."

  if ! autom8_confirm "Deseja remover estes apps agora?"; then
    autom8_warn_ui "Remoção múltipla cancelada pelo usuário."
    autom8_summary_warn "Remoção múltipla cancelada"
    autom8_log_warn "apps" "Multiple app removal canceled: ${ids[*]}"
    return 0
  fi

  autom8_require_admin "remover vários apps" || {
    autom8_summary_fail "Sem permissão para remover apps"
    return 1
  }

  autom8_log_info "apps" "Removing multiple apps: ${ids[*]} packages: ${installed_packages[*]}"

  if autom8_apps_remove_packages "${installed_packages[@]}"; then
    autom8_success "Apps removidos: ${ids[*]}"
    autom8_summary_ok "Apps removidos: ${ids[*]}"
  else
    autom8_error_ui "Falha ao remover apps: ${ids[*]}"
    autom8_summary_fail "Falha na remoção múltipla"
    return 1
  fi
}
