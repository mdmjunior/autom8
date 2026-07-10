#!/usr/bin/env bash

AUTOM8_DOCTOR_FAILURES=0
AUTOM8_DOCTOR_WARNINGS=0
AUTOM8_DOCTOR_REPORT_FILE=""

autom8_doctor_report() {
  printf '%s\n' "$*" >> "$AUTOM8_DOCTOR_REPORT_FILE"
}

autom8_doctor_ok() {
  local message="$1"
  autom8_status_ok "$message"
  autom8_doctor_report "[OK] $message"
}

autom8_doctor_warn() {
  local message="$1"
  AUTOM8_DOCTOR_WARNINGS=$((AUTOM8_DOCTOR_WARNINGS + 1))
  autom8_status_warn "$message"
  autom8_doctor_report "[AVISO] $message"
}

autom8_doctor_fail() {
  local message="$1"
  AUTOM8_DOCTOR_FAILURES=$((AUTOM8_DOCTOR_FAILURES + 1))
  autom8_status_fail "$message"
  autom8_doctor_report "[FALHA] $message"
}

autom8_doctor_check_dir() {
  local dir="$1"
  local writable="${2:-no}"

  if [[ ! -d "$dir" ]]; then
    autom8_doctor_fail "Diretório ausente: $dir"
    return 1
  fi

  if [[ "$writable" == "yes" && ! -w "$dir" ]]; then
    autom8_doctor_fail "Diretório sem permissão de escrita: $dir"
    return 1
  fi

  autom8_doctor_ok "Diretório OK: $dir"
  return 0
}

autom8_doctor_check_file() {
  local file="$1"
  local executable="${2:-no}"

  if [[ ! -f "$file" ]]; then
    autom8_doctor_fail "Arquivo ausente: $file"
    return 1
  fi

  if [[ "$executable" == "yes" && ! -x "$file" ]]; then
    autom8_doctor_fail "Arquivo sem permissão de execução: $file"
    return 1
  fi

  autom8_doctor_ok "Arquivo OK: $file"
  return 0
}

autom8_doctor_check_command() {
  local command_name="$1"
  local required="${2:-yes}"

  if command -v "$command_name" >/dev/null 2>&1; then
    autom8_doctor_ok "Comando encontrado: $command_name"
    return 0
  fi

  if [[ "$required" == "yes" ]]; then
    autom8_doctor_fail "Comando obrigatório ausente: $command_name"
    return 1
  fi

  autom8_doctor_warn "Comando opcional ausente: $command_name"
  return 0
}

autom8_doctor_check_path() {
  if command -v autom8 >/dev/null 2>&1; then
    autom8_doctor_ok "Comando autom8 encontrado no PATH: $(command -v autom8)"
  else
    autom8_doctor_warn "Comando autom8 não está no PATH desta sessão"
  fi
}

autom8_doctor_check_sudo() {
  if [[ "$AUTOM8_CAN_SUDO" == "true" && "$AUTOM8_READ_ONLY" != "true" ]]; then
    autom8_doctor_ok "Sudo disponível para ações administrativas"
  else
    autom8_doctor_warn "Usuário atual está em modo somente leitura"
  fi
}

autom8_doctor_check_distro() {
  if [[ "$AUTOM8_SUPPORTED_DISTRO" == "true" ]]; then
    autom8_doctor_ok "Distro suportada oficialmente: $AUTOM8_DISTRO_ID"
  else
    autom8_doctor_warn "Distro não suportada oficialmente: $AUTOM8_DISTRO_ID"
  fi
}

autom8_doctor_expected_package_url() {
  local repo="${AUTOM8_GITHUB_REPO:-mdmjunior/autom8}"
  printf 'https://github.com/%s/releases/latest/download/autom8-latest.tar.gz' "$repo"
}

autom8_doctor_check_release_origin() {
  local expected
  local current

  expected="$(autom8_doctor_expected_package_url)"
  current="${AUTOM8_PACKAGE_URL:-$expected}"

  if [[ "$current" == "$expected" ]]; then
    autom8_doctor_ok "Origem estável configurada: GitHub Releases"
  else
    autom8_doctor_warn "Origem do pacote foi sobrescrita: $current"
  fi

  autom8_doctor_report "URL esperada: $expected"
  autom8_doctor_report "URL atual: $current"
}

autom8_doctor_check_online_version() {
  local repo="${AUTOM8_GITHUB_REPO:-mdmjunior/autom8}"
  local api_url="https://api.github.com/repos/${repo}/releases/latest"
  local latest
  local installed

  if ! command -v curl >/dev/null 2>&1; then
    autom8_doctor_warn "Não foi possível verificar versão online: curl ausente"
    return 0
  fi

  latest="$(
    curl -fsSL \
      --connect-timeout 5 \
      --max-time 10 \
      -H "Accept: application/vnd.github+json" \
      "$api_url" 2>/dev/null \
      | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
      | head -n 1
  )"

  if [[ -z "$latest" ]]; then
    autom8_doctor_warn "Não foi possível verificar atualização online"
    return 0
  fi

  installed="${AUTOM8_VERSION#v}"
  latest="${latest#v}"

  autom8_doctor_report "Versão instalada: $installed"
  autom8_doctor_report "Última versão online: $latest"

  if [[ "$installed" == "dev" ]]; then
    autom8_doctor_warn "Versão local é dev; comparação online apenas informativa"
    return 0
  fi

  if [[ "$installed" == "$latest" ]]; then
    autom8_doctor_ok "Versão instalada está alinhada com a release estável: $latest"
  else
    autom8_doctor_warn "Versão online disponível: $latest; instalada: $installed"
  fi
}

autom8_module_doctor() {
  AUTOM8_DOCTOR_FAILURES=0
  AUTOM8_DOCTOR_WARNINGS=0

  local timestamp
  timestamp="$(date '+%Y-%m-%d-%H%M')"

  mkdir -p "$AUTOM8_REPORT_DIR"
  AUTOM8_DOCTOR_REPORT_FILE="$AUTOM8_REPORT_DIR/doctor-${timestamp}.txt"

  {
    printf 'AutoM8 Doctor\n'
    printf 'Gerado em: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
    printf 'Produto: %s\n' "$AUTOM8_NAME"
    printf 'Versão: %s\n' "$AUTOM8_VERSION"
    printf 'Root: %s\n' "$AUTOM8_ROOT"
    printf 'Usuário: %s\n' "$USER"
    printf '\n'
  } > "$AUTOM8_DOCTOR_REPORT_FILE"

  autom8_header "AutoM8 Doctor" "Verificação da instalação local"

  autom8_section "Produto"
  autom8_key_value "Nome" "$AUTOM8_NAME"
  autom8_key_value "Versão instalada" "$AUTOM8_VERSION"
  autom8_key_value "Diretório" "$AUTOM8_ROOT"
  autom8_key_value "Relatório" "$AUTOM8_DOCTOR_REPORT_FILE"

  autom8_doctor_report "== Produto =="
  autom8_doctor_report "Nome: $AUTOM8_NAME"
  autom8_doctor_report "Versão instalada: $AUTOM8_VERSION"
  autom8_doctor_report "Diretório: $AUTOM8_ROOT"
  autom8_doctor_report ""

  echo
  autom8_section "Sistema"
  autom8_key_value "Distro" "$AUTOM8_DISTRO_NAME"
  autom8_key_value "ID" "$AUTOM8_DISTRO_ID"
  autom8_key_value "Versão" "$AUTOM8_DISTRO_VERSION"
  autom8_key_value "Gerenciador" "$AUTOM8_PACKAGE_MANAGER"

  autom8_doctor_report "== Sistema =="
  autom8_doctor_report "Distro: $AUTOM8_DISTRO_NAME"
  autom8_doctor_report "ID: $AUTOM8_DISTRO_ID"
  autom8_doctor_report "Versão: $AUTOM8_DISTRO_VERSION"
  autom8_doctor_report "Gerenciador: $AUTOM8_PACKAGE_MANAGER"
  autom8_doctor_report ""

  autom8_doctor_check_distro
  autom8_doctor_check_sudo

  echo
  autom8_section "Estrutura"
  autom8_doctor_report "== Estrutura =="

  autom8_doctor_check_dir "$AUTOM8_ROOT"
  autom8_doctor_check_dir "$AUTOM8_ROOT/bin"
  autom8_doctor_check_dir "$AUTOM8_ROOT/core"
  autom8_doctor_check_dir "$AUTOM8_ROOT/modules"
  autom8_doctor_check_dir "$AUTOM8_ROOT/config" yes
  autom8_doctor_check_dir "$AUTOM8_LOG_DIR" yes
  autom8_doctor_check_dir "$AUTOM8_REPORT_DIR" yes
  autom8_doctor_check_dir "$AUTOM8_BACKUP_DIR" yes
  autom8_doctor_check_dir "$AUTOM8_TMP_DIR" yes

  autom8_doctor_report ""
  echo
  autom8_section "Arquivos principais"
  autom8_doctor_report "== Arquivos principais =="

  autom8_doctor_check_file "$AUTOM8_ROOT/bin/autom8" yes
  autom8_doctor_check_file "$AUTOM8_ROOT/VERSION"
  autom8_doctor_check_file "$AUTOM8_CONFIG_FILE"
  autom8_doctor_check_file "$AUTOM8_ROOT/core/ui.sh"
  autom8_doctor_check_file "$AUTOM8_ROOT/core/detect.sh"
  autom8_doctor_check_file "$AUTOM8_ROOT/core/sudo.sh"
  autom8_doctor_check_file "$AUTOM8_ROOT/modules/diagnose.sh"
  autom8_doctor_check_file "$AUTOM8_ROOT/modules/update.sh"
  autom8_doctor_check_file "$AUTOM8_ROOT/modules/clean.sh"
  autom8_doctor_check_file "$AUTOM8_ROOT/modules/doctor.sh"

  autom8_doctor_report ""
  echo
  autom8_section "Dependências obrigatórias"
  autom8_doctor_report "== Dependências obrigatórias =="

  for cmd in bash awk sed grep find tar gzip curl sudo jq rsync lsof nmap ip ss gum; do
    autom8_doctor_check_command "$cmd" yes
  done

  autom8_doctor_report ""
  echo
  autom8_section "Dependências opcionais"
  autom8_doctor_report "== Dependências opcionais =="

  for cmd in docker flatpak snap systemctl ufw firewall-cmd; do
    autom8_doctor_check_command "$cmd" no
  done

  autom8_doctor_report ""
  echo
  autom8_section "PATH"
  autom8_doctor_report "== PATH =="
  autom8_doctor_check_path

  autom8_doctor_report ""
  echo
  autom8_section "Release"
  autom8_doctor_report "== Release =="
  autom8_doctor_check_release_origin
  autom8_doctor_check_online_version

  autom8_doctor_report ""
  autom8_doctor_report "== Resultado =="
  autom8_doctor_report "Falhas: $AUTOM8_DOCTOR_FAILURES"
  autom8_doctor_report "Avisos: $AUTOM8_DOCTOR_WARNINGS"

  echo
  autom8_section "Resultado"
  autom8_key_value "Falhas" "$AUTOM8_DOCTOR_FAILURES"
  autom8_key_value "Avisos" "$AUTOM8_DOCTOR_WARNINGS"

  echo
  if [[ "$AUTOM8_DOCTOR_FAILURES" -eq 0 ]]; then
    autom8_success "Doctor finalizado sem falhas críticas."
    autom8_summary_ok "Doctor finalizado"
  else
    autom8_error_ui "Doctor encontrou $AUTOM8_DOCTOR_FAILURES falha(s)."
    autom8_summary_fail "Doctor encontrou falhas"
  fi

  if [[ "$AUTOM8_DOCTOR_WARNINGS" -gt 0 ]]; then
    autom8_warn_ui "Doctor encontrou $AUTOM8_DOCTOR_WARNINGS aviso(s)."
    autom8_summary_warn "Doctor encontrou avisos"
  fi

  autom8_note "Relatório: $AUTOM8_DOCTOR_REPORT_FILE"
  autom8_log_info "diagnostic" "Doctor report generated: $AUTOM8_DOCTOR_REPORT_FILE"
}
