#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESULTS_DIR="$PROJECT_ROOT/docs/releases/results"
TARGET_RC="${AUTOM8_REQUIRED_RC:-0.2.0-rc2}"

log() {
  printf '\033[1;34m[AutoM8 Stable Gate]\033[0m %s\n' "$1"
}

warn() {
  printf '\033[1;33m[AutoM8 Stable Gate]\033[0m %s\n' "$1"
}

error() {
  printf '\033[1;31m[AutoM8 Stable Gate]\033[0m %s\n' "$1" >&2
}

cd "$PROJECT_ROOT"

log "Validando gate para promoção stable."
log "RC exigido: $TARGET_RC"

if [[ ! -d "$RESULTS_DIR" ]]; then
  error "Diretório de resultados não encontrado: $RESULTS_DIR"
  exit 1
fi

mapfile -t result_files < <(
  find "$RESULTS_DIR" \
    -maxdepth 1 \
    -type f \
    -name "${TARGET_RC}-*.md" \
    ! -name "*template*" \
    ! -name "*example*" \
    | sort
)

if [[ "${#result_files[@]}" -eq 0 ]]; then
  error "Nenhum resultado real encontrado para $TARGET_RC."
  error "Crie um arquivo baseado nos templates em docs/releases/results/."
  exit 1
fi

approved_count=0
vm_or_laptop_count=0

for file in "${result_files[@]}"; do
  log "Analisando: ${file#$PROJECT_ROOT/}"

  if grep -qiE 'Resultado geral:[[:space:]]*aprovado|Aprovar RC2 para stable|Aprovar .* stable' "$file"; then
    approved_count=$((approved_count + 1))
    log "Resultado aprovado encontrado."
  else
    warn "Resultado não indica aprovação clara."
  fi

  if grep -qiE '\[x\][[:space:]]*VM|\[x\][[:space:]]*Laptop|Tipo:[[:space:]]*(VM|Laptop)' "$file"; then
    vm_or_laptop_count=$((vm_or_laptop_count + 1))
    log "Ambiente VM/Laptop confirmado."
  else
    warn "Ambiente VM/Laptop não está claramente marcado."
  fi
done

if [[ "$approved_count" -eq 0 ]]; then
  error "Nenhum resultado aprovado encontrado."
  exit 1
fi

if [[ "$vm_or_laptop_count" -eq 0 ]]; then
  error "Nenhum resultado aprovado confirma VM ou Laptop."
  exit 1
fi

log "Gate aprovado."
log "Resultados aprovados: $approved_count"
log "Resultados VM/Laptop: $vm_or_laptop_count"
