#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common/project.sh"

require_command awk
require_command cargo
require_command jq
require_command pkg-config
require_command python3
require_command rustc

log "Validando a fundação Rust do AutoM8..."

[[ -f "${CLI_DIR}/VERSION" ]] ||
  error "Arquivo de versão estável não encontrado."

[[ -f "${CLI_DIR}/Cargo.toml" ]] ||
  error "Workspace Cargo não encontrado."

[[ -f "${CLI_DIR}/Cargo.lock" ]] ||
  error "Cargo.lock não encontrado. Execute 'cd suite && cargo generate-lockfile'."

readarray -t detected_versions < <(
  python3 - "${CLI_DIR}/VERSION" "${CLI_DIR}/Cargo.toml" <<'PY'
import re
import sys
import tomllib
from pathlib import Path

stable = Path(sys.argv[1]).read_text(encoding="utf-8").strip()
with Path(sys.argv[2]).open("rb") as cargo_file:
    development = tomllib.load(cargo_file)["workspace"]["package"]["version"]

pattern = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?$")
if not pattern.fullmatch(stable):
    raise SystemExit(f"Versão estável inválida: {stable!r}")
if not pattern.fullmatch(development):
    raise SystemExit(f"Versão de desenvolvimento inválida: {development!r}")
if not development.endswith("-alpha.1"):
    raise SystemExit(
        f"A Etapa 1 exige versão de desenvolvimento alpha.1; encontrada {development!r}"
    )

print(stable)
print(development)
PY
)

stable_version="${detected_versions[0]:-}"
development_version="${detected_versions[1]:-}"

[[ -n "$stable_version" && -n "$development_version" ]] ||
  error "Não foi possível detectar as versões do projeto."

log "Versão estável preservada: ${stable_version}"
log "Versão em desenvolvimento: ${development_version}"

rustc_output="$(rustc --version)"
rustc_version="$(awk '{ print $2 }' <<< "$rustc_output")"
python3 - "$rustc_version" <<'PY'
import sys

def numeric(version: str) -> tuple[int, int, int]:
    base = version.split("-", maxsplit=1)[0]
    parts = tuple(int(part) for part in base.split("."))
    if len(parts) != 3:
        raise ValueError(version)
    return parts

detected = numeric(sys.argv[1])
minimum = (1, 85, 0)
if detected < minimum:
    raise SystemExit(
        f"rustc {sys.argv[1]} é antigo; a versão mínima é 1.85.0"
    )
PY

pkg-config --exists gtk4 ||
  error "Biblioteca de desenvolvimento GTK 4 não encontrada pelo pkg-config."
pkg-config --exists libadwaita-1 ||
  error "Biblioteca de desenvolvimento libadwaita não encontrada pelo pkg-config."

log "Validando catálogos estáveis preservados..."
"${PROJECT_ROOT}/scripts/build-apps-catalog.sh"
"${PROJECT_ROOT}/scripts/validate-apps-catalog.sh"
"${PROJECT_ROOT}/scripts/validate-profiles-catalog.sh"

log "Validando o instalador estável preservado..."
"${PROJECT_ROOT}/scripts/cli/check-installer.sh"

log "Validando metadados Cargo e formatação..."
cargo metadata \
  --manifest-path "${CLI_DIR}/Cargo.toml" \
  --locked \
  --no-deps \
  --format-version 1 >/dev/null
cargo fmt \
  --manifest-path "${CLI_DIR}/Cargo.toml" \
  --all \
  -- \
  --check

log "Executando Clippy..."
cargo clippy \
  --manifest-path "${CLI_DIR}/Cargo.toml" \
  --workspace \
  --all-targets \
  --locked \
  -- \
  -D warnings

log "Executando testes Rust..."
cargo test \
  --manifest-path "${CLI_DIR}/Cargo.toml" \
  --workspace \
  --all-targets \
  --locked

log "Gerando binários release..."
cargo build \
  --manifest-path "${CLI_DIR}/Cargo.toml" \
  --workspace \
  --release \
  --locked

cli_binary="${CLI_DIR}/target/release/autom8"
gui_binary="${CLI_DIR}/target/release/autom8-gnome"

[[ -x "$cli_binary" ]] ||
  error "Binário da CLI não foi gerado: ${cli_binary}"
[[ -x "$gui_binary" ]] ||
  error "Binário da interface GNOME não foi gerado: ${gui_binary}"

log "Executando smoke test da CLI..."
version_output="$("$cli_binary" --version)"
[[ "$version_output" == "autom8 ${development_version}" ]] ||
  error "Saída inesperada de --version: ${version_output}"

"$cli_binary" --help | grep -Fq 'Usage:' ||
  error "A ajuda da CLI não apresentou Usage."

plain_output="$(NO_COLOR=1 "$cli_binary" --no-color)"
[[ "$plain_output" == *"AutoM8 ${development_version}"* ]] ||
  error "O banner não apresentou produto e versão."

if [[ "$plain_output" == *$'\033['* ]]; then
  error "A saída sem cores contém sequência ANSI."
fi

if "$cli_binary" status >/dev/null 2>&1; then
  error "O comando ainda não implementado 'status' deveria falhar."
fi

log "Fundação da CLI aprovada."
