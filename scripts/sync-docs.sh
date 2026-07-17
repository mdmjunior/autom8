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
