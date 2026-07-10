#!/usr/bin/env bash
set -euo pipefail

AUTOM8_BIN="${AUTOM8_BIN:-/opt/autom8/bin/autom8}"
EXPECTED_VERSION="${AUTOM8_EXPECTED_VERSION:-0.2.0-rc1}"

log() {
  printf '\033[1;34m[AutoM8 Installed RC]\033[0m %s\n' "$1"
}

warn() {
  printf '\033[1;33m[AutoM8 Installed RC]\033[0m %s\n' "$1"
}

error() {
  printf '\033[1;31m[AutoM8 Installed RC]\033[0m %s\n' "$1" >&2
}

if [[ ! -x "$AUTOM8_BIN" ]]; then
  warn "AutoM8 não encontrado no caminho padrão ou sem permissão: $AUTOM8_BIN"
  warn "Procurando binário alternativo em /opt/autom8..."

  FOUND_BIN="$(find /opt/autom8 -maxdepth 5 -type f -path '*/bin/autom8' 2>/dev/null | head -n 1 || true)"

  if [[ -n "$FOUND_BIN" ]]; then
    warn "Binário encontrado em caminho alternativo: $FOUND_BIN"
    warn "Use AUTOM8_BIN=$FOUND_BIN para validar, ou reinstale com o instalador corrigido."
    AUTOM8_BIN="$FOUND_BIN"
  else
    error "AutoM8 não encontrado."
    error "Conteúdo atual de /opt/autom8:"
    find /opt/autom8 -maxdepth 4 -print 2>/dev/null | sed -n '1,120p' || true
    exit 1
  fi
fi

version="$("$AUTOM8_BIN" --version | tr -d '[:space:]')"

log "Versão detectada: $version"

if [[ "$version" != *"$EXPECTED_VERSION"* ]]; then
  error "Versão inesperada. Esperado conter: $EXPECTED_VERSION"
  exit 1
fi

"$AUTOM8_BIN" doctor || warn "doctor retornou avisos/falhas."

"$AUTOM8_BIN" apps categories
"$AUTOM8_BIN" apps list --category sistema
"$AUTOM8_BIN" apps list --category desenvolvimento
"$AUTOM8_BIN" apps show git
"$AUTOM8_BIN" apps show steam

"$AUTOM8_BIN" profiles list
"$AUTOM8_BIN" profiles show dev-essential
"$AUTOM8_BIN" profiles show server-basic

"$AUTOM8_BIN" --dry-run apps install git
"$AUTOM8_BIN" --dry-run apps install-many git htop jq
"$AUTOM8_BIN" --dry-run apps install-category sistema
"$AUTOM8_BIN" --dry-run profiles install dev-essential

if "$AUTOM8_BIN" --dry-run apps install steam; then
  error "steam deveria estar bloqueado por status advanced."
  exit 1
else
  log "Bloqueio de app advanced validado: steam."
fi

log "Verificação pós-instalação RC concluída."
