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
    "available": "🟢 Disponível",
    "partial": "🟡 Parcial",
    "planned": "⚪ Planejado"
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

github_url = (
    "https://github.com/"
    + product["githubRepo"]
)

apps_count = len(
    apps_catalog["apps"]
)

categories_count = len(
    apps_catalog["categories"]
)

profiles_count = len(
    profiles
)

readme = [
    "<!--",
    "  Este arquivo é gerado por scripts/sync-docs.sh.",
    "  Atualize docs/source/autom8-docs.json, os catálogos",
    "  ou o bloco DOCS:README do gerador.",
    "-->",
    "",
    '<p align="center">',
    f'  <a href="{product["siteUrl"]}">',
    "    <img",
    '      src="site/public/branding/logo-autom8-site.png"',
    '      alt="AutoM8 - Linux Management Suite"',
    '      width="620"',
    "    />",
    "  </a>",
    "</p>",
    "",
    '<p align="center">',
    f"  <strong>{product['positioning']}</strong>",
    "</p>",
    "",
    '<p align="center">',
    f"  {product['summary']}",
    "</p>",
    "",
    '<p align="center">',
    f'  <a href="{product["siteUrl"]}">',
    "    <img",
    '      alt="Site oficial"',
    '      src="https://img.shields.io/badge/SITE-020617?style=for-the-badge&logo=googlechrome&logoColor=38bdf8"',
    "    />",
    "  </a>",
    f'  <a href="{product["siteUrl"]}/docs">',
    "    <img",
    '      alt="Documentação"',
    '      src="https://img.shields.io/badge/DOCUMENTA%C3%87%C3%83O-020617?style=for-the-badge&logo=readthedocs&logoColor=22c55e"',
    "    />",
    "  </a>",
    f'  <a href="{product["siteUrl"]}/install">',
    "    <img",
    '      alt="Instalar AutoM8"',
    '      src="https://img.shields.io/badge/INSTALAR-020617?style=for-the-badge&logo=gnubash&logoColor=facc15"',
    "    />",
    "  </a>",
    f'  <a href="{github_url}/releases">',
    "    <img",
    '      alt="GitHub Releases"',
    '      src="https://img.shields.io/badge/RELEASES-020617?style=for-the-badge&logo=github&logoColor=ffffff"',
    "    />",
    "  </a>",
    "</p>",
    "",
    '<p align="center">',
    "  <img",
    f'    alt="Versão {product["currentVersion"]}"',
    (
        '    src="https://img.shields.io/badge/vers%C3%A3o-'
        f'{product["currentVersion"]}'
        '-22c55e?style=flat-square"'
    ),
    "  />",
    "  <img",
    f'    alt="{apps_count} aplicativos"',
    (
        '    src="https://img.shields.io/badge/apps-'
        f'{apps_count}'
        '-38bdf8?style=flat-square"'
    ),
    "  />",
    "  <img",
    f'    alt="{categories_count} categorias"',
    (
        '    src="https://img.shields.io/badge/categorias-'
        f'{categories_count}'
        '-a78bfa?style=flat-square"'
    ),
    "  />",
    "  <img",
    f'    alt="{profiles_count} perfis"',
    (
        '    src="https://img.shields.io/badge/perfis-'
        f'{profiles_count}'
        '-f59e0b?style=flat-square"'
    ),
    "  />",
    "  <a href=\"LICENSE\">",
    "    <img",
    '      alt="Licença GPL-3.0"',
    '      src="https://img.shields.io/badge/licen%C3%A7a-GPL--3.0-64748b?style=flat-square"',
    "    />",
    "  </a>",
    (
        f'  <a href="{github_url}/actions/workflows/'
        'quality.yml">'
    ),
    "    <img",
    '      alt="Quality Gate"',
    (
        f'      src="{github_url}/actions/workflows/'
        'quality.yml/badge.svg?branch=main"'
    ),
    "    />",
    "  </a>",
    "</p>",
    "",
    "---",
    "",
    "## AutoM8 em números",
    "",
    '<table align="center">',
    "  <tr>",
    '    <td align="center" width="25%">',
    f"      <strong>{product['currentVersion']}</strong><br />",
    "      <sub>versão estável</sub>",
    "    </td>",
    '    <td align="center" width="25%">',
    f"      <strong>{apps_count}</strong><br />",
    "      <sub>aplicativos</sub>",
    "    </td>",
    '    <td align="center" width="25%">',
    f"      <strong>{categories_count}</strong><br />",
    "      <sub>categorias</sub>",
    "    </td>",
    '    <td align="center" width="25%">',
    f"      <strong>{profiles_count}</strong><br />",
    "      <sub>perfis</sub>",
    "    </td>",
    "  </tr>",
    "</table>",
    "",
    "## Instalação",
    "",
    "Execute como usuário comum com permissão de `sudo`:",
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
    "> [!IMPORTANT]",
    "> Não execute o instalador diretamente como `root`.",
    "> A instalação padrão é feita em `/opt/autom8`.",
    "",
    "## Por que AutoM8?",
    "",
    "| Local e auditável | Seguro por padrão | Multidistro |",
    "| --- | --- | --- |",
    (
        "| Funciona localmente, sem painel remoto obrigatório. "
        "| Confirmações explícitas antes de alterações reais. "
        "| Fluxos para `apt`, `dnf`, `zypper` e `pacman`. |"
    ),
    (
        "| Logs e relatórios permanecem sob controle do usuário. "
        "| Modo `--dry-run` para visualizar ações antecipadamente. "
        "| Direcionado a desktops e servidores Linux. |"
    ),
    (
        "| Diagnósticos privados podem ser sanitizados. "
        "| Catálogos locais e atualizáveis. "
        "| Ubuntu e Fedora validados no ciclo atual. |"
    ),
    "",
    "## Experiência no terminal",
    "",
    "```console",
    "$ autom8 doctor",
    "",
    "AutoM8 · diagnóstico",
    "",
    "  ✓ Instalação validada",
    "  ✓ Dependências disponíveis",
    "  ✓ Catálogo carregado",
    f"  ✓ Versão estável: {product['currentVersion']}",
    "",
    "$ autom8 apps search docker",
    "",
    "  docker · Containers e ambientes isolados",
    "  docker-compose · Orquestração local",
    "",
    "$ autom8 profiles list",
    "",
    "  desenvolvimento",
    "  produtividade",
    "  servidor",
    "```",
    "",
    "## Stack do projeto",
    "",
    "### CLI e runtime",
    "",
    '<p>',
    '  <img alt="Linux" src="https://img.shields.io/badge/Linux-111827?style=for-the-badge&logo=linux&logoColor=ffffff" />',
    '  <img alt="Bash" src="https://img.shields.io/badge/Bash-111827?style=for-the-badge&logo=gnubash&logoColor=22c55e" />',
    '  <img alt="jq" src="https://img.shields.io/badge/jq-111827?style=for-the-badge&logo=jq&logoColor=38bdf8" />',
    '  <img alt="gum" src="https://img.shields.io/badge/gum-111827?style=for-the-badge&logoColor=facc15" />',
    "</p>",
    "",
    "### Website",
    "",
    '<p>',
    '  <img alt="Astro" src="https://img.shields.io/badge/Astro-111827?style=for-the-badge&logo=astro&logoColor=ff5d01" />',
    '  <img alt="Tailwind CSS" src="https://img.shields.io/badge/Tailwind_CSS-111827?style=for-the-badge&logo=tailwindcss&logoColor=38bdf8" />',
    '  <img alt="Node.js" src="https://img.shields.io/badge/Node.js_22-111827?style=for-the-badge&logo=nodedotjs&logoColor=22c55e" />',
    '  <img alt="Simple Icons" src="https://img.shields.io/badge/Simple_Icons-111827?style=for-the-badge&logo=simpleicons&logoColor=ffffff" />',
    "</p>",
    "",
    "### Infraestrutura e entrega",
    "",
    '<p>',
    '  <img alt="Docker" src="https://img.shields.io/badge/Docker-111827?style=for-the-badge&logo=docker&logoColor=2496ed" />',
    '  <img alt="Docker Swarm" src="https://img.shields.io/badge/Docker_Swarm-111827?style=for-the-badge&logo=docker&logoColor=38bdf8" />',
    '  <img alt="Nginx" src="https://img.shields.io/badge/Nginx-111827?style=for-the-badge&logo=nginx&logoColor=22c55e" />',
    '  <img alt="Traefik" src="https://img.shields.io/badge/Traefik-111827?style=for-the-badge&logo=traefikproxy&logoColor=38bdf8" />',
    '  <img alt="GitHub Actions" src="https://img.shields.io/badge/GitHub_Actions-111827?style=for-the-badge&logo=githubactions&logoColor=2088ff" />',
    '  <img alt="ShellCheck" src="https://img.shields.io/badge/ShellCheck-111827?style=for-the-badge&logo=gnu&logoColor=facc15" />',
    "</p>",
    "",
    "## Arquitetura",
    "",
    "```mermaid",
    "flowchart LR",
    "    User[Usuário Linux] --> Installer[install.sh]",
    "    Installer --> Release[GitHub Releases]",
    "    Release --> CLI[AutoM8 CLI]",
    "",
    "    CLI --> Apps[Catálogo de apps]",
    "    CLI --> Profiles[Perfis]",
    "    CLI --> Modules[Módulos]",
    "    CLI --> Reports[Logs e relatórios]",
    "",
    "    Source[docs/source/autom8-docs.json] --> Sync[sync-docs.sh]",
    "    Sync --> Website[Website Astro]",
    "    Sync --> Help[Ajuda da CLI]",
    "    Sync --> Readme[README]",
    "",
    "    Website --> Image[Docker + Nginx]",
    "    Image --> Swarm[Docker Swarm]",
    "    Swarm --> Proxy[Traefik + TLS]",
    "```",
    "",
    "> O website publica o instalador e a documentação.",
    "> Os pacotes estáveis da suíte são distribuídos exclusivamente",
    "> pelo GitHub Releases.",
    "",
    "## Recursos",
    "",
    "| Comando | Estado | Desde | Descrição |",
    "| --- | --- | --- | --- |"
]

for command in commands:
    readme.append(
        f"| `{command['command']}` "
        f"| {status_labels[command['status']]} "
        f"| `{command['since']}` "
        f"| {command['summary']} |"
    )

readme.extend([
    "",
    "## Compatibilidade",
    "",
    "| Plataforma | Estado atual | Gerenciador |",
    "| --- | --- | --- |",
    "| Ubuntu Desktop | 🟢 Validado | `apt` |",
    "| Fedora Workstation | 🟢 Validado | `dnf` |",
    "| Debian e derivados | 🟡 Compatível, testes em expansão | `apt` |",
    "| openSUSE | 🟡 Compatível, testes em expansão | `zypper` |",
    "| Arch Linux e derivados | 🟡 Compatível, testes em expansão | `pacman` |",
    "",
    "## Comandos essenciais",
    "",
    "| Comando | Descrição |",
    "| --- | --- |"
])

for command in essential_commands:
    readme.append(
        f"| `{command['command']}` | {command['summary']} |"
    )

readme.extend([
    "",
    "Use `autom8 help` para a lista completa e",
    "`autom8 help <comando>` para detalhes.",
    "",
    "## Desenvolvimento",
    "",
    "```bash",
    "git checkout develop",
    "./scripts/bootstrap-dev.sh",
    "./scripts/sync-docs.sh",
    "./scripts/check.sh all",
    "./scripts/website/build.sh",
    "```",
    "",
    "Mudanças entram em `develop` e são promovidas para `main`",
    "por Pull Request com Quality Gate obrigatório.",
    "",
    "## Estrutura do repositório",
    "",
    "```text",
    "autom8/",
    "├── suite/       # CLI instalada em /opt/autom8",
    "├── installer/   # instalador público",
    "├── site/        # website Astro",
    "├── docs/        # documentação e fonte canônica",
    "├── infra/       # Docker Swarm e deploy",
    "└── scripts/     # build, validação, pacote e release",
    "```",
    "",
    "## Documentação",
    "",
    "- [Índice técnico](docs/README.md)",
    "- [Arquitetura](docs/ARCHITECTURE.md)",
    "- [Deploy](docs/DEPLOY.md)",
    "- [Releases](docs/RELEASES.md)",
    "- [Variáveis](docs/VARIABLES.md)",
    "- [Como contribuir](CONTRIBUTING.md)",
    "- [Segurança](SECURITY.md)",
    "",
    "A fonte canônica é `docs/source/autom8-docs.json`.",
    "O README, os dados do website e a ajuda da CLI são",
    "sincronizados por `scripts/sync-docs.sh`.",
    "",
    "## Roadmap",
    "",
    "1. concluir `autom8 self-update`;",
    "2. ampliar os testes multidistro;",
    "3. implementar `autom8 backup`;",
    "4. adicionar rollback antes de operações sensíveis;",
    "5. fortalecer a cadeia de releases com checksum e SBOM.",
    "",
    "Acompanhe a visão completa no",
    f"[roadmap oficial]({product['siteUrl']}/roadmap).",
    "",
    "## Licença",
    "",
    "Distribuído sob a [GNU GPL-3.0](LICENSE).",
    "",
    "---",
    "",
    '<p align="center">',
    "  <img",
    '    src="site/public/branding/favicon.png"',
    '    alt=""',
    '    width="52"',
    "  />",
    "</p>",
    "",
    '<p align="center">',
    "  <strong>AutoM8</strong><br />",
    "  Um produto OSLabs para a comunidade Linux.",
    "</p>"
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
    "Este documento descreve a arquitetura técnica do AutoM8,",
    "os fluxos de execução, distribuição, documentação e publicação.",
    "",
    "## Princípios arquiteturais",
    "",
    "O projeto é orientado pelos seguintes princípios:",
    "",
    "- execução local, sem painel remoto obrigatório;",
    "- operações explícitas e auditáveis;",
    "- suporte a modo de simulação antes de alterações reais;",
    "- separação entre CLI, instalador, website e infraestrutura;",
    "- documentação derivada de uma fonte canônica;",
    "- pacotes estáveis distribuídos exclusivamente pelo GitHub Releases;",
    "- deploy do website com imagem imutável, healthcheck e rollback;",
    "- compatibilidade progressiva com múltiplas famílias Linux.",
    "",
    "## Visão geral do repositório",
    "",
    "| Diretório | Responsabilidade |",
    "| --- | --- |",
    "| `suite/` | Runtime da CLI instalado em `/opt/autom8`. |",
    "| `suite/bin/` | Entrypoint executável da suíte. |",
    "| `suite/core/` | Configuração, detecção, logs, UI, sudo, ajuda e resumos. |",
    "| `suite/modules/` | Funcionalidades executáveis da CLI. |",
    "| `suite/catalog/` | Catálogos consolidados de aplicativos e perfis. |",
    "| `installer/` | Instalador público e fluxo de preparação do sistema. |",
    "| `site/` | Website institucional e documentação pública em Astro. |",
    "| `docs/` | Documentos técnicos e fonte canônica de conteúdo. |",
    "| `scripts/` | Sincronização, validação, build, pacote, release e deploy. |",
    "| `infra/` | Definições Docker, Swarm, Nginx e publicação do website. |",
    "| `.github/workflows/` | Quality Gates e automações do repositório. |",
    "",
    "## Diagrama de contexto",
    "",
    "```mermaid",
    "flowchart LR",
    "    User[Usuário Linux]",
    "    Maintainer[Mantenedor]",
    "    Website[Website AutoM8]",
    "    Installer[install.sh]",
    "    Releases[GitHub Releases]",
    "    CLI[AutoM8 CLI]",
    "    System[Sistema Linux]",
    "    GitHub[Repositório GitHub]",
    "    VPS[VPS OSLabs]",
    "",
    "    User --> Website",
    "    User --> Installer",
    "    Installer --> Releases",
    "    Releases --> CLI",
    "    User --> CLI",
    "    CLI --> System",
    "",
    "    Maintainer --> GitHub",
    "    GitHub --> Releases",
    "    GitHub --> VPS",
    "    VPS --> Website",
    "```",
    "",
    "## Runtime da CLI",
    "",
    "O entrypoint principal fica em `suite/bin/autom8`.",
    "",
    "Na inicialização, ele determina `AUTOM8_ROOT` e carrega",
    "os componentes compartilhados do diretório `suite/core/`:",
    "",
    "- `constants.sh`: caminhos, versão e constantes globais;",
    "- `config.sh`: leitura e normalização das configurações;",
    "- `logger.sh`: criação e gravação dos logs;",
    "- `ui.sh`: interface textual e integração com `gum`;",
    "- `detect.sh`: identificação da distribuição e do ambiente;",
    "- `sudo.sh`: validação e execução de operações privilegiadas;",
    "- `summary.sh`: resumo das ações executadas;",
    "- `help.sh`: índice e ajuda detalhada dos comandos.",
    "",
    "Depois do núcleo, o entrypoint carrega os módulos funcionais",
    "disponíveis em `suite/modules/`.",
    "",
    "Os módulos são carregados no mesmo processo Bash e expõem",
    "funções que são despachadas pelo menu ou pela linha de comando.",
    "",
    "### Fluxo de inicialização",
    "",
    "```mermaid",
    "sequenceDiagram",
    "    participant U as Usuário",
    "    participant E as suite/bin/autom8",
    "    participant C as Núcleo compartilhado",
    "    participant D as Detecção",
    "    participant M as Módulo",
    "    participant S as Sistema Linux",
    "",
    "    U->>E: autom8 <comando>",
    "    E->>C: carregar constantes e configuração",
    "    E->>D: detectar distro, sessão e sudo",
    "    D-->>E: contexto do ambiente",
    "    E->>C: iniciar log e resumo",
    "    E->>M: despachar comando",
    "    M->>S: inspecionar ou alterar o sistema",
    "    S-->>M: resultado",
    "    M->>C: registrar log e resumo",
    "    C-->>U: saída final",
    "```",
    "",
    "### Modos de execução",
    "",
    "A CLI possui dois modos principais de interação:",
    "",
    "1. menu interativo, iniciado com `autom8`;",
    "2. execução direta, como `autom8 doctor` ou `autom8 apps list`.",
    "",
    "Flags globais são interpretadas antes do despacho do comando.",
    "Entre elas estão:",
    "",
    "- `--dry-run`: apresenta a ação sem aplicar a alteração real;",
    "- `--private`: sanitiza dados sensíveis em diagnósticos compatíveis;",
    "- `--version`: exibe a versão atual;",
    "- `--help`: apresenta o índice de ajuda.",
    "",
    "## Núcleo compartilhado",
    "",
    "O núcleo evita que cada módulo implemente novamente funções",
    "de detecção, confirmação, privilégio, logs e apresentação.",
    "",
    "Essa separação permite que um módulo se concentre em três etapas:",
    "",
    "1. validar se a operação pode ser executada;",
    "2. montar e apresentar as ações previstas;",
    "3. executar, registrar e resumir o resultado.",
    "",
    "## Módulos",
    "",
    "Os módulos atualmente carregados pelo entrypoint incluem:",
    "",
    "- diagnóstico e doctor;",
    "- atualização e limpeza;",
    "- aplicativos e perfis;",
    "- segurança e Docker;",
    "- usuários e configurações;",
    "- relatórios;",
    "- backup e upgrade de distribuição em evolução;",
    "- validação de atualização da própria suíte.",
    "",
    "Módulos podem estar nos estados `available`, `partial` ou `planned`.",
    "O estado público de cada comando vem da fonte canônica de documentação.",
    "",
    "## Dados e estado local",
    "",
    "A instalação padrão usa `/opt/autom8`.",
    "",
    "```text",
    "/opt/autom8/",
    "├── bin/        # executável principal",
    "├── core/       # núcleo compartilhado",
    "├── modules/    # módulos funcionais",
    "├── catalog/    # catálogos consolidados",
    "├── config/     # configuração da instalação",
    "├── docs/       # ajuda local",
    "├── logs/       # registros de execução",
    "├── reports/    # relatórios gerados",
    "├── backups/    # backups futuros ou operacionais",
    "└── tmp/        # arquivos temporários controlados",
    "```",
    "",
    "O código instalado pertence a `root:root`.",
    "Os diretórios operacionais que precisam receber escrita do usuário",
    "são preparados separadamente pelo instalador.",
    "",
    "## Catálogo de aplicativos",
    "",
    "O catálogo de aplicativos possui duas camadas:",
    "",
    "1. arquivos fonte separados por categoria;",
    "2. catálogo consolidado consumido pela CLI.",
    "",
    "```mermaid",
    "flowchart LR",
    "    Sources[suite/catalog/apps/*.json]",
    "    Builder[build-apps-catalog.sh]",
    "    Catalog[suite/catalog/apps.json]",
    "    Validator[validate-apps-catalog.sh]",
    "    Apps[autom8 apps]",
    "",
    "    Sources --> Builder",
    "    Builder --> Catalog",
    "    Catalog --> Validator",
    "    Validator --> Apps",
    "```",
    "",
    "O catálogo consolidado é validado antes da criação de pacotes.",
    "Perfis utilizam `suite/catalog/profiles.json` e referenciam",
    "aplicativos presentes no catálogo.",
    "",
    "## Instalação",
    "",
    "O instalador público fica em `installer/install.sh` e é executado",
    "por um usuário comum com acesso a `sudo`.",
    "",
    "### Responsabilidades do instalador",
    "",
    "- impedir execução direta como `root`;",
    "- validar autenticação com `sudo`;",
    "- detectar o sistema e o gerenciador de pacotes;",
    "- instalar dependências comuns;",
    "- instalar e validar `gum`;",
    "- baixar o pacote estável pelo GitHub Releases;",
    "- validar se o arquivo baixado é um `tar.gz` válido;",
    "- localizar a raiz correta da suíte dentro do pacote;",
    "- sincronizar os arquivos para `/opt/autom8`;",
    "- configurar permissões e diretórios operacionais;",
    "- disponibilizar o comando no `PATH`;",
    "- executar `autom8 --version` e `autom8 doctor`.",
    "",
    "### Fluxo de instalação",
    "",
    "```mermaid",
    "sequenceDiagram",
    "    participant U as Usuário",
    "    participant W as Website",
    "    participant I as install.sh",
    "    participant P as Gerenciador de pacotes",
    "    participant R as GitHub Releases",
    "    participant F as /opt/autom8",
    "",
    "    U->>W: solicita install.sh",
    "    W-->>U: entrega o instalador",
    "    U->>I: executa como usuário comum",
    "    I->>P: instala dependências",
    "    I->>R: baixa autom8-latest.tar.gz",
    "    R-->>I: pacote estável",
    "    I->>I: valida e extrai o pacote",
    "    I->>F: sincroniza a suíte",
    "    I->>F: configura permissões e PATH",
    "    I->>F: executa version e doctor",
    "```",
    "",
    "O website não hospeda o pacote completo da suíte.",
    "Ele publica o instalador e a documentação pública.",
    "",
    "## Empacotamento",
    "",
    "`scripts/package.sh` gera dois arquivos temporários:",
    "",
    "- `autom8-<versão>.tar.gz`;",
    "- `autom8-latest.tar.gz`.",
    "",
    "Antes de empacotar, o script:",
    "",
    "- lê a versão em `suite/VERSION`;",
    "- reconstrói o catálogo consolidado;",
    "- valida os catálogos de aplicativos e perfis;",
    "- exclui logs, relatórios, backups e temporários do pacote.",
    "",
    "Os arquivos gerados não são copiados para o website,",
    "para a VPS nem para o diretório do repositório.",
    "",
    "## Releases",
    "",
    "Releases estáveis são publicadas por `scripts/release-stable.sh`.",
    "",
    "O fluxo exige:",
    "",
    "- árvore Git limpa;",
    "- branch `main`;",
    "- GitHub CLI autenticado;",
    "- validação completa da CLI;",
    "- versão válida em `suite/VERSION`.",
    "",
    "```mermaid",
    "flowchart LR",
    "    Main[main limpa]",
    "    Check[check.sh cli]",
    "    Package[package.sh]",
    "    Versioned[autom8-versão.tar.gz]",
    "    Latest[autom8-latest.tar.gz]",
    "    Release[GitHub Release vX.Y.Z]",
    "    Installer[install.sh]",
    "",
    "    Main --> Check",
    "    Check --> Package",
    "    Package --> Versioned",
    "    Package --> Latest",
    "    Versioned --> Release",
    "    Latest --> Release",
    "    Release --> Installer",
    "```",
    "",
    "Se a release da versão já existir, seus assets podem ser",
    "substituídos explicitamente pelo fluxo de publicação.",
    "",
    "## Documentação canônica",
    "",
    "A fonte principal de conteúdo é:",
    "",
    "`docs/source/autom8-docs.json`",
    "",
    "Ela é combinada com os catálogos pelo script",
    "`scripts/sync-docs.sh`.",
    "",
    "### Saídas da sincronização",
    "",
    "- README visual do repositório;",
    "- documentação técnica em `docs/`;",
    "- arquivos de ajuda da CLI;",
    "- dados estruturados consumidos pelo website;",
    "- catálogo resumido, roadmap e changelog;",
    "- sessões de terminal usadas na apresentação pública.",
    "",
    "```mermaid",
    "flowchart TD",
    "    Source[autom8-docs.json]",
    "    Apps[apps.json]",
    "    Profiles[profiles.json]",
    "    Sync[sync-docs.sh]",
    "    Readme[README.md]",
    "    Docs[docs/*.md]",
    "    Help[suite/docs/help]",
    "    SiteData[site/src/data/*.json]",
    "",
    "    Source --> Sync",
    "    Apps --> Sync",
    "    Profiles --> Sync",
    "    Sync --> Readme",
    "    Sync --> Docs",
    "    Sync --> Help",
    "    Sync --> SiteData",
    "```",
    "",
    "Arquivos gerados não devem ser editados isoladamente.",
    "A fonte ou o gerador correspondente deve ser atualizado primeiro.",
    "",
    "## Website",
    "",
    "O website fica em `site/` e utiliza:",
    "",
    "- Astro para geração das páginas;",
    "- Tailwind CSS para a camada utilitária de estilos;",
    "- Simple Icons para marcas e integrações visuais;",
    "- Node.js 22 no fluxo de desenvolvimento e build;",
    "- Nginx para servir a saída estática em produção.",
    "",
    "O build gera páginas estáticas, metadados SEO, sitemap,",
    "robots.txt e web manifest.",
    "",
    "Uma auditoria pós-build valida HTML, links, SEO e acessibilidade.",
    "",
    "## Publicação do website",
    "",
    "O website é empacotado em uma imagem Docker e publicado",
    "como serviço de uma Stack Docker Swarm.",
    "",
    "```mermaid",
    "flowchart LR",
    "    Main[Branch main]",
    "    Build[Build Astro]",
    "    Audit[Auditoria do site]",
    "    Image[Imagem Docker imutável]",
    "    Test[Teste local da imagem]",
    "    Swarm[Docker Swarm]",
    "    Traefik[Traefik + TLS]",
    "    Public[autom8.oslabs.com.br]",
    "",
    "    Main --> Build",
    "    Build --> Audit",
    "    Audit --> Image",
    "    Image --> Test",
    "    Test --> Swarm",
    "    Swarm --> Traefik",
    "    Traefik --> Public",
    "```",
    "",
    "A imagem recebe uma tag composta pela versão da suíte",
    "e pelo commit Git que originou a publicação.",
    "",
    "O serviço utiliza:",
    "",
    "- atualização `start-first`;",
    "- uma réplica por padrão;",
    "- healthcheck HTTP;",
    "- espera ativa durante a publicação;",
    "- rollback automático quando a atualização falha;",
    "- rede externa compartilhada `oslabs-public`;",
    "- roteamento HTTPS realizado pelo Traefik.",
    "",
    "## Quality Gate",
    "",
    "Mudanças entram pela branch `develop` e são promovidas para",
    "`main` por Pull Request.",
    "",
    "O Quality Gate combina validações locais e GitHub Actions.",
    "",
    "As verificações incluem, conforme o escopo:",
    "",
    "- sintaxe Bash;",
    "- ShellCheck;",
    "- integridade da estrutura do repositório;",
    "- consistência de versões;",
    "- validação dos catálogos;",
    "- instalação e empacotamento da CLI;",
    "- sincronização da documentação;",
    "- build e auditoria do website;",
    "- validação da imagem Docker;",
    "- renderização da Stack Swarm.",
    "",
    "## Fronteiras de segurança",
    "",
    "### Usuário e root",
    "",
    "O AutoM8 deve ser iniciado por um usuário comum.",
    "Operações privilegiadas são elevadas pontualmente com `sudo`.",
    "",
    "### Código e dados operacionais",
    "",
    "O código instalado é protegido com propriedade de root.",
    "Logs, relatórios, configuração e temporários operacionais",
    "possuem permissões apropriadas para o usuário da instalação.",
    "",
    "### Diagnósticos",
    "",
    "Relatórios privados devem reduzir ou remover informações",
    "sensíveis antes de serem compartilhados.",
    "",
    "### Distribuição",
    "",
    "O pacote estável deve vir do GitHub Releases.",
    "A VPS do website não é fonte de distribuição dos pacotes da suíte.",
    "",
    "### Deploy",
    "",
    "O deploy não deve publicar uma imagem que falhe no teste local",
    "ou no healthcheck do serviço.",
    "",
    "## Pontos de extensão",
    "",
    "### Novo módulo",
    "",
    "Para adicionar um módulo:",
    "",
    "1. criar o arquivo em `suite/modules/`;",
    "2. utilizar as funções compartilhadas do núcleo;",
    "3. registrar o módulo no entrypoint;",
    "4. adicionar ajuda e estado à fonte canônica;",
    "5. incluir testes e validações;",
    "6. executar a sincronização da documentação.",
    "",
    "### Novo aplicativo",
    "",
    "Para adicionar um aplicativo:",
    "",
    "1. editar o arquivo fonte da categoria correta;",
    "2. reconstruir o catálogo consolidado;",
    "3. validar o catálogo;",
    "4. testar busca, exibição e `--dry-run`.",
    "",
    "### Novo perfil",
    "",
    "Para adicionar um perfil:",
    "",
    "1. editar `suite/catalog/profiles.json`;",
    "2. referenciar somente aplicativos válidos;",
    "3. validar o catálogo de perfis;",
    "4. sincronizar documentação e website.",
    "",
    "### Nova distribuição",
    "",
    "O suporte a uma nova distribuição exige:",
    "",
    "- detecção consistente em `/etc/os-release`;",
    "- identificação do gerenciador de pacotes;",
    "- comandos de instalação, atualização e remoção;",
    "- testes do instalador;",
    "- testes dos módulos que alteram o sistema;",
    "- atualização da matriz pública de compatibilidade.",
    "",
    "## Invariantes do projeto",
    "",
    "As seguintes regras devem permanecer verdadeiras:",
    "",
    "1. `suite/VERSION` define a versão estável da CLI;",
    "2. o pacote estável vem do GitHub Releases;",
    "3. o website não hospeda o pacote completo da suíte;",
    "4. a documentação gerada deriva da fonte canônica;",
    "5. a branch `main` representa o estado promovido;",
    "6. releases estáveis partem de `main` limpa;",
    "7. o deploy do website utiliza imagem imutável;",
    "8. falhas de atualização devem permitir rollback;",
    "9. operações destrutivas exigem confirmação;",
    "10. o modo `--dry-run` não deve alterar o sistema.",
    "",
    "## Referências relacionadas",
    "",
    "- [README do projeto](../README.md)",
    "- [Deploy](DEPLOY.md)",
    "- [Releases](RELEASES.md)",
    "- [Variáveis](VARIABLES.md)",
    "- [Contribuição](../CONTRIBUTING.md)",
    "- [Segurança](../SECURITY.md)"
]

write_text("docs/ARCHITECTURE.md", md(architecture_md))

print("Documentação sincronizada com sucesso.")
PY
