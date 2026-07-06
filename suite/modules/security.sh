#!/usr/bin/env bash

autom8_module_security() {
  autom8_title "Segurança básica"

  echo "Firewall:"
  if command -v ufw >/dev/null 2>&1; then
    ufw status 2>/dev/null || true
  elif command -v firewall-cmd >/dev/null 2>&1; then
    firewall-cmd --state 2>/dev/null || true
  else
    echo "Firewall conhecido não encontrado."
  fi

  echo
  echo "Portas em escuta:"
  ss -tulpn 2>/dev/null || true

  echo
  echo "SSH:"
  systemctl is-active ssh 2>/dev/null || systemctl is-active sshd 2>/dev/null || true

  autom8_log_info "security" "Basic security check executed"
  autom8_summary_ok "Checagem básica de segurança executada"
}
