# AutoM8

AutoM8 é uma CLI local para instalar aplicativos, aplicar perfis e executar manutenção Linux com confirmação, logs e modo de simulação.

[Site oficial](https://autom8.oslabs.com.br) · [Documentação](https://autom8.oslabs.com.br/docs) · [Releases](https://github.com/mdmjunior/autom8/releases)

## Estado atual

- Versão estável: `0.2.0`
- Catálogo: **76 apps**, **10 categorias** e **6 perfis**
- Validado em Ubuntu Desktop e Fedora Workstation.
- Compatível com fluxos baseados em `apt`, `dnf`, `zypper` e `pacman`.

## Instalação

Execute com um usuário comum que tenha permissão de `sudo`:

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

Use `autom8 help` para a lista completa e `autom8 help <comando>` para detalhes.

### Em evolução

- **Parcial:** `autom8 self-update` — Valida o pacote estável mais recente publicado no GitHub Releases.
- **Planejado:** `autom8 backup` — Backups simples antes de operações sensíveis.
- **Planejado:** `autom8 upgrade-distro` — Preparação futura para upgrade de versão da distro.

## Desenvolvimento

```bash
./scripts/bootstrap-dev.sh
./scripts/sync-docs.sh
./scripts/check.sh all
./scripts/website/build.sh
```

Fluxo do projeto: mudanças entram em `develop`; a promoção para `main` ocorre por pull request com Quality Gate.

## Estrutura

```text
suite/      CLI instalada em /opt/autom8
installer/  instalador público
site/       website Astro
docs/       fonte e documentos técnicos
scripts/    validação, build, pacote e release
```

## Documentação do repositório

- [Índice técnico](docs/README.md)
- [Arquitetura](docs/ARCHITECTURE.md)
- [Releases](docs/RELEASES.md)
- [Variáveis](docs/VARIABLES.md)
- [Como contribuir](CONTRIBUTING.md)
- [Segurança](SECURITY.md)

A fonte canônica é `docs/source/autom8-docs.json`. Arquivos gerados não devem ser editados isoladamente.

## Licença

[GNU GPL-3.0](LICENSE).

AutoM8 é um produto OSLabs para a comunidade Linux.
