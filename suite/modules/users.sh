#!/usr/bin/env bash

autom8_module_users() {
  autom8_title "Usuários do sistema"

  echo "Usuários com login permitido:"
  awk -F: '($7 !~ /(nologin|false)$/) {print $1 " | home=" $6 " | shell=" $7}' /etc/passwd

  echo
  echo "Grupos administrativos:"
  getent group sudo 2>/dev/null || true
  getent group wheel 2>/dev/null || true
  getent group admin 2>/dev/null || true

  autom8_warn_ui "Ações de bloqueio, shell e sudo serão implementadas em versão futura."
  autom8_log_info "users" "Users listed"
  autom8_summary_ok "Usuários listados"
}
