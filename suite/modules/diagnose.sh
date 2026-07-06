#!/usr/bin/env bash

autom8_module_diagnose() {
  autom8_title "Diagnóstico do sistema"

  local timestamp
  timestamp="$(date '+%Y-%m-%d-%H%M')"

  local report_file="$AUTOM8_REPORT_DIR/diagnostic-${timestamp}.txt"

  {
    echo "AutoM8 - Linux Management Suite"
    echo "Relatório de Diagnóstico"
    echo "Gerado em: $(date '+%Y-%m-%d %H:%M:%S')"
    echo

    echo "== Sistema =="
    autom8_print_detection
    echo "Hostname: $(hostname)"
    echo "Kernel: $(uname -r)"
    echo "Arquitetura: $(uname -m)"
    echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
    echo

    echo "== CPU =="
    if command -v lscpu >/dev/null 2>&1; then
      lscpu | sed -n '1,20p'
    else
      grep -m1 "model name" /proc/cpuinfo 2>/dev/null || true
    fi
    echo

    echo "== Memória =="
    free -h 2>/dev/null || true
    echo

    echo "== Disco =="
    df -hT 2>/dev/null || true
    echo

    echo "== Rede =="
    ip -br addr 2>/dev/null || true
    echo
    ip route 2>/dev/null || true
    echo

    echo "== DNS =="
    if [[ -f /etc/resolv.conf ]]; then
      cat /etc/resolv.conf
    fi
    echo

    echo "== Serviços principais =="
    if command -v systemctl >/dev/null 2>&1; then
      systemctl --failed --no-pager 2>/dev/null || true
    fi
    echo

    echo "== Firewall =="
    if command -v ufw >/dev/null 2>&1; then
      ufw status 2>/dev/null || true
    elif command -v firewall-cmd >/dev/null 2>&1; then
      firewall-cmd --state 2>/dev/null || true
      firewall-cmd --list-all 2>/dev/null || true
    else
      echo "Firewall conhecido não encontrado ou não instalado."
    fi
    echo

    echo "== Portas em escuta =="
    ss -tulpn 2>/dev/null || true
    echo

    echo "== Docker =="
    if command -v docker >/dev/null 2>&1; then
      docker --version 2>/dev/null || true
      docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || true
      docker system df 2>/dev/null || true
    else
      echo "Docker não encontrado."
    fi
    echo

    echo "== Usuários com login permitido =="
    awk -F: '($7 !~ /(nologin|false)$/) {print $1 " | home=" $6 " | shell=" $7}' /etc/passwd
    echo

    echo "== Usuários em grupos sudo/wheel/admin =="
    getent group sudo 2>/dev/null || true
    getent group wheel 2>/dev/null || true
    getent group admin 2>/dev/null || true
    echo

    echo "== Sessão gráfica =="
    echo "Desktop: $AUTOM8_DESKTOP_SESSION"
    echo "Tipo: $AUTOM8_SESSION_TYPE"
  } > "$report_file"

  autom8_log_info "diagnostic" "Diagnostic report generated: $report_file"
  autom8_success "Relatório gerado em: $report_file"
  autom8_summary_ok "Diagnóstico gerado"
}
