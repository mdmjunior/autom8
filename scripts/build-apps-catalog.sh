#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$PROJECT_ROOT/suite/catalog/apps"
OUTPUT_FILE="$PROJECT_ROOT/suite/catalog/apps.json"

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "ERRO: diretório de categorias não encontrado: $SOURCE_DIR" >&2
  exit 1
fi

python3 - <<'PY'
import json
from pathlib import Path

root = Path.cwd()
source_dir = root / "suite/catalog/apps"
output_file = root / "suite/catalog/apps.json"
version = (root / "suite/VERSION").read_text().strip()

category_files = sorted(source_dir.glob("*.json"))
apps = []
categories = []
seen_ids = set()

for file in category_files:
    data = json.loads(file.read_text())

    slug = data["category"]["slug"]
    name = data["category"]["name"]
    description = data["category"].get("description", "")

    categories.append({
        "slug": slug,
        "name": name,
        "description": description,
        "file": str(file.relative_to(root))
    })

    for app in data.get("apps", []):
        app_id = app["id"]

        if app_id in seen_ids:
            raise SystemExit(f"App duplicado no catálogo: {app_id}")

        seen_ids.add(app_id)
        app["category"] = slug
        app["categoryName"] = name
        app.setdefault("status", "available")
        app.setdefault("tags", [])
        app.setdefault("notes", [])

        apps.append(app)

output = {
    "schema": 2,
    "version": version,
    "updatedAt": "2026-07-10",
    "source": "suite/catalog/apps/*.json",
    "categories": categories,
    "apps": apps
}

output_file.parent.mkdir(parents=True, exist_ok=True)
output_file.write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n")

print(f"Catálogo consolidado gerado: {output_file}")
print(f"Categorias: {len(categories)}")
print(f"Apps: {len(apps)}")
PY

if [[ -x "$PROJECT_ROOT/scripts/validate-apps-catalog.sh" && "${AUTOM8_SKIP_APPS_CATALOG_VALIDATE:-0}" != "1" ]]; then
  "$PROJECT_ROOT/scripts/validate-apps-catalog.sh"
fi
