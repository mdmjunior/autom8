#!/usr/bin/env bash

autom8_apps_catalog_file() {
  if [[ -f "$AUTOM8_APPS_CATALOG_CACHE" ]]; then
    printf '%s\n' "$AUTOM8_APPS_CATALOG_CACHE"
  else
    printf '%s\n' "$AUTOM8_APPS_CATALOG_FILE"
  fi
}

autom8_apps_require_catalog() {
  local catalog
  catalog="$(autom8_apps_catalog_file)"

  if [[ ! -f "$catalog" ]]; then
    autom8_error_ui "Catálogo de apps não encontrado: $catalog"
    autom8_summary_fail "Catálogo de apps ausente"
    return 1
  fi

  if ! jq empty "$catalog" >/dev/null 2>&1; then
    autom8_error_ui "Catálogo de apps inválido: $catalog"
    autom8_summary_fail "Catálogo de apps inválido"
    return 1
  fi

  return 0
}

autom8_apps_pm_key() {
  case "$AUTOM8_PACKAGE_MANAGER" in
    apt|dnf|zypper|pacman)
      printf '%s\n' "$AUTOM8_PACKAGE_MANAGER"
      ;;
    *)
      printf 'unknown\n'
      ;;
  esac
}

autom8_apps_list() {
  autom8_apps_require_catalog || return 1

  local catalog
  catalog="$(autom8_apps_catalog_file)"

  autom8_header "Apps" "Catálogo local de aplicativos."

  autom8_key_value "Catálogo" "$catalog"
  autom8_key_value "Versão" "$(jq -r '.version // "unknown"' "$catalog")"
  autom8_key_value "Gerenciador" "$AUTOM8_PACKAGE_MANAGER"

  echo
  autom8_section "Disponíveis"

  jq -r '
    .apps[]
    | "  " + (.id | .[0:18]) + " | " + (.name | .[0:28]) + " | " + (.category // "uncategorized") + " | " + (.summary // "")
  ' "$catalog"

  autom8_summary_ok "Catálogo listado"
}

autom8_apps_search() {
  autom8_apps_require_catalog || return 1

  local query="${1:-}"

  if [[ -z "$query" ]]; then
    autom8_error_ui "Informe um termo de busca."
    autom8_note "Exemplo: autom8 apps search docker"
    autom8_summary_fail "Busca sem termo"
    return 1
  fi

  local catalog
  catalog="$(autom8_apps_catalog_file)"

  autom8_header "Apps · busca" "Termo: $query"

  jq -r --arg q "${query,,}" '
    .apps[]
    | select(
        (.id | ascii_downcase | contains($q))
        or (.name | ascii_downcase | contains($q))
        or (.summary | ascii_downcase | contains($q))
        or ((.tags // []) | join(" ") | ascii_downcase | contains($q))
      )
    | "  " + .id + " | " + .name + " | " + (.summary // "")
  ' "$catalog"

  autom8_summary_ok "Busca executada"
}

autom8_apps_show() {
  autom8_apps_require_catalog || return 1

  local app_id="${1:-}"

  if [[ -z "$app_id" ]]; then
    autom8_error_ui "Informe o ID do app."
    autom8_note "Exemplo: autom8 apps show git"
    autom8_summary_fail "Detalhes sem app"
    return 1
  fi

  local catalog
  local exists
  local pm_key

  catalog="$(autom8_apps_catalog_file)"
  pm_key="$(autom8_apps_pm_key)"

  exists="$(jq -r --arg id "$app_id" '.apps[] | select(.id == $id) | .id' "$catalog" | head -n 1)"

  if [[ -z "$exists" ]]; then
    autom8_error_ui "App não encontrado no catálogo: $app_id"
    autom8_summary_fail "App não encontrado"
    return 1
  fi

  autom8_header "Apps · detalhes" "$app_id"

  autom8_key_value "ID" "$(jq -r --arg id "$app_id" '.apps[] | select(.id == $id) | .id' "$catalog")"
  autom8_key_value "Nome" "$(jq -r --arg id "$app_id" '.apps[] | select(.id == $id) | .name' "$catalog")"
  autom8_key_value "Categoria" "$(jq -r --arg id "$app_id" '.apps[] | select(.id == $id) | .category // "uncategorized"' "$catalog")"
  autom8_key_value "Resumo" "$(jq -r --arg id "$app_id" '.apps[] | select(.id == $id) | .summary // ""' "$catalog")"

  echo
  autom8_section "Pacotes para $AUTOM8_PACKAGE_MANAGER"

  if [[ "$pm_key" == "unknown" ]]; then
    autom8_status_warn "Gerenciador não suportado para instalação automática"
  else
    jq -r --arg id "$app_id" --arg pm "$pm_key" '
      .apps[]
      | select(.id == $id)
      | (.packages[$pm] // [])
      | .[]
      | "  - " + .
    ' "$catalog"
  fi

  echo
  autom8_section "Notas"
  jq -r --arg id "$app_id" '
    .apps[]
    | select(.id == $id)
    | (.notes // ["Sem notas adicionais."])
    | .[]
    | "  - " + .
  ' "$catalog"

  autom8_summary_ok "Detalhes exibidos"
}

autom8_apps_packages_for_current_pm() {
  local app_id="$1"
  local catalog
  local pm_key

  catalog="$(autom8_apps_catalog_file)"
  pm_key="$(autom8_apps_pm_key)"

  if [[ "$pm_key" == "unknown" ]]; then
    return 1
  fi

  jq -r --arg id "$app_id" --arg pm "$pm_key" '
    .apps[]
    | select(.id == $id)
    | (.packages[$pm] // [])
    | .[]
  ' "$catalog"
}

autom8_apps_install_command_preview() {
  local packages=("$@")

  case "$AUTOM8_PACKAGE_MANAGER" in
    apt)
      printf 'sudo apt update && sudo apt install -y %s\n' "${packages[*]}"
      ;;
    dnf)
      printf 'sudo dnf install -y %s\n' "${packages[*]}"
      ;;
    zypper)
      printf 'sudo zypper install -y %s\n' "${packages[*]}"
      ;;
    pacman)
      printf 'sudo pacman -Sy --needed --noconfirm %s\n' "${packages[*]}"
      ;;
    *)
      printf 'Gerenciador não suportado\n'
      ;;
  esac
}

autom8_apps_install_packages() {
  local packages=("$@")

  case "$AUTOM8_PACKAGE_MANAGER" in
    apt)
      autom8_sudo "atualizar índice APT" apt update || return 1
      autom8_sudo "instalar apps via APT" apt install -y "${packages[@]}" || return 1
      ;;
    dnf)
      autom8_sudo "instalar apps via DNF" dnf install -y "${packages[@]}" || return 1
      ;;
    zypper)
      autom8_sudo "instalar apps via Zypper" zypper install -y "${packages[@]}" || return 1
      ;;
    pacman)
      autom8_sudo "instalar apps via Pacman" pacman -Sy --needed --noconfirm "${packages[@]}" || return 1
      ;;
    *)
      autom8_error_ui "Gerenciador de pacotes não suportado para apps: $AUTOM8_PACKAGE_MANAGER"
      return 1
      ;;
  esac
}

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

  if [[ "${AUTOM8_DRY_RUN:-false}" == "true" ]]; then
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

autom8_apps_update_catalog() {
  autom8_header "Apps · atualizar catálogo" "Baixa a versão mais recente do catálogo do repositório."

  if ! command -v curl >/dev/null 2>&1; then
    autom8_error_ui "curl não encontrado."
    autom8_summary_fail "Não foi possível atualizar catálogo"
    return 1
  fi

  mkdir -p "$AUTOM8_TMP_DIR"

  autom8_key_value "Origem" "$AUTOM8_APPS_CATALOG_URL"
  autom8_key_value "Destino" "$AUTOM8_APPS_CATALOG_CACHE"

  echo
  if ! autom8_confirm "Deseja baixar o catálogo atualizado agora?"; then
    autom8_warn_ui "Atualização de catálogo cancelada."
    autom8_summary_warn "Atualização de catálogo cancelada"
    return 0
  fi

  if ! curl -fsSL --connect-timeout 5 --max-time 20 "$AUTOM8_APPS_CATALOG_URL" -o "$AUTOM8_APPS_CATALOG_CACHE.tmp"; then
    rm -f "$AUTOM8_APPS_CATALOG_CACHE.tmp"
    autom8_error_ui "Falha ao baixar catálogo."
    autom8_summary_fail "Falha ao baixar catálogo"
    return 1
  fi

  if ! jq empty "$AUTOM8_APPS_CATALOG_CACHE.tmp" >/dev/null 2>&1; then
    rm -f "$AUTOM8_APPS_CATALOG_CACHE.tmp"
    autom8_error_ui "Catálogo baixado é inválido."
    autom8_summary_fail "Catálogo inválido"
    return 1
  fi

  mv "$AUTOM8_APPS_CATALOG_CACHE.tmp" "$AUTOM8_APPS_CATALOG_CACHE"

  autom8_success "Catálogo atualizado."
  autom8_summary_ok "Catálogo atualizado"
  autom8_log_info "apps" "Apps catalog updated from $AUTOM8_APPS_CATALOG_URL"
}

autom8_apps_menu() {
  while true; do
    clear || true
    autom8_header "Apps" "Instalação por catálogo local atualizável."

    local choice
    choice="$(autom8_choose "O que deseja fazer?" \
      "Listar apps" \
      "Buscar app" \
      "Ver detalhes" \
      "Instalar app" \
      "Atualizar catálogo" \
      "Voltar")" || return 0

    clear || true

    case "$choice" in
      "Listar apps")
        autom8_apps_list
        ;;
      "Buscar app")
        local query
        if autom8_has_gum; then
          query="$(gum input --placeholder "Termo de busca")"
        else
          read -r -p "Termo de busca: " query
        fi
        autom8_apps_search "$query"
        ;;
      "Ver detalhes")
        local app_id
        if autom8_has_gum; then
          app_id="$(gum input --placeholder "ID do app")"
        else
          read -r -p "ID do app: " app_id
        fi
        autom8_apps_show "$app_id"
        ;;
      "Instalar app")
        local install_id
        if autom8_has_gum; then
          install_id="$(gum input --placeholder "ID do app")"
        else
          read -r -p "ID do app: " install_id
        fi
        autom8_apps_install "$install_id"
        ;;
      "Atualizar catálogo")
        autom8_apps_update_catalog
        ;;
      "Voltar")
        return 0
        ;;
    esac

    echo
    autom8_print_summary
    echo
    autom8_pause
    autom8_reset_summary
  done
}

autom8_module_apps() {
  local action="${1:-menu}"
  shift || true

  case "$action" in
    menu|"")
      autom8_apps_menu
      ;;
    list)
      autom8_apps_list "$@"
      ;;
    search)
      autom8_apps_search "$@"
      ;;
    show)
      autom8_apps_show "$@"
      ;;
    install)
      autom8_apps_install "$@"
      ;;
    update-catalog)
      autom8_apps_update_catalog "$@"
      ;;
    *)
      autom8_error_ui "Ação desconhecida em apps: $action"
      autom8_note "Uso: autom8 apps [list|search|show|install|update-catalog]"
      autom8_summary_fail "Ação de apps desconhecida"
      return 1
      ;;
  esac
}
