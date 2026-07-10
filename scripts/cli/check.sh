#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common/project.sh"

require_command jq
require_command python3

log "Validando AutoM8 CLI..."

[[ -f "${CLI_DIR}/VERSION" ]] ||
  error "Arquivo de versão não encontrado."

version="$(tr -d '[:space:]' < "${CLI_DIR}/VERSION")"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
  error "Versão inválida em suite/VERSION: ${version}"
fi

log "Versão detectada: ${version}"

log "Gerando catálogo consolidado..."
"${PROJECT_ROOT}/scripts/build-apps-catalog.sh"

log "Validando catálogo de apps..."
"${PROJECT_ROOT}/scripts/validate-apps-catalog.sh"

log "Validando catálogo de perfis..."
"${PROJECT_ROOT}/scripts/validate-profiles-catalog.sh"

log "Validando instalador..."
"${PROJECT_ROOT}/scripts/cli/check-installer.sh"

log "CLI aprovada."
