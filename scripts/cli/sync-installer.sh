#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common/project.sh"

canonical="${INSTALLER_DIR}/install.sh"
public="${WEBSITE_DIR}/public/install.sh"

[[ -f "$canonical" ]] ||
  error "Instalador canônico não encontrado: ${canonical}"

mkdir -p "$(dirname "$public")"
install -m 0755 "$canonical" "$public"

bash -n "$canonical"
bash -n "$public"

grep -q 'releases/latest/download/autom8-latest.tar.gz' "$canonical" ||
  error "O instalador não aponta para autom8-latest.tar.gz."

log "Espelho público do instalador sincronizado pela CLI."
