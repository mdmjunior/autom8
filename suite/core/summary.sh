#!/usr/bin/env bash

AUTOM8_SUMMARY_OK=0
AUTOM8_SUMMARY_FAIL=0
AUTOM8_SUMMARY_WARN=0
AUTOM8_SUMMARY_ITEMS=()

autom8_reset_summary() {
  AUTOM8_SUMMARY_OK=0
  AUTOM8_SUMMARY_FAIL=0
  AUTOM8_SUMMARY_WARN=0
  AUTOM8_SUMMARY_ITEMS=()
}

autom8_summary_ok() {
  AUTOM8_SUMMARY_OK=$((AUTOM8_SUMMARY_OK + 1))
  AUTOM8_SUMMARY_ITEMS+=("OK: $1")
}

autom8_summary_fail() {
  AUTOM8_SUMMARY_FAIL=$((AUTOM8_SUMMARY_FAIL + 1))
  AUTOM8_SUMMARY_ITEMS+=("FALHA: $1")
}

autom8_summary_warn() {
  AUTOM8_SUMMARY_WARN=$((AUTOM8_SUMMARY_WARN + 1))
  AUTOM8_SUMMARY_ITEMS+=("AVISO: $1")
}

autom8_print_summary() {
  autom8_title "Resumo da execução"

  autom8_key_value "Concluídas" "$AUTOM8_SUMMARY_OK"
  autom8_key_value "Avisos" "$AUTOM8_SUMMARY_WARN"
  autom8_key_value "Falhas" "$AUTOM8_SUMMARY_FAIL"
  autom8_key_value "Logs" "$AUTOM8_LOG_DIR"

  if [[ "${#AUTOM8_SUMMARY_ITEMS[@]}" -gt 0 ]]; then
    echo
    for item in "${AUTOM8_SUMMARY_ITEMS[@]}"; do
      case "$item" in
        OK:*) autom8_status_ok "${item#OK: }" ;;
        AVISO:*) autom8_status_warn "${item#AVISO: }" ;;
        FALHA:*) autom8_status_fail "${item#FALHA: }" ;;
        *) printf '  %s\n' "$item" ;;
      esac
    done
  fi
}
