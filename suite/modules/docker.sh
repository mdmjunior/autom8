#!/usr/bin/env bash

autom8_module_docker() {
  autom8_title "Docker"

  if ! command -v docker >/dev/null 2>&1; then
    autom8_warn_ui "Docker não encontrado."
    autom8_note "Instalação do Docker será expandida em versão futura."
    autom8_summary_warn "Docker não instalado"
    return 0
  fi

  docker --version || true
  echo
  docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || true
  echo
  docker system df 2>/dev/null || true

  autom8_log_info "docker" "Docker status checked"
  autom8_summary_ok "Status do Docker verificado"
}
