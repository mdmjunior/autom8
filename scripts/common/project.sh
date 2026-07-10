#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

CLI_DIR="${PROJECT_ROOT}/suite"
INSTALLER_DIR="${PROJECT_ROOT}/installer"
WEBSITE_DIR="${PROJECT_ROOT}/site"
INFRA_DIR="${PROJECT_ROOT}/infra"
PACKAGES_DIR="${PROJECT_ROOT}/packages"

export PROJECT_ROOT
export CLI_DIR
export INSTALLER_DIR
export WEBSITE_DIR
export INFRA_DIR
export PACKAGES_DIR

log() {
  printf '[AutoM8] %s\n' "$*"
}

error() {
  printf '[AutoM8] ERRO: %s\n' "$*" >&2
  exit 1
}

require_command() {
  local command_name="$1"

  command -v "$command_name" >/dev/null 2>&1 ||
    error "Comando obrigatório não encontrado: ${command_name}"
}
