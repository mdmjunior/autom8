#!/usr/bin/env bash

# AutoM8 Apps internal library.
# Este arquivo é carregado por suite/modules/apps.sh.

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
    apt|dnf|zypper|pacman) printf '%s\n' "$AUTOM8_PACKAGE_MANAGER" ;;
    *) printf 'unknown\n' ;;
  esac
}

autom8_apps_category_filter_arg() {
  local arg
  local next_is_category="false"

  for arg in "$@"; do
    if [[ "$next_is_category" == "true" ]]; then
      printf '%s\n' "$arg"
      return 0
    fi

    case "$arg" in
      --category=*)
        printf '%s\n' "${arg#--category=}"
        return 0
        ;;
      --category)
        next_is_category="true"
        ;;
    esac
  done

  return 1
}


autom8_apps_prompt_category() {
  local placeholder="${1:-Categoria}"
  local catalog
  catalog="$(autom8_apps_catalog_file)"

  autom8_apps_require_catalog || return 1

  if autom8_has_gum; then
    jq -r '.categories[].slug' "$catalog" | gum choose --header "$placeholder" --height 12
  else
    local category
    read -r -p "$placeholder: " category
    printf '%s\n' "$category"
  fi
}

autom8_apps_category_exists() {
  local category="$1"
  local catalog
  catalog="$(autom8_apps_catalog_file)"

  jq -e --arg category "$category" '
    .categories[]
    | select(.slug == $category or .name == $category)
  ' "$catalog" >/dev/null
}

autom8_apps_ids_for_category() {
  local category="$1"
  local status_filter="${2:-}"
  local catalog
  catalog="$(autom8_apps_catalog_file)"

  if [[ -n "$status_filter" ]]; then
    jq -r --arg category "$category" --arg status "$status_filter" '
      .apps[]
      | select(.category == $category or .categoryName == $category)
      | select((.status // "available") == $status)
      | .id
    ' "$catalog"
  else
    jq -r --arg category "$category" '
      .apps[]
      | select(.category == $category or .categoryName == $category)
      | .id
    ' "$catalog"
  fi
}

autom8_apps_blocked_ids_for_category() {
  local category="$1"
  local catalog
  catalog="$(autom8_apps_catalog_file)"

  jq -r --arg category "$category" '
    .apps[]
    | select(.category == $category or .categoryName == $category)
    | select((.status // "available") != "available")
    | .id + " (" + (.status // "available") + ")"
  ' "$catalog"
}

autom8_apps_print_category_plan() {
  local category="$1"
  local available_ids=("${@:2}")
  local blocked_ids=()

  mapfile -t blocked_ids < <(autom8_apps_blocked_ids_for_category "$category")

  autom8_key_value "Categoria" "$category"
  autom8_key_value "Apps disponíveis" "${available_ids[*]:-nenhum}"

  if [[ "${#blocked_ids[@]}" -gt 0 ]]; then
    echo
    autom8_section "Apps bloqueados nesta versão"
    printf '  - %s\n' "${blocked_ids[@]}"
    autom8_note "Apps com status advanced/planned aparecem no catálogo, mas não entram em ações automáticas."
  fi
}

autom8_apps_categories() {
  autom8_apps_require_catalog || return 1

  local catalog
  catalog="$(autom8_apps_catalog_file)"

  autom8_header "Apps · categorias" "Grupos disponíveis no catálogo."

  jq -r '
    .categories[]
    | "  " + .slug + " | " + .name + " | " + (.description // "")
  ' "$catalog"

  autom8_summary_ok "Categorias listadas"
}

autom8_apps_is_installable() {
  local app_id="$1"
  local catalog
  local status

  catalog="$(autom8_apps_catalog_file)"
  status="$(jq -r --arg id "$app_id" '.apps[] | select(.id == $id) | .status // "available"' "$catalog" | head -n 1)"

  if [[ -z "$status" ]]; then
    autom8_error_ui "App não encontrado no catálogo: $app_id"
    autom8_summary_fail "App não encontrado"
    return 1
  fi

  if [[ "$status" != "available" ]]; then
    autom8_warn_ui "App marcado como $status: $app_id"
    autom8_note "Este app aparece no catálogo, mas não será instalado automaticamente nesta versão."
    autom8_summary_warn "App não instalável automaticamente: $app_id"
    return 1
  fi

  return 0
}

autom8_apps_validate_ids_installable() {
  local app_id
  local failures=0

  autom8_section "Validação de status"

  for app_id in "$@"; do
    if autom8_apps_is_installable "$app_id"; then
      autom8_status_ok "App disponível para ação automática: $app_id"
    else
      autom8_status_fail "App bloqueado para ação automática: $app_id"
      failures=$((failures + 1))
    fi
  done

  [[ "$failures" -eq 0 ]]
}

autom8_apps_all_ids() {
  local catalog
  catalog="$(autom8_apps_catalog_file)"

  jq -r '.apps[].id' "$catalog"
}

autom8_apps_prompt_many_ids() {
  local placeholder="${1:-IDs dos apps}"
  local ids=""

  autom8_apps_require_catalog || return 1

  if autom8_has_gum; then
    ids="$(autom8_apps_all_ids | gum choose --no-limit --height 16 --header "$placeholder" || true)"
    [[ -n "$ids" ]] || return 1
    printf '%s\n' "$ids"
  else
    local raw
    read -r -p "$placeholder separados por espaço ou vírgula: " raw
    raw="${raw//,/ }"

    for item in $raw; do
      [[ -n "$item" ]] && printf '%s\n' "$item"
    done
  fi
}

autom8_apps_collect_packages_for_ids() {
  local app_id
  local package_name

  declare -A seen_packages=()

  for app_id in "$@"; do
    while IFS= read -r package_name; do
      [[ -n "$package_name" ]] || continue

      if [[ -z "${seen_packages[$package_name]:-}" ]]; then
        seen_packages["$package_name"]=1
        printf '%s\n' "$package_name"
      fi
    done < <(autom8_apps_packages_for_current_pm "$app_id")
  done
}

autom8_apps_validate_ids_have_packages() {
  local app_id
  local packages=()
  local failures=0

  autom8_section "Validação dos apps"

  for app_id in "$@"; do
    mapfile -t packages < <(autom8_apps_packages_for_current_pm "$app_id")

    if [[ "${#packages[@]}" -eq 0 ]]; then
      autom8_status_fail "Sem pacote para: $app_id"
      failures=$((failures + 1))
    else
      autom8_status_ok "$app_id -> ${packages[*]}"
    fi
  done

  [[ "$failures" -eq 0 ]]
}

autom8_apps_list() {
  autom8_apps_require_catalog || return 1

  local category_filter=""
  category_filter="$(autom8_apps_category_filter_arg "$@" || true)"

  local catalog
  catalog="$(autom8_apps_catalog_file)"

  autom8_header "Apps" "Catálogo local de aplicativos."

  autom8_key_value "Catálogo" "$catalog"
  autom8_key_value "Versão" "$(jq -r '.version // "unknown"' "$catalog")"
  autom8_key_value "Gerenciador" "$AUTOM8_PACKAGE_MANAGER"

  if [[ -n "$category_filter" ]]; then
    autom8_key_value "Categoria" "$category_filter"
  fi

  echo
  autom8_section "Disponíveis"

  if [[ -n "$category_filter" ]]; then
    jq -r --arg category "$category_filter" '
      .apps[]
      | select(.category == $category or .categoryName == $category)
      | "  " + (.id | .[0:22]) + " | " + (.status // "available") + " | " + (.name | .[0:28]) + " | " + (.summary // "")
    ' "$catalog"
  else
    jq -r '
      .apps[]
      | "  " + (.id | .[0:22]) + " | " + (.category // "sem-categoria") + " | " + (.status // "available") + " | " + (.name | .[0:28])
    ' "$catalog"
  fi

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
        or (.category | ascii_downcase | contains($q))
        or ((.tags // []) | join(" ") | ascii_downcase | contains($q))
      )
    | "  " + .id + " | " + .name + " | " + (.category // "uncategorized") + " | " + (.summary // "")
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
  autom8_key_value "Categoria" "$(jq -r --arg id "$app_id" '.apps[] | select(.id == $id) | .categoryName // .category // "uncategorized"' "$catalog")"
  autom8_key_value "Status" "$(jq -r --arg id "$app_id" '.apps[] | select(.id == $id) | .status // "available"' "$catalog")"
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
  autom8_section "Tags"
  jq -r --arg id "$app_id" '
    .apps[]
    | select(.id == $id)
    | (.tags // [])
    | .[]
    | "  - " + .
  ' "$catalog"

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
