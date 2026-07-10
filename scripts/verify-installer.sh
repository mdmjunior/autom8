#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CANONICAL="$PROJECT_ROOT/installer/install.sh"
PUBLIC="$PROJECT_ROOT/site/public/install.sh"

if [[ ! -f "$CANONICAL" ]]; then
  echo "ERRO: instalador canônico não encontrado: $CANONICAL" >&2
  exit 1
fi

if [[ ! -f "$PUBLIC" ]]; then
  echo "ERRO: instalador público não encontrado: $PUBLIC" >&2
  exit 1
fi

bash -n "$CANONICAL"
bash -n "$PUBLIC"

if ! cmp -s "$CANONICAL" "$PUBLIC"; then
  echo "ERRO: site/public/install.sh está diferente de installer/install.sh." >&2
  echo "Corrija com:" >&2
  echo "  cp installer/install.sh site/public/install.sh" >&2
  exit 1
fi

grep -q 'releases/latest/download/autom8-latest.tar.gz' "$PUBLIC"

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
  if ! grep -q "$token" "$CANONICAL"; then
    echo "ERRO: token obrigatório não encontrado no instalador: $token" >&2
    exit 1
  fi
done

echo "Instalador canônico e público estão consistentes."
