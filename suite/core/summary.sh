#!/usr/bin/env bash

AUTOM8_SUMMARY_OK=0
AUTOM8_SUMMARY_FAIL=0
AUTOM8_SUMMARY_WARN=0
AUTOM8_SUMMARY_ITEMS=()

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

  printf 'Concluídas: %s\n' "$AUTOM8_SUMMARY_OK"
  printf 'Avisos: %s\n' "$AUTOM8_SUMMARY_WARN"
  printf 'Falhas: %s\n' "$AUTOM8_SUMMARY_FAIL"
  printf 'Logs: %s\n\n' "$AUTOM8_LOG_DIR"

  if [[ "${#AUTOM8_SUMMARY_ITEMS[@]}" -gt 0 ]]; then
    printf '%s\n' "${AUTOM8_SUMMARY_ITEMS[@]}"
  fi
}
