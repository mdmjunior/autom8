#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$PROJECT_ROOT"

python3 - <<'PY'
from pathlib import Path
import json
import re
import sys

apps_path = Path("suite/catalog/apps.json")
profiles_path = Path("suite/catalog/profiles.json")

errors = []
warnings = []

id_pattern = re.compile(r"^[a-z0-9][a-z0-9._-]*$")

if not apps_path.exists():
    errors.append(f"Catálogo de apps não encontrado: {apps_path}")

if not profiles_path.exists():
    errors.append(f"Catálogo de perfis não encontrado: {profiles_path}")

if errors:
    for error in errors:
        print(f"[ERRO] {error}", file=sys.stderr)
    sys.exit(1)

try:
    apps_data = json.loads(apps_path.read_text())
except Exception as exc:
    print(f"[ERRO] Apps JSON inválido: {exc}", file=sys.stderr)
    sys.exit(1)

try:
    profiles_data = json.loads(profiles_path.read_text())
except Exception as exc:
    print(f"[ERRO] Profiles JSON inválido: {exc}", file=sys.stderr)
    sys.exit(1)

apps = apps_data.get("apps", [])
profiles = profiles_data.get("profiles", [])

if not isinstance(apps, list):
    errors.append("suite/catalog/apps.json: apps deve ser lista")
    apps = []

if not isinstance(profiles, list):
    errors.append("suite/catalog/profiles.json: profiles deve ser lista")
    profiles = []

apps_by_id = {
    app.get("id"): app
    for app in apps
    if isinstance(app, dict) and app.get("id")
}

profile_ids = set()

for index, profile in enumerate(profiles):
    prefix = f"profiles[{index}]"

    if not isinstance(profile, dict):
        errors.append(f"{prefix}: perfil deve ser objeto")
        continue

    profile_id = profile.get("id")
    name = profile.get("name")
    summary = profile.get("summary")
    profile_apps = profile.get("apps")

    if not profile_id:
        errors.append(f"{prefix}: id ausente")
        continue

    if not id_pattern.match(profile_id):
        errors.append(f"{prefix}: id inválido: {profile_id}")

    if profile_id in profile_ids:
        errors.append(f"Perfil duplicado: {profile_id}")

    profile_ids.add(profile_id)

    if not name:
        errors.append(f"{prefix}: name ausente")

    if not summary:
        errors.append(f"{prefix}: summary ausente")

    if not isinstance(profile_apps, list) or not profile_apps:
        errors.append(f"{prefix}: apps deve ser lista não vazia")
        continue

    seen_apps = set()

    for app_id in profile_apps:
        if app_id in seen_apps:
            errors.append(f"{prefix}: app duplicado no perfil: {app_id}")

        seen_apps.add(app_id)

        app = apps_by_id.get(app_id)

        if not app:
            errors.append(f"{prefix}: app inexistente no catálogo: {app_id}")
            continue

        status = app.get("status", "available")

        if status != "available":
            warnings.append(f"{prefix}: app {app_id} tem status {status}; será bloqueado em ação automática")

if errors:
    print("Validação do catálogo de perfis falhou:", file=sys.stderr)
    for error in errors:
        print(f"  [ERRO] {error}", file=sys.stderr)

    if warnings:
        print("", file=sys.stderr)
        print("Avisos:", file=sys.stderr)
        for warning in warnings:
            print(f"  [AVISO] {warning}", file=sys.stderr)

    sys.exit(1)

print("Catálogo de perfis válido.")
print(f"Perfis: {len(profile_ids)}")

if warnings:
    print("Avisos:")
    for warning in warnings:
        print(f"  [AVISO] {warning}")
PY
