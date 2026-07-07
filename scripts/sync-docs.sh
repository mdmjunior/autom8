#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_FILE="$PROJECT_ROOT/docs/source/autom8-docs.json"

if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "ERRO: fonte de documentação não encontrada: $SOURCE_FILE" >&2
  exit 1
fi

python3 - <<'PY'
import json
from pathlib import Path

root = Path.cwd()
source = json.loads((root / "docs/source/autom8-docs.json").read_text())

product = source["product"]
commands = source["commands"]
modules = source["modules"]
variables = source["variables"]
roadmap = source["roadmap"]
changelog = source["changelog"]
requirements = source["requirements"]
install = source["install"]
release_policy = source["releasePolicy"]
troubleshooting = source["troubleshooting"]

def write_text(path, content):
    path = root / path
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content.rstrip() + "\n")

def write_json(path, data):
    path = root / path
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")

def md(lines):
    return "\n".join(lines)

available = [c for c in commands if c["status"] == "available"]
partial = [c for c in commands if c["status"] == "partial"]
planned = [c for c in commands if c["status"] == "planned"]

write_json("site/src/data/docs.json", [
    {
        "command": c["command"],
        "description": c["summary"],
        "status": c["status"],
        "since": c["since"],
        "slug": c["slug"]
    }
    for c in commands
])

write_json("site/src/data/modules.json", modules)
write_json("site/src/data/roadmap.json", roadmap)
write_json("site/src/data/changelog.json", changelog)

write_json("site/src/data/documentation.json", {
    "product": product,
    "releasePolicy": release_policy,
    "install": install,
    "requirements": requirements,
    "variables": variables,
    "commands": commands,
    "modules": modules,
    "troubleshooting": troubleshooting
})

help_lines = [
    f"{product['fullName']}",
    "",
    product["summary"],
    "",
    "Uso:",
    "  autom8",
    "  autom8 help",
    "  autom8 help <comando>",
    "  autom8 --version",
    "",
    "Comandos disponíveis:"
]

for c in available:
    help_lines.append(f"  {c['command']:<24} {c['summary']}")

if partial:
    help_lines.extend(["", "Comandos parciais:"])
    for c in partial:
        help_lines.append(f"  {c['command']:<24} {c['summary']}")

if planned:
    help_lines.extend(["", "Comandos planejados:"])
    for c in planned:
        help_lines.append(f"  {c['command']:<24} {c['summary']}")

help_lines.extend([
    "",
    "Ajuda por comando:",
    "  autom8 help doctor",
    "  autom8 help clean",
    "  autom8 help update",
    "",
    f"Site: {product['siteUrl']}",
    f"Release estável: {release_policy['latestPackageUrl']}"
])

write_text("suite/docs/help.txt", "\n".join(help_lines))

for c in commands:
    lines = [
        f"{product['name']} help: {c['command']}",
        "",
        f"Status: {c['status']}",
        f"Desde: {c['since']}",
        "",
        c["summary"],
        ""
    ]

    if c["details"]:
        lines.append("Detalhes:")
        for item in c["details"]:
            lines.append(f"- {item}")
        lines.append("")

    if c["examples"]:
        lines.append("Exemplos:")
        for item in c["examples"]:
            lines.append(f"  {item}")

    write_text(f"suite/docs/help/{c['slug']}.txt", "\n".join(lines))

readme = [
    f"# {product['fullName']}",
    "",
    product["summary"],
    "",
    f"**{product['brand']}**",
    "",
    "## Site",
    "",
    product["siteUrl"],
    "",
    "## Instalação",
    "",
    "Execute com um usuário comum que tenha permissão de `sudo`:",
    "",
    "```bash",
    install["command"],
    "```",
    "",
    "Depois da instalação:",
    "",
    "```bash",
    *install["after"],
    "```",
    "",
    "## Distribuição estável",
    "",
    f"O instalador baixa a última versão estável publicada em GitHub Releases:",
    "",
    "```text",
    release_policy["latestPackageUrl"],
    "```",
    "",
    "A VPS não hospeda pacotes da suíte. O site publica o instalador e a documentação.",
    "",
    "## Comandos principais",
    "",
    "```bash",
]

for c in commands:
    readme.append(c["command"])

readme.extend([
    "```",
    "",
    "## Status dos módulos",
    "",
    "| Módulo | Comando | Status | Versão |",
    "| --- | --- | --- | --- |"
])

for m in modules:
    readme.append(f"| {m['name']} | `{m['command']}` | {m['status']} | {m['version']} |")

readme.extend([
    "",
    "## Documentação",
    "",
    "- Site: `https://autom8.oslabs.com.br/docs`",
    "- Fonte única: `docs/source/autom8-docs.json`",
    "- Help da CLI: `suite/docs/help.txt` e `suite/docs/help/`",
    "",
    "## Desenvolvimento",
    "",
    "```bash",
    "./scripts/sync-docs.sh",
    "./scripts/build-site.sh",
    "```",
    "",
    "## Release estável",
    "",
    "Após merge na `main`:",
    "",
    "```bash",
    "./scripts/release-stable.sh",
    "```",
    "",
    "## Créditos",
    "",
    f"{product['brand']}.",
    "",
    "Criado por Marcio Moreira Junior para a comunidade Linux."
])

write_text("README.md", md(readme))

docs_readme = [
    "# Documentação do AutoM8",
    "",
    "A documentação oficial é gerada a partir de uma fonte única:",
    "",
    "```text",
    "docs/source/autom8-docs.json",
    "```",
    "",
    "Esse arquivo alimenta:",
    "",
    "- README.md",
    "- site/src/data/docs.json",
    "- site/src/data/modules.json",
    "- site/src/data/roadmap.json",
    "- site/src/data/changelog.json",
    "- site/src/data/documentation.json",
    "- suite/docs/help.txt",
    "- suite/docs/help/<comando>.txt",
    "",
    "Para sincronizar:",
    "",
    "```bash",
    "./scripts/sync-docs.sh",
    "```"
]

write_text("docs/README.md", md(docs_readme))

releases_md = [
    "# Releases do AutoM8",
    "",
    "Pacotes estáveis devem ser publicados somente no GitHub Releases.",
    "",
    "## Política",
    "",
    f"- Fonte estável: {release_policy['stableSource']}",
    f"- Pacote latest: `{release_policy['latestPackageUrl']}`",
    f"- Padrão versionado: `{release_policy['versionedPackagePattern']}`",
    "",
    "A VPS e o ambiente local de desenvolvimento não devem manter pacotes publicados da suíte.",
    "",
    "## Publicar release",
    "",
    "A partir da branch `main` limpa:",
    "",
    "```bash",
    "./scripts/release-stable.sh",
    "```",
    "",
    "O script gera pacotes temporários, cria ou atualiza a release e remove os artefatos temporários ao final."
]

write_text("docs/RELEASES.md", md(releases_md))

variables_md = [
    "# Variáveis do AutoM8",
    "",
    "| Variável | Padrão | Escopo | Descrição |",
    "| --- | --- | --- | --- |"
]

for v in variables:
    variables_md.append(f"| `{v['name']}` | `{v['default']}` | {v['scope']} | {v['description']} |")

write_text("docs/VARIABLES.md", md(variables_md))

architecture_md = [
    "# Arquitetura do AutoM8",
    "",
    "O AutoM8 é dividido em quatro áreas principais:",
    "",
    "```text",
    "suite/      # suíte instalada em /opt/autom8",
    "installer/  # instalador público install.sh",
    "site/       # site oficial em Astro",
    "scripts/    # sincronização, build, deploy, pacote e release",
    "docs/       # fonte única e documentos auxiliares",
    "```",
    "",
    "## Runtime",
    "",
    "A CLI principal fica em `suite/bin/autom8`.",
    "",
    "Os módulos ficam em `suite/modules/`.",
    "",
    "O núcleo compartilhado fica em `suite/core/`.",
    "",
    "## Documentação",
    "",
    "A documentação nasce em `docs/source/autom8-docs.json` e é sincronizada por `scripts/sync-docs.sh`.",
    "",
    "## Pacotes",
    "",
    "Pacotes são gerados temporariamente por `scripts/package.sh` e publicados por `scripts/release-stable.sh`."
]

write_text("docs/ARCHITECTURE.md", md(architecture_md))

print("Documentação sincronizada com sucesso.")
PY
