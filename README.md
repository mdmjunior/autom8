<!--
  Este arquivo é gerado por scripts/sync-docs.sh.
  Atualize docs/source/autom8-docs.json, os catálogos
  ou o bloco DOCS:README do gerador.
-->

<p align="center">
  <a href="https://autom8.oslabs.com.br">
    <img
      src="site/public/branding/logo-autom8-site.png"
      alt="AutoM8 - Linux Management Suite"
      width="620"
    />
  </a>
</p>

<p align="center">
  <strong>Automação Linux local, auditável e previsível para desktops e servidores.</strong>
</p>

<p align="center">
  AutoM8 é uma CLI local para instalar aplicativos, aplicar perfis e executar manutenção em desktops e servidores Linux com confirmações, logs e modo de simulação.
</p>

<p align="center">
  <a href="https://autom8.oslabs.com.br">
    <img
      alt="Site oficial"
      src="https://img.shields.io/badge/SITE-020617?style=for-the-badge&logo=googlechrome&logoColor=38bdf8"
    />
  </a>
  <a href="https://autom8.oslabs.com.br/docs">
    <img
      alt="Documentação"
      src="https://img.shields.io/badge/DOCUMENTA%C3%87%C3%83O-020617?style=for-the-badge&logo=readthedocs&logoColor=22c55e"
    />
  </a>
  <a href="https://autom8.oslabs.com.br/install">
    <img
      alt="Instalar AutoM8"
      src="https://img.shields.io/badge/INSTALAR-020617?style=for-the-badge&logo=gnubash&logoColor=facc15"
    />
  </a>
  <a href="https://github.com/mdmjunior/autom8/releases">
    <img
      alt="GitHub Releases"
      src="https://img.shields.io/badge/RELEASES-020617?style=for-the-badge&logo=github&logoColor=ffffff"
    />
  </a>
</p>

<p align="center">
  <img
    alt="Versão 0.2.0"
    src="https://img.shields.io/badge/vers%C3%A3o-0.2.0-22c55e?style=flat-square"
  />
  <img
    alt="76 aplicativos"
    src="https://img.shields.io/badge/apps-76-38bdf8?style=flat-square"
  />
  <img
    alt="10 categorias"
    src="https://img.shields.io/badge/categorias-10-a78bfa?style=flat-square"
  />
  <img
    alt="6 perfis"
    src="https://img.shields.io/badge/perfis-6-f59e0b?style=flat-square"
  />
  <a href="LICENSE">
    <img
      alt="Licença GPL-3.0"
      src="https://img.shields.io/badge/licen%C3%A7a-GPL--3.0-64748b?style=flat-square"
    />
  </a>
  <a href="https://github.com/mdmjunior/autom8/actions/workflows/quality.yml">
    <img
      alt="Quality Gate"
      src="https://github.com/mdmjunior/autom8/actions/workflows/quality.yml/badge.svg?branch=main"
    />
  </a>
</p>

---

## AutoM8 em números

<table align="center">
  <tr>
    <td align="center" width="25%">
      <strong>0.2.0</strong><br />
      <sub>versão estável</sub>
    </td>
    <td align="center" width="25%">
      <strong>76</strong><br />
      <sub>aplicativos</sub>
    </td>
    <td align="center" width="25%">
      <strong>10</strong><br />
      <sub>categorias</sub>
    </td>
    <td align="center" width="25%">
      <strong>6</strong><br />
      <sub>perfis</sub>
    </td>
  </tr>
</table>

## Instalação

Execute como usuário comum com permissão de `sudo`:

```bash
curl -fsSL https://autom8.oslabs.com.br/install.sh | bash
```

Primeiro uso:

```bash
export PATH="/opt/autom8/bin:$PATH"
autom8
autom8 doctor
autom8 apps search docker
autom8 profiles list
```

> [!IMPORTANT]
> Não execute o instalador diretamente como `root`.
> A instalação padrão é feita em `/opt/autom8`.

## Por que AutoM8?

| Local e auditável | Seguro por padrão | Multidistro |
| --- | --- | --- |
| Funciona localmente, sem painel remoto obrigatório. | Confirmações explícitas antes de alterações reais. | Fluxos para `apt`, `dnf`, `zypper` e `pacman`. |
| Logs e relatórios permanecem sob controle do usuário. | Modo `--dry-run` para visualizar ações antecipadamente. | Direcionado a desktops e servidores Linux. |
| Diagnósticos privados podem ser sanitizados. | Catálogos locais e atualizáveis. | Ubuntu e Fedora validados no ciclo atual. |

## Experiência no terminal

```console
$ autom8 doctor

AutoM8 · diagnóstico

  ✓ Instalação validada
  ✓ Dependências disponíveis
  ✓ Catálogo carregado
  ✓ Versão estável: 0.2.0

$ autom8 apps search docker

  docker · Containers e ambientes isolados
  docker-compose · Orquestração local

$ autom8 profiles list

  desenvolvimento
  produtividade
  servidor
```

## Stack do projeto

### CLI e runtime

<p>
  <img alt="Linux" src="https://img.shields.io/badge/Linux-111827?style=for-the-badge&logo=linux&logoColor=ffffff" />
  <img alt="Bash" src="https://img.shields.io/badge/Bash-111827?style=for-the-badge&logo=gnubash&logoColor=22c55e" />
  <img alt="jq" src="https://img.shields.io/badge/jq-111827?style=for-the-badge&logo=jq&logoColor=38bdf8" />
  <img alt="gum" src="https://img.shields.io/badge/gum-111827?style=for-the-badge&logoColor=facc15" />
</p>

### Website

<p>
  <img alt="Astro" src="https://img.shields.io/badge/Astro-111827?style=for-the-badge&logo=astro&logoColor=ff5d01" />
  <img alt="Tailwind CSS" src="https://img.shields.io/badge/Tailwind_CSS-111827?style=for-the-badge&logo=tailwindcss&logoColor=38bdf8" />
  <img alt="Node.js" src="https://img.shields.io/badge/Node.js_22-111827?style=for-the-badge&logo=nodedotjs&logoColor=22c55e" />
  <img alt="Simple Icons" src="https://img.shields.io/badge/Simple_Icons-111827?style=for-the-badge&logo=simpleicons&logoColor=ffffff" />
</p>

### Infraestrutura e entrega

<p>
  <img alt="Docker" src="https://img.shields.io/badge/Docker-111827?style=for-the-badge&logo=docker&logoColor=2496ed" />
  <img alt="Docker Swarm" src="https://img.shields.io/badge/Docker_Swarm-111827?style=for-the-badge&logo=docker&logoColor=38bdf8" />
  <img alt="Nginx" src="https://img.shields.io/badge/Nginx-111827?style=for-the-badge&logo=nginx&logoColor=22c55e" />
  <img alt="Traefik" src="https://img.shields.io/badge/Traefik-111827?style=for-the-badge&logo=traefikproxy&logoColor=38bdf8" />
  <img alt="GitHub Actions" src="https://img.shields.io/badge/GitHub_Actions-111827?style=for-the-badge&logo=githubactions&logoColor=2088ff" />
  <img alt="ShellCheck" src="https://img.shields.io/badge/ShellCheck-111827?style=for-the-badge&logo=gnu&logoColor=facc15" />
</p>

## Arquitetura

```mermaid
flowchart LR
    User[Usuário Linux] --> Installer[install.sh]
    Installer --> Release[GitHub Releases]
    Release --> CLI[AutoM8 CLI]

    CLI --> Apps[Catálogo de apps]
    CLI --> Profiles[Perfis]
    CLI --> Modules[Módulos]
    CLI --> Reports[Logs e relatórios]

    Source[docs/source/autom8-docs.json] --> Sync[sync-docs.sh]
    Sync --> Website[Website Astro]
    Sync --> Help[Ajuda da CLI]
    Sync --> Readme[README]

    Website --> Image[Docker + Nginx]
    Image --> Swarm[Docker Swarm]
    Swarm --> Proxy[Traefik + TLS]
```

> O website publica o instalador e a documentação.
> Os pacotes estáveis da suíte são distribuídos exclusivamente
> pelo GitHub Releases.

## Recursos

| Comando | Estado | Desde | Descrição |
| --- | --- | --- | --- |
| `autom8 apps` | 🟢 Disponível | `0.2.0` | Instala e remove aplicativos por catálogo local atualizável online. |
| `autom8 backup` | ⚪ Planejado | `0.3.0` | Backups simples antes de operações sensíveis. |
| `autom8 clean` | 🟢 Disponível | `0.1.1` | Executa limpeza segura com confirmação explícita. |
| `autom8 config` | 🟢 Disponível | `0.1.1` | Permite alterar configurações básicas da suíte. |
| `autom8 diagnose` | 🟢 Disponível | `0.1.1` | Gera diagnóstico completo local ou privado sanitizado. |
| `autom8 docker` | 🟢 Disponível | `0.1.1` | Mostra informações do Docker quando disponível. |
| `autom8 doctor` | 🟢 Disponível | `0.1.1` | Valida instalação, dependências, PATH, release e versão online. |
| `autom8` | 🟢 Disponível | `0.1.1` | Abre Dashboard + Menu. |
| `autom8 profiles` | 🟢 Disponível | `0.2.0` | Lista, detalha, instala e remove perfis baseados no catálogo de apps. |
| `autom8 report` | 🟢 Disponível | `0.1.1` | Lista e exporta relatórios gerados. |
| `autom8 security` | 🟢 Disponível | `0.1.1` | Executa checagem básica de segurança local. |
| `autom8 self-update` | 🟡 Parcial | `0.1.0` | Valida o pacote estável mais recente publicado no GitHub Releases. |
| `autom8 update` | 🟢 Disponível | `0.1.1` | Atualiza repositórios e pacotes do sistema com confirmação. |
| `autom8 upgrade-distro` | ⚪ Planejado | `future` | Preparação futura para upgrade de versão da distro. |
| `autom8 users` | 🟢 Disponível | `0.1.1` | Lista usuários locais e grupos administrativos. |
| `autom8 --version` | 🟢 Disponível | `0.1.1` | Mostra a versão instalada. |

## Compatibilidade

| Plataforma | Estado atual | Gerenciador |
| --- | --- | --- |
| Ubuntu Desktop | 🟢 Validado | `apt` |
| Fedora Workstation | 🟢 Validado | `dnf` |
| Debian e derivados | 🟡 Compatível, testes em expansão | `apt` |
| openSUSE | 🟡 Compatível, testes em expansão | `zypper` |
| Arch Linux e derivados | 🟡 Compatível, testes em expansão | `pacman` |

## Comandos essenciais

| Comando | Descrição |
| --- | --- |
| `autom8 apps` | Instala e remove aplicativos por catálogo local atualizável online. |
| `autom8 profiles` | Lista, detalha, instala e remove perfis baseados no catálogo de apps. |
| `autom8 update` | Atualiza repositórios e pacotes do sistema com confirmação. |
| `autom8 clean` | Executa limpeza segura com confirmação explícita. |
| `autom8 doctor` | Valida instalação, dependências, PATH, release e versão online. |
| `autom8 diagnose` | Gera diagnóstico completo local ou privado sanitizado. |
| `autom8 security` | Executa checagem básica de segurança local. |
| `autom8 report` | Lista e exporta relatórios gerados. |

Use `autom8 help` para a lista completa e
`autom8 help <comando>` para detalhes.

## Desenvolvimento

```bash
git checkout develop
./scripts/bootstrap-dev.sh
./scripts/sync-docs.sh
./scripts/check.sh all
./scripts/website/build.sh
```

Mudanças entram em `develop` e são promovidas para `main`
por Pull Request com Quality Gate obrigatório.

## Estrutura do repositório

```text
autom8/
├── suite/       # CLI instalada em /opt/autom8
├── installer/   # instalador público
├── site/        # website Astro
├── docs/        # documentação e fonte canônica
├── infra/       # Docker Swarm e deploy
└── scripts/     # build, validação, pacote e release
```

## Documentação

- [Índice técnico](docs/README.md)
- [Arquitetura](docs/ARCHITECTURE.md)
- [Deploy](docs/DEPLOY.md)
- [Releases](docs/RELEASES.md)
- [Variáveis](docs/VARIABLES.md)
- [Como contribuir](CONTRIBUTING.md)
- [Segurança](SECURITY.md)

A fonte canônica é `docs/source/autom8-docs.json`.
O README, os dados do website e a ajuda da CLI são
sincronizados por `scripts/sync-docs.sh`.

## Roadmap

1. concluir `autom8 self-update`;
2. ampliar os testes multidistro;
3. implementar `autom8 backup`;
4. adicionar rollback antes de operações sensíveis;
5. fortalecer a cadeia de releases com checksum e SBOM.

Acompanhe a visão completa no
[roadmap oficial](https://autom8.oslabs.com.br/roadmap).

## Licença

Distribuído sob a [GNU GPL-3.0](LICENSE).

---

<p align="center">
  <img
    src="site/public/branding/favicon.png"
    alt=""
    width="52"
  />
</p>

<p align="center">
  <strong>AutoM8</strong><br />
  Um produto OSLabs para a comunidade Linux.
</p>
