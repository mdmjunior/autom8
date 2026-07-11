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

apps_catalog = json.loads(
    (root / "suite/catalog/apps.json").read_text()
)
profiles_catalog = json.loads(
    (root / "suite/catalog/profiles.json").read_text()
)

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

profiles = [
    {
        "id": profile["id"],
        "name": profile["name"],
        "summary": profile.get("summary", ""),
        "category": profile.get("category", "sem-categoria"),
        "appsCount": len(profile.get("apps", [])),
        "command": f"autom8 profiles show {profile['id']}"
    }
    for profile in profiles_catalog["profiles"]
]

catalog_summary = {
    "version": apps_catalog["version"],
    "updatedAt": apps_catalog.get("updatedAt", ""),
    "appsCount": len(apps_catalog["apps"]),
    "profilesCount": len(profiles),
    "categories": [
        {
            "slug": category["slug"],
            "name": category["name"],
            "description": category.get("description", "")
        }
        for category in apps_catalog["categories"]
    ]
}

def terminal_line(text="", line_type="plain"):
    return {
        "text": text,
        "type": line_type
    }

def terminal_header(title, subtitle):
    return [
        terminal_line(
            "========================================",
            "muted"
        ),
        terminal_line(title, "plain"),
        terminal_line(subtitle, "note"),
        terminal_line(
            "========================================",
            "muted"
        ),
        terminal_line()
    ]

def terminal_summary(message):
    return [
        terminal_line(),
        terminal_line(
            "=== Resumo da execução ===",
            "muted"
        ),
        terminal_line(),
        terminal_line(
            f"  {'Concluídas:':<22} 1"
        ),
        terminal_line(
            f"  {'Avisos:':<22} 0"
        ),
        terminal_line(
            f"  {'Falhas:':<22} 0"
        ),
        terminal_line(
            f"  {'Logs:':<22} /opt/autom8/logs"
        ),
        terminal_line(),
        terminal_line(
            f"  {'OK':<7} {message}",
            "success"
        )
    ]

search_results = []

for app in apps_catalog["apps"]:
    searchable = " ".join([
        app.get("id", ""),
        app.get("name", ""),
        app.get("summary", ""),
        app.get("category", ""),
        " ".join(app.get("tags", []))
    ]).lower()

    if "docker" in searchable:
        search_results.append(app)

terminal_sessions = [
    {
        "command": "autom8 --version",
        "output": [
            terminal_line(
                f"AutoM8 {apps_catalog['version']}",
                "success"
            )
        ]
    },
    {
        "command": "autom8 apps search docker",
        "output": (
            terminal_header(
                "Apps · busca",
                "Termo: docker"
            )
            + [
                terminal_line(
                    "  "
                    + app["id"]
                    + " | "
                    + app["name"]
                    + " | "
                    + app.get("category", "uncategorized")
                    + " | "
                    + app.get("summary", "")
                )
                for app in search_results
            ]
            + terminal_summary("Busca executada")
        )
    },
    {
        "command": "autom8 apps categories",
        "output": (
            terminal_header(
                "Apps · categorias",
                "Grupos disponíveis no catálogo."
            )
            + [
                terminal_line(
                    "  "
                    + category["slug"]
                    + " | "
                    + category["name"]
                    + " | "
                    + category.get("description", "")
                )
                for category in apps_catalog["categories"]
            ]
            + terminal_summary("Categorias listadas")
        )
    },
    {
        "command": "autom8 profiles list",
        "output": (
            terminal_header(
                "Perfis",
                "Perfis baseados no catálogo de apps."
            )
            + [
                terminal_line(
                    f"  {'Catálogo:':<22} "
                    "/opt/autom8/catalog/profiles.json"
                ),
                terminal_line(
                    f"  {'Versão:':<22} "
                    f"{profiles_catalog['version']}"
                ),
                terminal_line(),
                terminal_line("Disponíveis", "muted")
            ]
            + [
                terminal_line(
                    "  "
                    + profile["id"]
                    + " | "
                    + profile["name"]
                    + " | "
                    + profile.get("summary", "")
                )
                for profile in profiles_catalog["profiles"]
            ]
            + terminal_summary("Perfis listados")
        )
    }
]

write_json("site/src/data/modules.json", modules)
write_json("site/src/data/profiles.json", profiles)
write_json("site/src/data/catalog-summary.json", catalog_summary)
write_json(
    "site/src/data/terminal-sessions.json",
    terminal_sessions
)
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
    "profiles": profiles,
    "catalogSummary": catalog_summary,
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


# DOCS:README:START
status_labels = {
    "available": "Disponível",
    "partial": "Parcial",
    "planned": "Planejado"
}

essential_slugs = [
    "apps",
    "profiles",
    "update",
    "clean",
    "doctor",
    "diagnose",
    "security",
    "report"
]

commands_by_slug = {
    command["slug"]: command
    for command in commands
}

essential_commands = [
    commands_by_slug[slug]
    for slug in essential_slugs
    if slug in commands_by_slug
]

readme = [
    f"# {product['name']}",
    "",
    product["summary"],
    "",
    (
        f"[Site oficial]({product['siteUrl']}) · "
        f"[Documentação]({product['siteUrl']}/docs) · "
        f"[Releases](https://github.com/{product['githubRepo']}/releases)"
    ),
    "",
    "## Estado atual",
    "",
    f"- Versão estável: `{product['currentVersion']}`",
    (
        f"- Catálogo: **{len(apps_catalog['apps'])} apps**, "
        f"**{len(apps_catalog['categories'])} categorias** e "
        f"**{len(profiles)} perfis**"
    ),
    "- Validado em Ubuntu Desktop e Fedora Workstation.",
    "- Compatível com fluxos baseados em `apt`, `dnf`, `zypper` e `pacman`.",
    "",
    "## Instalação",
    "",
    "Execute com um usuário comum que tenha permissão de `sudo`:",
    "",
    "```bash",
    install["command"],
    "```",
    "",
    "Primeiro uso:",
    "",
    "```bash",
    *install["after"],
    "autom8 apps search docker",
    "autom8 profiles list",
    "```",
    "",
    "## Comandos essenciais",
    "",
    "| Comando | Descrição |",
    "| --- | --- |"
]

for command in essential_commands:
    readme.append(
        f"| `{command['command']}` | {command['summary']} |"
    )

readme.extend([
    "",
    "Use `autom8 help` para a lista completa e "
    "`autom8 help <comando>` para detalhes.",
    "",
    "### Em evolução",
    ""
])

for command in partial + planned:
    readme.append(
        f"- **{status_labels[command['status']]}:** "
        f"`{command['command']}` — {command['summary']}"
    )

readme.extend([
    "",
    "## Desenvolvimento",
    "",
    "```bash",
    "./scripts/bootstrap-dev.sh",
    "./scripts/sync-docs.sh",
    "./scripts/check.sh all",
    "./scripts/website/build.sh",
    "```",
    "",
    "Fluxo do projeto: mudanças entram em `develop`; "
    "a promoção para `main` ocorre por pull request com Quality Gate.",
    "",
    "## Estrutura",
    "",
    "```text",
    "suite/      CLI instalada em /opt/autom8",
    "installer/  instalador público",
    "site/       website Astro",
    "docs/       fonte e documentos técnicos",
    "scripts/    validação, build, pacote e release",
    "```",
    "",
    "## Documentação do repositório",
    "",
    "- [Índice técnico](docs/README.md)",
    "- [Arquitetura](docs/ARCHITECTURE.md)",
    "- [Releases](docs/RELEASES.md)",
    "- [Variáveis](docs/VARIABLES.md)",
    "- [Como contribuir](CONTRIBUTING.md)",
    "- [Segurança](SECURITY.md)",
    "",
    "A fonte canônica é `docs/source/autom8-docs.json`. "
    "Arquivos gerados não devem ser editados isoladamente.",
    "",
    "## Licença",
    "",
    "[GNU GPL-3.0](LICENSE).",
    "",
    "AutoM8 é um produto OSLabs para a comunidade Linux."
])

write_text("README.md", md(readme))
# DOCS:README:END


# DOCS:INDEX:START
docs_readme = [
    "# Documentação do AutoM8",
    "",
    "Este diretório reúne a documentação técnica e operacional do projeto.",
    "",
    "## Para usuários",
    "",
    f"- [Guia rápido]({product['siteUrl']}/docs)",
    "- [README do projeto](../README.md)",
    "- Ajuda local: `autom8 help` e `autom8 help <comando>`",
    "",
    "## Para manutenção",
    "",
    "- [Arquitetura](ARCHITECTURE.md)",
    "- [Releases](RELEASES.md)",
    "- [Variáveis](VARIABLES.md)",
    "- [Contribuição](../CONTRIBUTING.md)",
    "- [Segurança](../SECURITY.md)",
    "",
    "## Fonte única",
    "",
    "`docs/source/autom8-docs.json` alimenta o README, "
    "os dados do site e a ajuda da CLI.",
    "",
    "Para sincronizar e validar:",
    "",
    "```bash",
    "./scripts/sync-docs.sh",
    "./scripts/check.sh all",
    "```",
    "",
    "Não edite arquivos gerados sem atualizar a fonte ou o gerador."
]

write_text("docs/README.md", md(docs_readme))
# DOCS:INDEX:END

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
