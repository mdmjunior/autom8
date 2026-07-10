#!/usr/bin/env bash

autom8_profiles_catalog_file() {
  printf '%s\n' "$AUTOM8_CATALOG_DIR/profiles.json"
}

autom8_profiles_require_catalog() {
  local catalog
  catalog="$(autom8_profiles_catalog_file)"

  if [[ ! -f "$catalog" ]]; then
    autom8_error_ui "Catálogo de perfis não encontrado: $catalog"
    autom8_summary_fail "Catálogo de perfis ausente"
    return 1
  fi

  if ! jq empty "$catalog" >/dev/null 2>&1; then
    autom8_error_ui "Catálogo de perfis inválido: $catalog"
    autom8_summary_fail "Catálogo de perfis inválido"
    return 1
  fi

  return 0
}

autom8_profiles_all_ids() {
  local catalog
  catalog="$(autom8_profiles_catalog_file)"

  jq -r '.profiles[].id' "$catalog"
}

autom8_profiles_exists() {
  local profile_id="$1"
  local catalog
  catalog="$(autom8_profiles_catalog_file)"

  jq -e --arg id "$profile_id" '
    .profiles[]
    | select(.id == $id)
  ' "$catalog" >/dev/null
}

autom8_profiles_apps() {
  local profile_id="$1"
  local catalog
  catalog="$(autom8_profiles_catalog_file)"

  jq -r --arg id "$profile_id" '
    .profiles[]
    | select(.id == $id)
    | .apps[]
  ' "$catalog"
}

autom8_profiles_prompt_id() {
  local placeholder="${1:-Perfil}"

  autom8_profiles_require_catalog || return 1

  if autom8_has_gum; then
    autom8_profiles_all_ids | gum choose --header "$placeholder" --height 12
  else
    local profile_id
    read -r -p "$placeholder: " profile_id
    printf '%s\n' "$profile_id"
  fi
}

autom8_profiles_list() {
  autom8_profiles_require_catalog || return 1

  local catalog
  catalog="$(autom8_profiles_catalog_file)"

  autom8_header "Perfis" "Perfis baseados no catálogo de apps."

  autom8_key_value "Catálogo" "$catalog"
  autom8_key_value "Versão" "$(jq -r '.version // "unknown"' "$catalog")"

  echo
  autom8_section "Disponíveis"

  jq -r '
    .profiles[]
    | "  " + .id + " | " + .name + " | " + (.summary // "")
  ' "$catalog"

  autom8_summary_ok "Perfis listados"
}

autom8_profiles_show() {
  autom8_profiles_require_catalog || return 1

  local profile_id="${1:-}"

  if [[ -z "$profile_id" ]]; then
    autom8_error_ui "Informe o ID do perfil."
    autom8_note "Exemplo: autom8 profiles show dev-essential"
    autom8_summary_fail "Detalhes sem perfil"
    return 1
  fi

  if ! autom8_profiles_exists "$profile_id"; then
    autom8_error_ui "Perfil não encontrado: $profile_id"
    autom8_summary_fail "Perfil não encontrado"
    return 1
  fi

  local catalog
  catalog="$(autom8_profiles_catalog_file)"

  autom8_header "Perfis · detalhes" "$profile_id"

  autom8_key_value "ID" "$(jq -r --arg id "$profile_id" '.profiles[] | select(.id == $id) | .id' "$catalog")"
  autom8_key_value "Nome" "$(jq -r --arg id "$profile_id" '.profiles[] | select(.id == $id) | .name' "$catalog")"
  autom8_key_value "Categoria" "$(jq -r --arg id "$profile_id" '.profiles[] | select(.id == $id) | .category // "sem-categoria"' "$catalog")"
  autom8_key_value "Resumo" "$(jq -r --arg id "$profile_id" '.profiles[] | select(.id == $id) | .summary // ""' "$catalog")"

  echo
  autom8_section "Apps"

  while IFS= read -r app_id; do
    [[ -n "$app_id" ]] || continue
    autom8_apps_show "$app_id"
    echo
  done < <(autom8_profiles_apps "$profile_id")

  autom8_summary_ok "Detalhes do perfil exibidos"
}

autom8_profiles_install() {
  autom8_profiles_require_catalog || return 1
  autom8_apps_require_catalog || return 1

  local profile_id="${1:-}"

  if [[ -z "$profile_id" ]]; then
    profile_id="$(autom8_profiles_prompt_id "Selecione o perfil para instalar" || true)"
  fi

  if [[ -z "$profile_id" ]]; then
    autom8_warn_ui "Nenhum perfil selecionado."
    autom8_summary_warn "Instalação de perfil sem seleção"
    return 0
  fi

  if ! autom8_profiles_exists "$profile_id"; then
    autom8_error_ui "Perfil não encontrado: $profile_id"
    autom8_summary_fail "Perfil não encontrado"
    return 1
  fi

  local ids=()
  mapfile -t ids < <(autom8_profiles_apps "$profile_id")

  autom8_header "Perfis · instalação" "$profile_id"
  autom8_key_value "Apps" "${ids[*]}"

  if [[ "${#ids[@]}" -eq 0 ]]; then
    autom8_warn_ui "Perfil sem apps."
    autom8_summary_warn "Perfil sem apps"
    return 0
  fi

  autom8_apps_install_many "${ids[@]}"
}

autom8_profiles_remove() {
  autom8_profiles_require_catalog || return 1
  autom8_apps_require_catalog || return 1

  local profile_id="${1:-}"

  if [[ -z "$profile_id" ]]; then
    profile_id="$(autom8_profiles_prompt_id "Selecione o perfil para remover" || true)"
  fi

  if [[ -z "$profile_id" ]]; then
    autom8_warn_ui "Nenhum perfil selecionado."
    autom8_summary_warn "Remoção de perfil sem seleção"
    return 0
  fi

  if ! autom8_profiles_exists "$profile_id"; then
    autom8_error_ui "Perfil não encontrado: $profile_id"
    autom8_summary_fail "Perfil não encontrado"
    return 1
  fi

  local ids=()
  mapfile -t ids < <(autom8_profiles_apps "$profile_id")

  autom8_header "Perfis · remoção" "$profile_id"
  autom8_key_value "Apps" "${ids[*]}"

  if [[ "${#ids[@]}" -eq 0 ]]; then
    autom8_warn_ui "Perfil sem apps."
    autom8_summary_warn "Perfil sem apps"
    return 0
  fi

  autom8_apps_remove_many "${ids[@]}"
}

autom8_profiles_menu() {
  while true; do
    clear || true
    autom8_header "Perfis" "Instalação por conjuntos baseados no catálogo."

    local choice
    choice="$(autom8_choose "O que deseja fazer?" \
      "Listar perfis" \
      "Ver detalhes" \
      "Instalar perfil" \
      "Remover perfil" \
      "Voltar")" || return 0

    clear || true

    case "$choice" in
      "Listar perfis")
        autom8_profiles_list
        ;;
      "Ver detalhes")
        local show_id
        show_id="$(autom8_profiles_prompt_id "Selecione o perfil" || true)"
        autom8_profiles_show "$show_id"
        ;;
      "Instalar perfil")
        autom8_profiles_install
        ;;
      "Remover perfil")
        autom8_profiles_remove
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

autom8_module_profiles() {
  local action="${1:-menu}"
  shift || true

  case "$action" in
    menu|"")
      autom8_profiles_menu
      ;;
    list)
      autom8_profiles_list "$@"
      ;;
    show)
      autom8_profiles_show "$@"
      ;;
    install)
      autom8_profiles_install "$@"
      ;;
    remove)
      autom8_profiles_remove "$@"
      ;;
    *)
      autom8_error_ui "Ação desconhecida em perfis: $action"
      autom8_note "Uso: autom8 profiles [list|show|install|remove]"
      autom8_summary_fail "Ação de perfis desconhecida"
      return 1
      ;;
  esac
}
