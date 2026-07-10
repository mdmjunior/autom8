#!/usr/bin/env bash

AUTOM8_DIAGNOSE_REPORT_FILE=""
AUTOM8_DIAGNOSE_PRIVATE="false"

autom8_diagnose_is_private() {
  local arg

  if [[ "${AUTOM8_PRIVATE_REPORT:-false}" == "true" ]]; then
    return 0
  fi

  for arg in "$@"; do
    if [[ "$arg" == "--private" ]]; then
      return 0
    fi
  done

  return 1
}

autom8_diagnose_sanitize_stream() {
  local hostname_value="${HOSTNAME:-}"
  local detected_hostname
  local current_user="${USER:-}"

  detected_hostname="$(hostname 2>/dev/null || true)"

  awk \
    -v h1="$hostname_value" \
    -v h2="$detected_hostname" \
    -v user="$current_user" '
      {
        if (h1 != "") {
          gsub(h1, "hostname-redacted")
        }

        if (h2 != "" && h2 != h1) {
          gsub(h2, "hostname-redacted")
        }

        if (user != "") {
          gsub("/home/" user, "/home/user-redacted")
          gsub("user=" user, "user=user-redacted")
        }

        gsub(/\/home\/[A-Za-z0-9._-]+/, "/home/user-redacted")
        gsub(/[0-9]{1,3}(\.[0-9]{1,3}){3}/, "ip-redacted")
        gsub(/[[:xdigit:]]{2}(:[[:xdigit:]]{2}){5}/, "mac-redacted")
        gsub(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/, "email-redacted")

        print
      }
    '
}

autom8_diagnose_write() {
  if [[ "$AUTOM8_DIAGNOSE_PRIVATE" == "true" ]]; then
    printf '%s\n' "$*" | autom8_diagnose_sanitize_stream >> "$AUTOM8_DIAGNOSE_REPORT_FILE"
  else
    printf '%s\n' "$*" >> "$AUTOM8_DIAGNOSE_REPORT_FILE"
  fi
}

autom8_diagnose_run() {
  local title="$1"
  shift

  autom8_diagnose_write "== $title =="

  if [[ "$AUTOM8_DIAGNOSE_PRIVATE" == "true" ]]; then
    "$@" 2>&1 | autom8_diagnose_sanitize_stream >> "$AUTOM8_DIAGNOSE_REPORT_FILE" || true
  else
    "$@" >> "$AUTOM8_DIAGNOSE_REPORT_FILE" 2>&1 || true
  fi

  printf '\n' >> "$AUTOM8_DIAGNOSE_REPORT_FILE"
}

autom8_diagnose_system() {
  autom8_diagnose_write "== Sistema =="
  autom8_diagnose_write "Distro: $AUTOM8_DISTRO_NAME"
  autom8_diagnose_write "ID: $AUTOM8_DISTRO_ID"
  autom8_diagnose_write "Versão: $AUTOM8_DISTRO_VERSION"
  autom8_diagnose_write "Gerenciador: $AUTOM8_PACKAGE_MANAGER"

  if [[ "$AUTOM8_DIAGNOSE_PRIVATE" == "true" ]]; then
    autom8_diagnose_write "Hostname: hostname-redacted"
  else
    autom8_diagnose_write "Hostname: $(hostname 2>/dev/null || true)"
  fi

  autom8_diagnose_write "Kernel: $(uname -r 2>/dev/null || true)"
  autom8_diagnose_write "Arquitetura: $(uname -m 2>/dev/null || true)"
  autom8_diagnose_write "Uptime: $(uptime -p 2>/dev/null || uptime 2>/dev/null || true)"
  autom8_diagnose_write ""
}

autom8_diagnose_network() {
  if [[ "$AUTOM8_DIAGNOSE_PRIVATE" == "true" ]]; then
    autom8_diagnose_run "Rede" bash -c 'ip -br addr 2>/dev/null || true'
    autom8_diagnose_run "Rotas sanitizadas" bash -c 'ip route 2>/dev/null || true'
  else
    autom8_diagnose_run "Rede" bash -c 'ip -br addr 2>/dev/null || true; echo; ip route 2>/dev/null || true'
  fi
}

autom8_diagnose_dns() {
  if [[ ! -f /etc/resolv.conf ]]; then
    autom8_diagnose_write "== DNS =="
    autom8_diagnose_write "Arquivo /etc/resolv.conf não encontrado."
    autom8_diagnose_write ""
    return 0
  fi

  if [[ "$AUTOM8_DIAGNOSE_PRIVATE" == "true" ]]; then
    autom8_diagnose_run "DNS sanitizado" bash -c 'grep -E "^(nameserver|search|options)" /etc/resolv.conf 2>/dev/null || true'
  else
    autom8_diagnose_run "DNS" cat /etc/resolv.conf
  fi
}

autom8_diagnose_services() {
  autom8_diagnose_run "Serviços principais" bash -c '
    if command -v systemctl >/dev/null 2>&1; then
      systemctl --failed --no-pager 2>/dev/null || true
    else
      echo "systemctl não encontrado."
    fi
  '
}

autom8_diagnose_firewall() {
  autom8_diagnose_run "Firewall" bash -c '
    if command -v ufw >/dev/null 2>&1; then
      ufw status 2>/dev/null || true
    elif command -v firewall-cmd >/dev/null 2>&1; then
      firewall-cmd --state 2>/dev/null || true
      firewall-cmd --list-all 2>/dev/null || true
    else
      echo "Firewall conhecido não encontrado ou não instalado."
    fi
  '
}

autom8_diagnose_ports() {
  if [[ "$AUTOM8_DIAGNOSE_PRIVATE" == "true" ]]; then
    autom8_diagnose_run "Portas em escuta sanitizadas" bash -c 'ss -tuln 2>/dev/null || true'
  else
    autom8_diagnose_run "Portas em escuta" bash -c 'ss -tulpn 2>/dev/null || true'
  fi
}

autom8_diagnose_docker() {
  if [[ "$AUTOM8_DIAGNOSE_PRIVATE" == "true" ]]; then
    # O conteúdo é um script literal executado pelo bash interno.
    # shellcheck disable=SC2016
    autom8_diagnose_run "Docker sanitizado" bash -c '
      if command -v docker >/dev/null 2>&1; then
        docker --version 2>/dev/null || true
        echo
        echo "Containers em execução: $(docker ps -q 2>/dev/null | wc -l)"
        echo
        docker system df 2>/dev/null || true
      else
        echo "Docker não encontrado."
      fi
    '
  else
    autom8_diagnose_run "Docker" bash -c '
      if command -v docker >/dev/null 2>&1; then
        docker --version 2>/dev/null || true
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || true
        docker system df 2>/dev/null || true
      else
        echo "Docker não encontrado."
      fi
    '
  fi
}

autom8_diagnose_users() {
  if [[ "$AUTOM8_DIAGNOSE_PRIVATE" == "true" ]]; then
    # A expansão de $7 deve ocorrer dentro do awk no bash interno.
    # shellcheck disable=SC2016
    autom8_diagnose_run "Usuários com login permitido sanitizados" bash -c '
      awk -F: '\''($7 !~ /(nologin|false)$/) {count++; print "user-" count " | home=/home/user-" count " | shell=" $7}'\'' /etc/passwd
    '

    # $group_name pertence ao script executado pelo bash interno.
    # shellcheck disable=SC2016
    autom8_diagnose_run "Grupos administrativos sanitizados" bash -c '
      for group_name in sudo wheel admin; do
        if getent group "$group_name" >/dev/null 2>&1; then
          echo "$group_name: members-redacted"
        fi
      done
    '
  else
    # As variáveis do awk devem ser avaliadas pelo bash interno.
    # shellcheck disable=SC2016
    autom8_diagnose_run "Usuários com login permitido" bash -c '
      awk -F: '\''($7 !~ /(nologin|false)$/) {print $1 " | home=" $6 " | shell=" $7}'\'' /etc/passwd
    '

    autom8_diagnose_run "Usuários em grupos sudo/wheel/admin" bash -c '
      getent group sudo 2>/dev/null || true
      getent group wheel 2>/dev/null || true
      getent group admin 2>/dev/null || true
    '
  fi
}

autom8_diagnose_graphical_session() {
  autom8_diagnose_write "== Sessão gráfica =="
  autom8_diagnose_write "Desktop: $AUTOM8_DESKTOP_SESSION"
  autom8_diagnose_write "Tipo: $AUTOM8_SESSION_TYPE"
  autom8_diagnose_write ""
}

autom8_module_diagnose() {
  AUTOM8_DIAGNOSE_PRIVATE="false"

  if autom8_diagnose_is_private "$@"; then
    AUTOM8_DIAGNOSE_PRIVATE="true"
  fi

  local timestamp
  local report_prefix
  timestamp="$(date '+%Y-%m-%d-%H%M')"

  if [[ "$AUTOM8_DIAGNOSE_PRIVATE" == "true" ]]; then
    report_prefix="diagnostic-private"
  else
    report_prefix="diagnostic"
  fi

  mkdir -p "$AUTOM8_REPORT_DIR"
  AUTOM8_DIAGNOSE_REPORT_FILE="$AUTOM8_REPORT_DIR/${report_prefix}-${timestamp}.txt"

  {
    printf 'AutoM8 - Linux Management Suite\n'
    printf 'Relatório de Diagnóstico\n'
    printf 'Gerado em: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
    printf 'Modo privado: %s\n' "$AUTOM8_DIAGNOSE_PRIVATE"
    printf '\n'
  } > "$AUTOM8_DIAGNOSE_REPORT_FILE"

  if [[ "$AUTOM8_DIAGNOSE_PRIVATE" == "true" ]]; then
    autom8_header "Diagnóstico privado" "Relatório sanitizado para compartilhamento."
    autom8_warn_ui "Modo privado ativo: dados sensíveis serão ocultados ou reduzidos."
  else
    autom8_header "Diagnóstico do sistema" "Relatório completo local."
  fi

  autom8_diagnose_system
  autom8_diagnose_run "CPU" bash -c '
    if command -v lscpu >/dev/null 2>&1; then
      lscpu | sed -n "1,20p"
    else
      grep -m1 "model name" /proc/cpuinfo 2>/dev/null || true
    fi
  '
  autom8_diagnose_run "Memória" bash -c 'free -h 2>/dev/null || true'
  autom8_diagnose_run "Disco" bash -c 'df -hT 2>/dev/null || true'
  autom8_diagnose_network
  autom8_diagnose_dns
  autom8_diagnose_services
  autom8_diagnose_firewall
  autom8_diagnose_ports
  autom8_diagnose_docker
  autom8_diagnose_users
  autom8_diagnose_graphical_session

  autom8_log_info "diagnostic" "Diagnostic report generated: $AUTOM8_DIAGNOSE_REPORT_FILE"

  if [[ "$AUTOM8_DIAGNOSE_PRIVATE" == "true" ]]; then
    autom8_success "Relatório privado gerado em: $AUTOM8_DIAGNOSE_REPORT_FILE"
    autom8_summary_ok "Diagnóstico privado gerado"
  else
    autom8_success "Relatório gerado em: $AUTOM8_DIAGNOSE_REPORT_FILE"
    autom8_summary_ok "Diagnóstico gerado"
  fi
}
