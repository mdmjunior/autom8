#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/project.sh"

require_command git
require_command python3
require_command shellcheck

cd "$PROJECT_ROOT"

log "Validando sintaxe e qualidade dos scripts shell..."

checked_scripts=0

while IFS= read -r -d '' script; do
  if ! bash -n "$script"; then
    error "Erro de sintaxe em: ${script}"
  fi

  if ! shellcheck "$script"; then
    error "ShellCheck reprovou: ${script}"
  fi

  ((checked_scripts += 1))
done < <(
  find \
    suite \
    installer \
    scripts \
    infra \
    -type f \
    -name '*.sh' \
    -print0
)

log "Scripts aprovados: ${checked_scripts}"
log "Validando arquivos JSON..."

checked_json=0

while IFS= read -r -d '' json_file; do
  if ! python3 -m json.tool "$json_file" >/dev/null; then
    error "JSON inválido: ${json_file}"
  fi

  ((checked_json += 1))
done < <(
  find \
    docs \
    site \
    suite \
    \( \
      -path 'site/node_modules' -o \
      -path 'site/dist' -o \
      -path 'site/.astro' \
    \) -prune -o \
    -type f \
    -name '*.json' \
    -print0
)

log "Arquivos JSON aprovados: ${checked_json}"
log "Validando fontes de versão..."

python3 - <<'PY'
import json
import sys
from pathlib import Path

version = Path("suite/VERSION").read_text().strip()

checks = {
    "suite/catalog/apps.json": (
        json.loads(Path("suite/catalog/apps.json").read_text())
        .get("version")
    ),
    "docs/source/autom8-docs.json": (
        json.loads(Path("docs/source/autom8-docs.json").read_text())
        .get("product", {})
        .get("currentVersion")
    ),
    "site/src/data/documentation.json": (
        json.loads(Path("site/src/data/documentation.json").read_text())
        .get("product", {})
        .get("currentVersion")
    ),
}

errors = []

for filename, detected in checks.items():
    if detected != version:
        errors.append(
            f"{filename}: versão {detected!r}; esperada {version!r}"
        )

if errors:
    for error in errors:
        print(f"[ERRO] {error}", file=sys.stderr)

    raise SystemExit(1)

print(f"Versão consistente: {version}")
PY

log "Verificando arquivos executáveis..."

required_executables=(
  suite/bin/autom8
  installer/install.sh
  scripts/check.sh
  scripts/cli/check.sh
  scripts/website/check.sh
)

for executable in "${required_executables[@]}"; do
  [[ -x "$executable" ]] ||
    error "Arquivo deveria ser executável: ${executable}"
done

log "Verificando resíduos de estruturas antigas..."

legacy_paths=(
  suite/catalog/appimage.yaml
  suite/catalog/apps-fedora.yaml
  suite/catalog/apps-ubuntu.yaml
  suite/catalog/external-repos.yaml
  suite/catalog/flatpak.yaml
  suite/catalog/snap.yaml
  suite/profiles
)

for legacy_path in "${legacy_paths[@]}"; do
  [[ ! -e "$legacy_path" ]] ||
    error "Caminho legado ainda presente: ${legacy_path}"
done

legacy_references="$(
  git grep -n -F 'feature/apps-v0.2' -- \
    scripts \
    installer \
    suite \
    infra \
    site \
    2>/dev/null || true
)"

if [[ -n "$legacy_references" ]]; then
  printf '%s\n' "$legacy_references" >&2
  error "Foram encontradas referências à branch antiga."
fi

log "Verificando artefatos indevidamente rastreados..."

mapfile -t tracked_runtime_files < <(
  git ls-files \
    'site/node_modules/**' \
    'site/dist/**' \
    'site/.astro/**' \
    'suite/logs/**' \
    'suite/tmp/**' \
    'suite/backups/**' \
    'suite/reports/**' |
    grep -vE '/(\.keep|\.gitkeep)$' || true
)

if (( ${#tracked_runtime_files[@]} > 0 )); then
  printf '  %s\n' "${tracked_runtime_files[@]}" >&2
  error "Arquivos de build ou runtime estão rastreados pelo Git."
fi

git diff --check

log "Integridade geral do repositório aprovada."
