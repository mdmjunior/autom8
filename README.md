# AutoM8 - Linux Management Suite

AutoM8 é uma suíte local para preparar, diagnosticar, atualizar e manter ambientes Linux com clareza, logs e controle do usuário.

**AutoM8 by OSLabs**

## Site

https://autom8.oslabs.com.br

## Instalação

Execute com um usuário comum que tenha permissão de `sudo`:

```bash
curl -fsSL https://autom8.oslabs.com.br/install.sh | bash
```

Depois da instalação:

```bash
export PATH="/opt/autom8/bin:$PATH"
autom8
autom8 doctor
```

## Distribuição estável

O instalador baixa a última versão estável publicada em GitHub Releases:

```text
https://github.com/mdmjunior/autom8/releases/latest/download/autom8-latest.tar.gz
```

A VPS não hospeda pacotes da suíte. O site publica o instalador e a documentação.

## Comandos principais

```bash
autom8
autom8 --version
autom8 doctor
autom8 diagnose
autom8 update
autom8 clean
autom8 security
autom8 docker
autom8 users
autom8 config
autom8 report
autom8 apps
autom8 profiles
autom8 backup
autom8 upgrade-distro
autom8 self-update
```

## Status dos módulos

| Módulo | Comando | Status | Versão |
| --- | --- | --- | --- |
| Doctor | `autom8 doctor` | available | 0.1.0 |
| Diagnóstico | `autom8 diagnose` | available | 0.1.0 |
| Atualização do Sistema | `autom8 update` | available | 0.1.0 |
| Limpeza | `autom8 clean` | available | 0.1.0 |
| Segurança | `autom8 security` | available | 0.1.0 |
| Docker | `autom8 docker` | available | 0.1.0 |
| Usuários | `autom8 users` | available | 0.1.0 |
| Configurações | `autom8 config` | available | 0.1.0 |
| Relatórios | `autom8 report` | available | 0.1.0 |
| Apps | `autom8 apps` | planned | 0.2.0 |
| Perfis | `autom8 profiles` | planned | 0.2.0 |
| Backup | `autom8 backup` | planned | 0.3.0 |

## Documentação

- Site: `https://autom8.oslabs.com.br/docs`
- Fonte única: `docs/source/autom8-docs.json`
- Help da CLI: `suite/docs/help.txt` e `suite/docs/help/`

## Desenvolvimento

```bash
./scripts/sync-docs.sh
./scripts/build-site.sh
```

## Release estável

Após merge na `main`:

```bash
./scripts/release-stable.sh
```

## Créditos

AutoM8 by OSLabs.

Criado por Marcio Moreira Junior para a comunidade Linux.
