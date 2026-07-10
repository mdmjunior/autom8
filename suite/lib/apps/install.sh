#!/usr/bin/env bash

# AutoM8 Apps internal library.
# Este arquivo é carregado por suite/modules/apps.sh.

autom8_apps_install() {
  autom8_apps_require_catalog || return 1

  local app_id="${1:-}"

  if [[ -z "$app_id" ]]; then
    autom8_error_ui "Informe o ID do app."
    autom8_note "Exemplo: autom8 apps install git"
    autom8_summary_fail "Instalação sem app"
    return 1
  fi

  if ! autom8_is_supported_or_diagnostic_only; then
    autom8_error_ui "Distro não suportada oficialmente. Instalação de apps bloqueada."
    autom8_summary_fail "Apps bloqueado em distro não suportada"
    return 1
  fi

  autom8_apps_is_installable "$app_id" || return 1

  local packages=()
  mapfile -t packages < <(autom8_apps_packages_for_current_pm "$app_id")

  if [[ "${#packages[@]}" -eq 0 ]]; then
    autom8_error_ui "Nenhum pacote disponível para '$app_id' usando $AUTOM8_PACKAGE_MANAGER."
    autom8_summary_fail "Pacote não disponível para a distro"
    return 1
  fi

  autom8_header "Apps · instalação" "$app_id"

  autom8_key_value "App" "$app_id"
  autom8_key_value "Gerenciador" "$AUTOM8_PACKAGE_MANAGER"
  autom8_key_value "Pacotes" "${packages[*]}"

  echo
  autom8_section "Comando previsto"
  autom8_note "$(autom8_apps_install_command_preview "${packages[@]}")"

  echo
  if ! autom8_apps_validate_packages_available "${packages[@]}"; then
    autom8_summary_fail "Instalação bloqueada por pacote indisponível"
    return 1
  fi

  if [[ "${AUTOM8_DRY_RUN:-false}" == "true" ]]; then
    echo
    autom8_success "Simulação concluída. Nada foi instalado."
    autom8_summary_ok "Simulação de instalação concluída"
    return 0
  fi

  echo
  if ! autom8_confirm "Deseja instalar este app agora?"; then
    autom8_warn_ui "Instalação cancelada pelo usuário."
    autom8_summary_warn "Instalação cancelada"
    autom8_log_warn "apps" "App install canceled: $app_id"
    return 0
  fi

  autom8_require_admin "instalar apps" || {
    autom8_summary_fail "Sem permissão para instalar apps"
    return 1
  }

  autom8_log_info "apps" "Installing app: $app_id packages: ${packages[*]}"

  if autom8_apps_install_packages "${packages[@]}"; then
    autom8_success "App instalado: $app_id"
    autom8_summary_ok "App instalado: $app_id"
  else
    autom8_error_ui "Falha ao instalar app: $app_id"
    autom8_summary_fail "Falha ao instalar app: $app_id"
    return 1
  fi
}

autom8_apps_install_many() {
  autom8_apps_require_catalog || return 1

  local ids=("$@")

  if [[ "${#ids[@]}" -eq 0 ]]; then
    mapfile -t ids < <(autom8_apps_prompt_many_ids "Selecione os apps para instalar")
  fi

  if [[ "${#ids[@]}" -eq 0 ]]; then
    autom8_warn_ui "Nenhum app selecionado."
    autom8_summary_warn "Instalação múltipla sem seleção"
    return 0
  fi

  if ! autom8_is_supported_or_diagnostic_only; then
    autom8_error_ui "Distro não suportada oficialmente. Instalação de apps bloqueada."
    autom8_summary_fail "Apps bloqueado em distro não suportada"
    return 1
  fi

  if ! autom8_apps_validate_ids_installable "${ids[@]}"; then
    autom8_summary_fail "Instalação múltipla bloqueada por status do app"
    return 1
  fi

  autom8_header "Apps · instalação múltipla" "Confirmação única para vários apps."

  autom8_key_value "Gerenciador" "$AUTOM8_PACKAGE_MANAGER"
  autom8_key_value "Apps" "${ids[*]}"

  echo
  if ! autom8_apps_validate_ids_have_packages "${ids[@]}"; then
    autom8_summary_fail "Instalação múltipla bloqueada por app inválido"
    return 1
  fi

  local packages=()
  mapfile -t packages < <(autom8_apps_collect_packages_for_ids "${ids[@]}")

  if [[ "${#packages[@]}" -eq 0 ]]; then
    autom8_error_ui "Nenhum pacote disponível para os apps selecionados."
    autom8_summary_fail "Instalação múltipla sem pacotes"
    return 1
  fi

  echo
  autom8_section "Pacotes consolidados"
  printf '  - %s\n' "${packages[@]}"

  echo
  autom8_section "Comando previsto"
  autom8_note "$(autom8_apps_install_command_preview "${packages[@]}")"

  echo
  if ! autom8_apps_validate_packages_available "${packages[@]}"; then
    autom8_summary_fail "Instalação múltipla bloqueada por pacote indisponível"
    return 1
  fi

  if [[ "${AUTOM8_DRY_RUN:-false}" == "true" ]]; then
    echo
    autom8_success "Simulação concluída. Nada foi instalado."
    autom8_summary_ok "Simulação de instalação múltipla concluída"
    return 0
  fi

  echo
  if ! autom8_confirm "Deseja instalar estes apps agora?"; then
    autom8_warn_ui "Instalação múltipla cancelada pelo usuário."
    autom8_summary_warn "Instalação múltipla cancelada"
    autom8_log_warn "apps" "Multiple app install canceled: ${ids[*]}"
    return 0
  fi

  autom8_require_admin "instalar vários apps" || {
    autom8_summary_fail "Sem permissão para instalar apps"
    return 1
  }

  autom8_log_info "apps" "Installing multiple apps: ${ids[*]} packages: ${packages[*]}"

  if autom8_apps_install_packages "${packages[@]}"; then
    autom8_success "Apps instalados: ${ids[*]}"
    autom8_summary_ok "Apps instalados: ${ids[*]}"
  else
    autom8_error_ui "Falha ao instalar apps: ${ids[*]}"
    autom8_summary_fail "Falha na instalação múltipla"
    return 1
  fi
}

autom8_apps_install_category() {
  autom8_apps_require_catalog || return 1

  local category="${1:-}"

  if [[ -z "$category" ]]; then
    category="$(autom8_apps_prompt_category "Selecione a categoria para instalar" || true)"
  fi

  if [[ -z "$category" ]]; then
    autom8_warn_ui "Nenhuma categoria selecionada."
    autom8_summary_warn "Instalação por categoria sem seleção"
    return 0
  fi

  if ! autom8_apps_category_exists "$category"; then
    autom8_error_ui "Categoria não encontrada: $category"
    autom8_summary_fail "Categoria não encontrada"
    return 1
  fi

  if ! autom8_is_supported_or_diagnostic_only; then
    autom8_error_ui "Distro não suportada oficialmente. Instalação por categoria bloqueada."
    autom8_summary_fail "Instalação por categoria bloqueada em distro não suportada"
    return 1
  fi

  local ids=()
  local packages=()

  mapfile -t ids < <(autom8_apps_ids_for_category "$category" "available")

  autom8_header "Apps · instalar categoria" "Instalação em lote com confirmação única."

  autom8_key_value "Gerenciador" "$AUTOM8_PACKAGE_MANAGER"
  autom8_apps_print_category_plan "$category" "${ids[@]}"

  if [[ "${#ids[@]}" -eq 0 ]]; then
    echo
    autom8_warn_ui "Nenhum app available encontrado nesta categoria."
    autom8_summary_warn "Categoria sem apps instaláveis"
    return 0
  fi

  echo
  if ! autom8_apps_validate_ids_have_packages "${ids[@]}"; then
    autom8_summary_fail "Instalação por categoria bloqueada por app inválido"
    return 1
  fi

  mapfile -t packages < <(autom8_apps_collect_packages_for_ids "${ids[@]}")

  if [[ "${#packages[@]}" -eq 0 ]]; then
    autom8_error_ui "Nenhum pacote disponível para a categoria selecionada."
    autom8_summary_fail "Instalação por categoria sem pacotes"
    return 1
  fi

  echo
  autom8_section "Pacotes consolidados"
  printf '  - %s\n' "${packages[@]}"

  echo
  autom8_section "Comando previsto"
  autom8_note "$(autom8_apps_install_command_preview "${packages[@]}")"

  echo
  if ! autom8_apps_validate_packages_available "${packages[@]}"; then
    autom8_summary_fail "Instalação por categoria bloqueada por pacote indisponível"
    return 1
  fi

  if [[ "${AUTOM8_DRY_RUN:-false}" == "true" ]]; then
    echo
    autom8_success "Simulação concluída. Nada foi instalado."
    autom8_summary_ok "Simulação de instalação por categoria concluída"
    return 0
  fi

  echo
  if ! autom8_confirm "Deseja instalar os apps available desta categoria agora?"; then
    autom8_warn_ui "Instalação por categoria cancelada pelo usuário."
    autom8_summary_warn "Instalação por categoria cancelada"
    autom8_log_warn "apps" "Category install canceled: $category"
    return 0
  fi

  autom8_require_admin "instalar categoria de apps" || {
    autom8_summary_fail "Sem permissão para instalar categoria"
    return 1
  }

  autom8_log_info "apps" "Installing category: $category apps: ${ids[*]} packages: ${packages[*]}"

  if autom8_apps_install_packages "${packages[@]}"; then
    autom8_success "Categoria instalada: $category"
    autom8_summary_ok "Categoria instalada: $category"
  else
    autom8_error_ui "Falha ao instalar categoria: $category"
    autom8_summary_fail "Falha na instalação por categoria"
    return 1
  fi
}
