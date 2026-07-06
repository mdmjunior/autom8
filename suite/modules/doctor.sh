#!/usr/bin/env bash

autom8_doctor_status() {
  local status="$1"
  local message="$2"

  case "$status" in
    ok)
      printf '[OK] %s\n' "$message"
      ;;
    warn)
      printf '[AVISO] %s\n' "$message"
      ;;
    fail)
      printf '[FALHA] %s\n' "$message"
      ;;
  esac
}

autom8_doctor_check_command() {
  local command_name="$1"
  local required="${2:-yes}"

  if command -v "$command_name" >/dev/null 2>&1; then
    autom8_doctor_status ok "Comando encontrado: $command_name"
    return 0
  fi

  if [[ "$required" == "yes" ]]; then
    autom8_doctor_status fail "Comando obrigatório ausente: $command_name"
    return 1
  fi

  autom8_doctor_status warn "Comando opcional ausente: $command_name"
  return 0
}

autom8_doctor_check_dir() {
  local dir="$1"
  local writable="${2:-no}"

  if [[ ! -d "$dir" ]]; then
    autom8_doctor_status fail "Diretório ausente: $dir"
    return 1
  fi

  if [[ "$writable" == "yes" && ! -w "$dir" ]]; then
    autom8_doctor_status fail "Diretório sem permissão de escrita: $dir"
    return 1
  fi

  autom8_doctor_status ok "Diretório OK: $dir"
  return 0
}

autom8_doctor_check_file() {
  local file="$1"

  if [[ -f "$file" ]]; then
    autom8_doctor_status ok "Arquivo OK: $file"
    return 0
  fi

  autom8_doctor_status fail "Arquivo ausente: $file"
  return 1
}

autom8_module_doctor() {
  autom8_title "AutoM8 Doctor"

  local failures=0
  local warnings=0
  local timestamp
  local report_file

  timestamp="$(date '+%Y-%m-%d-%H%M')"
  report_file="$AUTOM8_REPORT_DIR/doctor-${timestamp}.txt"

  {
    echo "AutoM8 Doctor"
    echo "Gerado em: $(date '+%Y-%m-%d %H:%M:%S')"
    echo

    echo "== Produto =="
    echo "Nome: $AUTOM8_NAME"
    echo "Versão: $AUTOM8_VERSION"
    echo "Root: $AUTOM8_ROOT"
    echo "Usuário: $USER"
    echo

    echo "== Distro =="
    autom8_print_detection
    echo

    echo "== Permissões =="
    echo "Pode usar sudo: $AUTOM8_CAN_SUDO"
    echo "Modo somente leitura: $AUTOM8_READ_ONLY"
    echo

    echo "== Estrutura =="
  } > "$report_file"

  autom8_doctor_check_dir "$AUTOM8_ROOT" | tee -a "$report_file" || failures=$((failures + 1))
  autom8_doctor_check_dir "$AUTOM8_ROOT/bin" | tee -a "$report_file" || failures=$((failures + 1))
  autom8_doctor_check_dir "$AUTOM8_ROOT/core" | tee -a "$report_file" || failures=$((failures + 1))
  autom8_doctor_check_dir "$AUTOM8_ROOT/modules" | tee -a "$report_file" || failures=$((failures + 1))
  autom8_doctor_check_dir "$AUTOM8_ROOT/config" yes | tee -a "$report_file" || failures=$((failures + 1))
  autom8_doctor_check_dir "$AUTOM8_LOG_DIR" yes | tee -a "$report_file" || failures=$((failures + 1))
  autom8_doctor_check_dir "$AUTOM8_REPORT_DIR" yes | tee -a "$report_file" || failures=$((failures + 1))
  autom8_doctor_check_dir "$AUTOM8_BACKUP_DIR" yes | tee -a "$report_file" || failures=$((failures + 1))
  autom8_doctor_check_dir "$AUTOM8_TMP_DIR" yes | tee -a "$report_file" || failures=$((failures + 1))

  echo >> "$report_file"
  echo "== Arquivos principais ==" >> "$report_file"

  autom8_doctor_check_file "$AUTOM8_ROOT/bin/autom8" | tee -a "$report_file" || failures=$((failures + 1))
  autom8_doctor_check_file "$AUTOM8_ROOT/VERSION" | tee -a "$report_file" || failures=$((failures + 1))
  autom8_doctor_check_file "$AUTOM8_CONFIG_FILE" | tee -a "$report_file" || failures=$((failures + 1))
  autom8_doctor_check_file "$AUTOM8_ROOT/modules/diagnose.sh" | tee -a "$report_file" || failures=$((failures + 1))
  autom8_doctor_check_file "$AUTOM8_ROOT/modules/update.sh" | tee -a "$report_file" || failures=$((failures + 1))
  autom8_doctor_check_file "$AUTOM8_ROOT/modules/clean.sh" | tee -a "$report_file" || failures=$((failures + 1))
  autom8_doctor_check_file "$AUTOM8_ROOT/modules/doctor.sh" | tee -a "$report_file" || failures=$((failures + 1))

  if [[ -x "$AUTOM8_ROOT/bin/autom8" ]]; then
    autom8_doctor_status ok "Executável OK: $AUTOM8_ROOT/bin/autom8" | tee -a "$report_file"
  else
    autom8_doctor_status fail "Executável sem permissão: $AUTOM8_ROOT/bin/autom8" | tee -a "$report_file"
    failures=$((failures + 1))
  fi

  echo >> "$report_file"
  echo "== Comandos obrigatórios ==" >> "$report_file"

  for cmd in bash awk sed grep find tar gzip curl sudo; do
    autom8_doctor_check_command "$cmd" yes | tee -a "$report_file" || failures=$((failures + 1))
  done

  echo >> "$report_file"
  echo "== Comandos opcionais ==" >> "$report_file"

  for cmd in gum jq rsync ss docker flatpak snap nmap lsof; do
    if ! autom8_doctor_check_command "$cmd" no | tee -a "$report_file"; then
      warnings=$((warnings + 1))
    fi
  done

  echo >> "$report_file"
  echo "== PATH ==" >> "$report_file"

  if command -v autom8 >/dev/null 2>&1; then
    autom8_doctor_status ok "Comando autom8 encontrado no PATH: $(command -v autom8)" | tee -a "$report_file"
  else
    autom8_doctor_status warn "Comando autom8 ainda não está no PATH desta sessão" | tee -a "$report_file"
    warnings=$((warnings + 1))
  fi

  echo >> "$report_file"
  echo "== Resultado ==" >> "$report_file"
  echo "Falhas: $failures" >> "$report_file"
  echo "Avisos: $warnings" >> "$report_file"

  echo
  if [[ "$failures" -eq 0 ]]; then
    autom8_success "Doctor finalizado sem falhas críticas."
    autom8_summary_ok "Doctor finalizado"
  else
    autom8_error_ui "Doctor encontrou $failures falha(s)."
    autom8_summary_fail "Doctor encontrou falhas"
  fi

  if [[ "$warnings" -gt 0 ]]; then
    autom8_warn_ui "Doctor encontrou $warnings aviso(s)."
  fi

  autom8_note "Relatório: $report_file"
  autom8_log_info "diagnostic" "Doctor report generated: $report_file"
}
