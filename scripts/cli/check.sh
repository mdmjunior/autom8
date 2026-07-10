#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common/project.sh"

log "Validando AutoM8 CLI..."

[[ -f "${CLI_DIR}/VERSION" ]] ||
  error "Arquivo de versão não encontrado."

version="$(tr -d '[:space:]' < "${CLI_DIR}/VERSION")"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
  error "Versão inválida em suite/VERSION: ${version}"
fi

log "Versão detectada: ${version}"

log "Validando sintaxe dos scripts..."

while IFS= read -r -d '' script; do
  bash -n "$script"
done < <(
  find \
    "${CLI_DIR}" \
    "${INSTALLER_DIR}" \
    "${PROJECT_ROOT}/scripts" \
    -type f \
    -name '*.sh' \
    -print0
)

log "Executando ShellCheck..."

while IFS= read -r -d '' script; do
  shellcheck "$script"
done < <(
  find \
    "${CLI_DIR}" \
    "${INSTALLER_DIR}" \
    "${PROJECT_ROOT}/scripts" \
    -type f \
    -name '*.sh' \
    -print0
)

log "Gerando catálogo consolidado..."
"${PROJECT_ROOT}/scripts/build-apps-catalog.sh"

log "Validando catálogo de apps..."
"${PROJECT_ROOT}/scripts/validate-apps-catalog.sh"

log "Validando catálogo de perfis..."
"${PROJECT_ROOT}/scripts/validate-profiles-catalog.sh"

log "Validando instalador..."
bash -n "${INSTALLER_DIR}/install.sh"

log "CLI aprovada na validação inicial."
