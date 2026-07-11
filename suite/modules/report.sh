#!/usr/bin/env bash

autom8_module_report() {
  autom8_title "Relatórios"

  local option
  option="$(autom8_choose "Escolha uma opção" \
    "Listar relatórios" \
    "Exportar relatórios em tar.gz" \
    "Voltar")" || return 0

  case "$option" in
    "Listar relatórios")
      find "$AUTOM8_REPORT_DIR" -maxdepth 1 -type f -printf '%f\n' 2>/dev/null | sort || true
      ;;
    "Exportar relatórios em tar.gz")
      local output
      output="$AUTOM8_REPORT_DIR/autom8-reports-$(date '+%Y-%m-%d-%H%M').tar.gz"
      tar -czf "$output" -C "$AUTOM8_REPORT_DIR" . 2>/dev/null || true
      autom8_success "Exportado: $output"
      ;;
    *)
      return 0
      ;;
  esac

  autom8_summary_ok "Relatórios processados"
}
