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
    apt|dnf|zypper|pacman) printf '%s\n' "$AUTOM8_PACKAGE_MANAGER" ;;
    *) printf 'unknown\n' ;;
  esac
}

autom8_apps_package_available() {
  local package_name="$1"

  case "$AUTOM8_PACKAGE_MANAGER" in
    apt)
      if command -v dpkg-query >/dev/null 2>&1 && dpkg-query -W -f='${Status}' "$package_name" 2>/dev/null | grep -q "install ok installed"; then
        return 0
      fi

      if command -v apt-cache >/dev/null 2>&1; then
        local candidate
        candidate="$(apt-cache policy "$package_name" 2>/dev/null | awk '/Candidate:/ {print $2; exit}')"
        [[ -n "$candidate" && "$candidate" != "(none)" ]]
        return $?
      fi
      ;;

    dnf)
      if command -v rpm >/dev/null 2>&1 && rpm -q "$package_name" >/dev/null 2>&1; then
        return 0
      fi

      dnf list "$package_name" >/dev/null 2>&1
      return $?
      ;;

    zypper)
      if command -v rpm >/dev/null 2>&1 && rpm -q "$package_name" >/dev/null 2>&1; then
        return 0
      fi

      zypper --non-interactive search --match-exact "$package_name" 2>/dev/null | awk -F'|' -v pkg="$package_name" '
        NR > 2 {
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
          if ($2 == pkg) found=1
        }
        END {exit found ? 0 : 1}
      '
      return $?
      ;;

    pacman)
      pacman -Qi "$package_name" >/dev/null 2>&1 || pacman -Si "$package_name" >/dev/null 2>&1
      return $?
      ;;
  esac

  return 1
}

autom8_apps_validate_packages_available() {
  local package_name
  local missing=0

  autom8_section "Validação de pacotes"

  for package_name in "$@"; do
    if autom8_apps_package_available "$package_name"; then
      autom8_status_ok "Pacote disponível: $package_name"
    else
      autom8_status_fail "Pacote indisponível: $package_name"
      missing=$((missing + 1))
    fi
  done

  if [[ "$missing" -gt 0 ]]; then
    autom8_warn_ui "Um ou mais pacotes não estão disponíveis nos repositórios atuais."
    autom8_note "Atualize o catálogo/repositórios ou habilite o repositório necessário antes de instalar."
    return 1
  fi

  return 0
}


autom8_apps_package_installed() {
  local package_name="$1"

  case "$AUTOM8_PACKAGE_MANAGER" in
    apt)
      command -v dpkg-query >/dev/null 2>&1 || return 1
      dpkg-query -W -f='${Status}' "$package_name" 2>/dev/null | grep -q "install ok installed"
      ;;
    dnf|zypper)
      command -v rpm >/dev/null 2>&1 || return 1
      rpm -q "$package_name" >/dev/null 2>&1
      ;;
    pacman)
      pacman -Qi "$package_name" >/dev/null 2>&1
      ;;
    *)
      return 1
      ;;
  esac
}

autom8_apps_installed_package_list() {
  local package_name

  for package_name in "$@"; do
    if autom8_apps_package_installed "$package_name"; then
      printf '%s\n' "$package_name"
    fi
  done
}

autom8_apps_remove_command_preview() {
  local packages=("$@")

  case "$AUTOM8_PACKAGE_MANAGER" in
    apt) printf 'sudo apt remove -y %s\n' "${packages[*]}" ;;
    dnf) printf 'sudo dnf remove -y %s\n' "${packages[*]}" ;;
    zypper) printf 'sudo zypper remove -y %s\n' "${packages[*]}" ;;
    pacman) printf 'sudo pacman -Rns --noconfirm %s\n' "${packages[*]}" ;;
    *) printf 'Gerenciador não suportado\n' ;;
  esac
}

autom8_apps_remove_packages() {
  local packages=("$@")

  case "$AUTOM8_PACKAGE_MANAGER" in
    apt)
      autom8_sudo "remover apps via APT" apt remove -y "${packages[@]}" || return 1
      ;;
    dnf)
      autom8_sudo "remover apps via DNF" dnf remove -y "${packages[@]}" || return 1
      ;;
    zypper)
      autom8_sudo "remover apps via Zypper" zypper remove -y "${packages[@]}" || return 1
      ;;
    pacman)
      autom8_sudo "remover apps via Pacman" pacman -Rns --noconfirm "${packages[@]}" || return 1
      ;;
    *)
      autom8_error_ui "Gerenciador de pacotes não suportado para remoção: $AUTOM8_PACKAGE_MANAGER"
      return 1
      ;;
  esac
}

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

autom8_apps_install_command_preview() {
  local packages=("$@")

  case "$AUTOM8_PACKAGE_MANAGER" in
    apt) printf 'sudo apt update && sudo apt install -y %s\n' "${packages[*]}" ;;
    dnf) printf 'sudo dnf install -y %s\n' "${packages[*]}" ;;
    zypper) printf 'sudo zypper install -y %s\n' "${packages[*]}" ;;
    pacman) printf 'sudo pacman -Sy --needed --noconfirm %s\n' "${packages[*]}" ;;
    *) printf 'Gerenciador não suportado\n' ;;
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
      "Listar categorias" \
      "Listar por categoria" \
      "Buscar app" \
      "Ver detalhes" \
      "Instalar app" \
      "Instalar vários apps" \
      "Remover app" \
      "Remover vários apps" \
      "Atualizar catálogo" \
      "Voltar")" || return 0

    clear || true

    case "$choice" in
      "Listar apps")
        autom8_apps_list
        ;;
      "Listar categorias")
        autom8_apps_categories
        ;;
      "Listar por categoria")
        local category
        if autom8_has_gum; then
          category="$(jq -r '.categories[].slug' "$(autom8_apps_catalog_file)" | gum choose --header "Categoria" --height 12)"
        else
          read -r -p "Categoria: " category
        fi
        autom8_apps_list --category "$category"
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
      "Remover app")
        local remove_id
        if autom8_has_gum; then
          remove_id="$(gum input --placeholder "ID do app")"
        else
          read -r -p "ID do app: " remove_id
        fi
        autom8_apps_remove "$remove_id"
        ;;
      "Instalar vários apps")
        autom8_apps_install_many
        ;;
      "Remover vários apps")
        autom8_apps_remove_many
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
    categories)
      autom8_apps_categories "$@"
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
    install-many)
      autom8_apps_install_many "$@"
      ;;
    remove)
      autom8_apps_remove "$@"
      ;;
    remove-many)
      autom8_apps_remove_many "$@"
      ;;
    update-catalog)
      autom8_apps_update_catalog "$@"
      ;;
    *)
      autom8_error_ui "Ação desconhecida em apps: $action"
      autom8_note "Uso: autom8 apps [categories|list|list --category <categoria>|search|show|install|install-many|remove|remove-many|update-catalog]"
      autom8_summary_fail "Ação de apps desconhecida"
      return 1
      ;;
  esac
}
