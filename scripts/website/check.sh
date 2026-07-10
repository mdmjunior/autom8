#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common/project.sh"

log "Validando AutoM8 Website..."

[[ -f "${WEBSITE_DIR}/package.json" ]] ||
  error "site/package.json não encontrado."

[[ -f "${WEBSITE_DIR}/package-lock.json" ]] ||
  error "site/package-lock.json não encontrado."

"${PROJECT_ROOT}/scripts/website/build.sh"

required_files=(
  "${WEBSITE_DIR}/dist/index.html"
  "${WEBSITE_DIR}/dist/install.sh"
  "${WEBSITE_DIR}/dist/healthz"
)

for required_file in "${required_files[@]}"; do
  [[ -f "$required_file" ]] ||
    error "Arquivo obrigatório não gerado: ${required_file}"
done

log "Website aprovado."
