#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common/project.sh"

canonical="${INSTALLER_DIR}/install.sh"
public="${WEBSITE_DIR}/public/install.sh"

[[ -f "$canonical" ]] ||
  error "Instalador canônico não encontrado: ${canonical}"

[[ -f "$public" ]] ||
  error "Espelho público não encontrado: ${public}"

bash -n "$canonical"
bash -n "$public"

cmp -s "$canonical" "$public" ||
  error "O espelho público divergiu. Execute ./scripts/cli/sync-installer.sh."

grep -q 'releases/latest/download/autom8-latest.tar.gz' "$canonical" ||
  error "O instalador não aponta para autom8-latest.tar.gz."

required_tokens=(
  git
  wget
  net-tools
  dnsutils
  bind-utils
  bind
  ifconfig
  netstat
  dig
  nslookup
  tree
)

for token in "${required_tokens[@]}"; do
  grep -q "$token" "$canonical" ||
    error "Token obrigatório ausente no instalador: ${token}"
done

log "Instalador canônico e espelho público aprovados."
