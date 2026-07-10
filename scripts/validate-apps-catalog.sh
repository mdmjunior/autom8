#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$PROJECT_ROOT"

python3 - <<'PY'
from pathlib import Path
import json
import re
import sys

root = Path.cwd()
source_dir = root / "suite/catalog/apps"
consolidated_file = root / "suite/catalog/apps.json"

expected_categories = {
    "desenvolvimento",
    "produtividade",
    "containers",
    "sistema",
    "rede",
    "midia",
    "design",
    "games",
    "escritorio",
    "usuario-local",
}

allowed_statuses = {"available", "advanced", "planned"}
required_package_managers = {"apt", "dnf", "zypper", "pacman"}
id_pattern = re.compile(r"^[a-z0-9][a-z0-9._-]*$")

errors = []
warnings = []

def load_json(path):
    try:
        return json.loads(path.read_text())
    except Exception as exc:
        errors.append(f"{path}: JSON inválido: {exc}")
        return None

if not source_dir.is_dir():
    errors.append(f"Diretório de categorias não encontrado: {source_dir}")

if not consolidated_file.is_file():
    errors.append(f"Catálogo consolidado não encontrado: {consolidated_file}")

source_categories = {}
source_app_ids = set()
source_apps = {}

if source_dir.is_dir():
    files = sorted(source_dir.glob("*.json"))

    if not files:
        errors.append(f"Nenhum arquivo de categoria encontrado em {source_dir}")

    for file in files:
        data = load_json(file)
        if not isinstance(data, dict):
            continue

        category = data.get("category")
        apps = data.get("apps")

        if not isinstance(category, dict):
            errors.append(f"{file}: campo category deve ser objeto")
            continue

        slug = category.get("slug")
        name = category.get("name")
        description = category.get("description")

        if not slug:
            errors.append(f"{file}: category.slug ausente")
            continue

        if slug != file.stem:
            errors.append(f"{file}: category.slug '{slug}' deve bater com o nome do arquivo '{file.stem}'")

        if not id_pattern.match(slug):
            errors.append(f"{file}: category.slug inválido: {slug}")

        if not name:
            errors.append(f"{file}: category.name ausente")

        if description is None:
            warnings.append(f"{file}: category.description ausente")

        if slug in source_categories:
            errors.append(f"Categoria duplicada: {slug}")

        source_categories[slug] = category

        if not isinstance(apps, list):
            errors.append(f"{file}: apps deve ser lista")
            continue

        if not apps:
            warnings.append(f"{file}: categoria sem apps")

        for index, app in enumerate(apps):
            prefix = f"{file}: apps[{index}]"

            if not isinstance(app, dict):
                errors.append(f"{prefix}: app deve ser objeto")
                continue

            app_id = app.get("id")
            name = app.get("name")
            summary = app.get("summary")
            status = app.get("status", "available")
            packages = app.get("packages")
            tags = app.get("tags", [])
            notes = app.get("notes", [])

            if not app_id:
                errors.append(f"{prefix}: id ausente")
                continue

            if not id_pattern.match(app_id):
                errors.append(f"{prefix}: id inválido: {app_id}")

            if app_id in source_app_ids:
                errors.append(f"App duplicado: {app_id}")

            source_app_ids.add(app_id)
            source_apps[app_id] = app

            if not name:
                errors.append(f"{prefix}: name ausente")

            if not summary:
                errors.append(f"{prefix}: summary ausente")

            if status not in allowed_statuses:
                errors.append(f"{prefix}: status inválido '{status}'. Permitidos: {sorted(allowed_statuses)}")

            if not isinstance(tags, list):
                errors.append(f"{prefix}: tags deve ser lista")

            if not isinstance(notes, list):
                errors.append(f"{prefix}: notes deve ser lista")

            if not isinstance(packages, dict):
                errors.append(f"{prefix}: packages deve ser objeto")
                continue

            missing_pms = required_package_managers - set(packages.keys())
            if missing_pms:
                errors.append(f"{prefix}: packages sem gerenciadores: {sorted(missing_pms)}")

            for pm in required_package_managers:
                values = packages.get(pm)

                if not isinstance(values, list):
                    errors.append(f"{prefix}: packages.{pm} deve ser lista")
                    continue

                if not values:
                    errors.append(f"{prefix}: packages.{pm} está vazio")

                for value in values:
                    if not isinstance(value, str) or not value.strip():
                        errors.append(f"{prefix}: packages.{pm} contém pacote vazio/inválido")

missing_categories = expected_categories - set(source_categories.keys())
extra_categories = set(source_categories.keys()) - expected_categories

if missing_categories:
    errors.append(f"Categorias obrigatórias ausentes: {sorted(missing_categories)}")

if extra_categories:
    warnings.append(f"Categorias extras encontradas: {sorted(extra_categories)}")

if consolidated_file.is_file():
    consolidated = load_json(consolidated_file)

    if isinstance(consolidated, dict):
        schema = consolidated.get("schema")
        categories = consolidated.get("categories")
        apps = consolidated.get("apps")

        if schema != 2:
            errors.append(f"{consolidated_file}: schema esperado 2, encontrado {schema}")

        if not isinstance(categories, list):
            errors.append(f"{consolidated_file}: categories deve ser lista")
            categories = []

        if not isinstance(apps, list):
            errors.append(f"{consolidated_file}: apps deve ser lista")
            apps = []

        consolidated_categories = {
            item.get("slug")
            for item in categories
            if isinstance(item, dict)
        }

        consolidated_app_ids = {
            item.get("id")
            for item in apps
            if isinstance(item, dict)
        }

        if source_categories and consolidated_categories != set(source_categories.keys()):
            errors.append(
                "Categorias do consolidado divergentes das fontes. "
                f"Fonte={sorted(source_categories.keys())}; consolidado={sorted(consolidated_categories)}"
            )

        if source_app_ids and consolidated_app_ids != source_app_ids:
            errors.append(
                "Apps do consolidado divergentes das fontes. "
                f"Fonte={len(source_app_ids)}; consolidado={len(consolidated_app_ids)}"
            )

        for item in apps:
            if not isinstance(item, dict):
                continue

            app_id = item.get("id")
            category = item.get("category")
            status = item.get("status", "available")

            if app_id and app_id in source_apps:
                source_app = source_apps[app_id]
                if status != source_app.get("status", "available"):
                    errors.append(f"{consolidated_file}: status divergente para {app_id}")

            if category not in source_categories:
                errors.append(f"{consolidated_file}: app {app_id} referencia categoria inexistente: {category}")

if errors:
    print("Validação do catálogo falhou:", file=sys.stderr)
    for error in errors:
        print(f"  [ERRO] {error}", file=sys.stderr)

    if warnings:
        print("", file=sys.stderr)
        print("Avisos:", file=sys.stderr)
        for warning in warnings:
            print(f"  [AVISO] {warning}", file=sys.stderr)

    sys.exit(1)

print("Catálogo de apps válido.")
print(f"Categorias: {len(source_categories)}")
print(f"Apps: {len(source_app_ids)}")

if warnings:
    print("Avisos:")
    for warning in warnings:
        print(f"  [AVISO] {warning}")
PY
