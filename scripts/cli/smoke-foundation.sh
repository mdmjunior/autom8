#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common/project.sh"

expected_distribution="${1:-}"

case "$expected_distribution" in
  ubuntu|fedora)
    ;;
  *)
    error "Uso: ./scripts/cli/smoke-foundation.sh [ubuntu|fedora]"
    ;;
esac

require_command awk
require_command cargo
require_command grep
require_command jq
require_command mktemp

if [[ ! -r /etc/os-release ]]; then
  error "Não foi possível ler /etc/os-release."
fi

# shellcheck source=/dev/null
source /etc/os-release

if [[ "${ID:-}" != "$expected_distribution" ]]; then
  error "Smoke destinado a ${expected_distribution}; sistema detectado: ${ID:-desconhecido}."
fi

temporary_directory="$(mktemp -d "${TMPDIR:-/tmp}/autom8-smoke-XXXXXX")"
cleanup() {
  rm -rf -- "$temporary_directory"
}
trap cleanup EXIT

log "Compilando os binários de desenvolvimento..."
cargo build \
  --manifest-path "${CLI_DIR}/Cargo.toml" \
  --workspace \
  --locked

cli_binary="${CLI_DIR}/target/debug/autom8"
gui_binary="${CLI_DIR}/target/debug/autom8-gnome"

[[ -x "$cli_binary" ]] ||
  error "Binário da CLI ausente: ${cli_binary}"
[[ -x "$gui_binary" ]] ||
  error "Binário GNOME ausente: ${gui_binary}"

log "Validando --version, --help, banner e códigos de saída..."
"$cli_binary" --version >"${temporary_directory}/version.txt"
"$cli_binary" --help >"${temporary_directory}/help.txt"
NO_COLOR=1 "$cli_binary" --no-color >"${temporary_directory}/banner.txt"

grep -Eq '^autom8 [0-9]+\.[0-9]+\.[0-9]+-alpha\.1$' \
  "${temporary_directory}/version.txt" ||
  error "Saída de --version inválida."
development_version="$(awk '{ print $2 }' "${temporary_directory}/version.txt")"
grep -Fq 'Usage:' "${temporary_directory}/help.txt" ||
  error "Saída de --help inválida."
grep -Fq "AutoM8 ${development_version}" "${temporary_directory}/banner.txt" ||
  error "Banner esperado não foi encontrado."

if grep -Fq $'\033[' "${temporary_directory}/banner.txt"; then
  error "O banner sem cores contém sequência ANSI."
fi

log "Validando o primeiro comando funcional..."
"$cli_binary" status >"${temporary_directory}/status.txt"
"$cli_binary" status --json >"${temporary_directory}/status.json"

grep -Fq 'AutoM8 · Visão geral' "${temporary_directory}/status.txt" ||
  error "Cabeçalho do status não encontrado."

jq -e '
  (.hostname | type == "string" and length > 0) and
  (.distribution.id | type == "string" and length > 0) and
  (.kernel | type == "string" and length > 0) and
  (.architecture | type == "string" and length > 0) and
  (.uptime_seconds | type == "number" and . >= 0)
' "${temporary_directory}/status.json" >/dev/null ||
  error "Contrato JSON do status é inválido."

log "Validando o plano e as verificações do Bootstrap..."
"$cli_binary" bootstrap \
  --hostname autom8-smoke \
  --timezone America/Sao_Paulo \
  --editor nano \
  --validate-network \
  --identify-hardware \
  --check \
  --json >"${temporary_directory}/bootstrap.json"

jq -e '
  (.answers.hostname == "autom8-smoke") and
  (.answers.timezone == "America/Sao_Paulo") and
  (.plan | type == "array" and length == 11) and
  (.preflight | type == "array" and length >= 4) and
  (.changes_applied == false)
' "${temporary_directory}/bootstrap.json" >/dev/null ||
  error "Contrato JSON do Bootstrap é inválido."

log "Smoke da fundação concluído em ${PRETTY_NAME:-$expected_distribution}."
