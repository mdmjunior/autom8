#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$PROJECT_ROOT"

log() {
  printf '\033[1;34m[AutoM8 Fedora Smoke]\033[0m %s\n' "$1"
}

warn() {
  printf '\033[1;33m[AutoM8 Fedora Smoke]\033[0m %s\n' "$1"
}

error() {
  printf '\033[1;31m[AutoM8 Fedora Smoke]\033[0m %s\n' "$1" >&2
}

run_optional() {
  local label="$1"
  shift

  log "$label"

  if "$@"; then
    log "OK: $label"
    return 0
  fi

  if [[ "${AUTOM8_FEDORA_STRICT:-0}" == "1" ]]; then
    error "Falhou em modo estrito: $label"
    return 1
  fi

  warn "Falhou em modo não estrito: $label"
  warn "Isso pode indicar pacote indisponível no Fedora ou ajuste pendente no catálogo."
  return 0
}

require_command() {
  local cmd="$1"

  if ! command -v "$cmd" >/dev/null 2>&1; then
    error "Comando obrigatório ausente: $cmd"
    return 1
  fi
}

detect_os() {
  if [[ ! -f /etc/os-release ]]; then
    warn "Não foi possível detectar /etc/os-release."
    return 0
  fi

  # shellcheck source=/dev/null
  source /etc/os-release

  log "Sistema detectado: ${PRETTY_NAME:-unknown}"

  if [[ "${ID:-}" != "fedora" ]]; then
    warn "Este smoke foi pensado para Fedora Workstation. Prosseguindo mesmo assim."
  fi
}

validate_required_commands() {
  log "Validando comandos básicos do ambiente Fedora."

  local required=(
    bash
    awk
    sed
    grep
    find
    tar
    gzip
    curl
    git
    jq
    dnf
    rpm
  )

  local missing=0
  local cmd

  for cmd in "${required[@]}"; do
    if require_command "$cmd"; then
      printf '  [OK] %s\n' "$cmd"
    else
      printf '  [FALHA] %s\n' "$cmd"
      missing=$((missing + 1))
    fi
  done

  if [[ "$missing" -gt 0 ]]; then
    error "Instale as dependências mínimas antes de rodar o smoke:"
    error "sudo dnf install -y git curl jq tar gzip"
    exit 1
  fi
}

validate_shell() {
  log "Validando sintaxe shell."

  bash -n suite/bin/autom8

  find suite -name "*.sh" -print -exec bash -n {} \;
  find scripts -name "*.sh" -print -exec bash -n {} \;
}

validate_catalogs() {
  log "Gerando e validando catálogos."

  ./scripts/build-apps-catalog.sh
  ./scripts/validate-apps-catalog.sh
  ./scripts/validate-profiles-catalog.sh

  python3 -m json.tool suite/catalog/apps.json >/dev/null
  python3 -m json.tool suite/catalog/profiles.json >/dev/null
}

validate_installer() {
  log "Validando instalador."

  ./scripts/verify-installer.sh
}

run_cli_smoke() {
  log "Executando comandos básicos da CLI."

  ./suite/bin/autom8 --version
  ./suite/bin/autom8 --help

  ./suite/bin/autom8 doctor || {
    warn "doctor retornou aviso/falha. Isso pode ser aceitável fora de uma instalação oficial."
  }

  ./suite/bin/autom8 apps categories
  ./suite/bin/autom8 apps list --category sistema
  ./suite/bin/autom8 apps list --category desenvolvimento
  ./suite/bin/autom8 apps list --category rede
  ./suite/bin/autom8 apps show git
  ./suite/bin/autom8 apps show htop
  ./suite/bin/autom8 apps show steam

  ./suite/bin/autom8 profiles list
  ./suite/bin/autom8 profiles show dev-essential
  ./suite/bin/autom8 profiles show server-basic
}

run_strict_dry_run_smoke() {
  log "Executando dry-runs estritos com apps básicos."

  ./suite/bin/autom8 --dry-run apps install git
  ./suite/bin/autom8 --dry-run apps install htop
  ./suite/bin/autom8 --dry-run apps install jq
  ./suite/bin/autom8 --dry-run apps install-many git htop jq

  if ./suite/bin/autom8 --dry-run apps install steam; then
    error "steam deveria estar bloqueado por status advanced."
    exit 1
  else
    log "Bloqueio de app advanced validado: steam."
  fi
}

run_exploratory_dry_run_smoke() {
  log "Executando dry-runs exploratórios Fedora."

  run_optional "Dry-run categoria sistema" \
    ./suite/bin/autom8 --dry-run apps install-category sistema

  run_optional "Dry-run categoria desenvolvimento" \
    ./suite/bin/autom8 --dry-run apps install-category desenvolvimento

  run_optional "Dry-run categoria rede" \
    ./suite/bin/autom8 --dry-run apps install-category rede

  run_optional "Dry-run perfil dev-essential" \
    ./suite/bin/autom8 --dry-run profiles install dev-essential

  run_optional "Dry-run perfil server-basic" \
    ./suite/bin/autom8 --dry-run profiles install server-basic
}

run_package_smoke() {
  log "Gerando pacote local temporário."

  ./scripts/package.sh

  local package_dir
  package_dir="$(find /tmp -maxdepth 1 -type d -name 'autom8-package-*' | sort | tail -n 1)"

  if [[ -z "$package_dir" ]]; then
    error "Diretório de pacote não encontrado em /tmp."
    exit 1
  fi

  log "Pacote encontrado: $package_dir"

  test -f "$package_dir/autom8-latest.tar.gz"

  tar -tzf "$package_dir/autom8-latest.tar.gz" | grep -E '(^./bin/autom8$|bin/autom8$)' >/dev/null
  tar -tzf "$package_dir/autom8-latest.tar.gz" | grep -E '(^./catalog/apps.json$|catalog/apps.json$)' >/dev/null
  tar -tzf "$package_dir/autom8-latest.tar.gz" | grep -E '(^./catalog/profiles.json$|catalog/profiles.json$)' >/dev/null
  tar -tzf "$package_dir/autom8-latest.tar.gz" | grep -E '(^./modules/apps.sh$|modules/apps.sh$)' >/dev/null
  tar -tzf "$package_dir/autom8-latest.tar.gz" | grep -E '(^./modules/profiles.sh$|modules/profiles.sh$)' >/dev/null
  tar -tzf "$package_dir/autom8-latest.tar.gz" | grep -E '(^./lib/apps/catalog.sh$|lib/apps/catalog.sh$)' >/dev/null

  log "Pacote validado."
}

main() {
  log "Iniciando smoke test AutoM8 em Fedora Workstation."

  detect_os
  validate_required_commands
  validate_shell
  validate_catalogs
  validate_installer
  run_cli_smoke
  run_strict_dry_run_smoke
  run_exploratory_dry_run_smoke
  run_package_smoke

  echo
  log "Smoke test Fedora concluído."
  echo
  echo "Observação:"
  echo "  Por padrão, categorias/perfis em Fedora rodam em modo exploratório."
  echo "  Para transformar falhas exploratórias em erro, rode:"
  echo "  AUTOM8_FEDORA_STRICT=1 ./scripts/smoke-fedora-workstation.sh"
}

main "$@"
