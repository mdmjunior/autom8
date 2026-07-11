#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common/project.sh"

require_command node
require_command npm

log "Instalando dependências reproduzíveis do website..."

cd "${WEBSITE_DIR}"
npm ci

log "Construindo website..."
npm run build

[[ -f "${WEBSITE_DIR}/dist/index.html" ]] ||
  error "O build não gerou dist/index.html."

log "Build do website concluído."
