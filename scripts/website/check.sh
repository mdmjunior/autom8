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

log "Executando build transitório atual do site..."
"${PROJECT_ROOT}/scripts/build-site.sh"

[[ -f "${WEBSITE_DIR}/dist/index.html" ]] ||
  error "Build não gerou site/dist/index.html."

log "Website aprovado na validação inicial."
