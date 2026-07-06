# AutoM8 - Linux Management Suite

AutoM8 é uma suíte local da OSLabs para gerenciamento de sistemas Linux.

O objetivo é oferecer uma CLI moderna, modular e segura para atualização, limpeza, diagnóstico, instalação de apps, perfis de uso, segurança básica, Docker, usuários e relatórios.

## Instalação

```bash
curl -fsSL https://autom8.oslabs.com.br/install.sh | bash
```

Depois da instalação:

```bash
export PATH="/opt/autom8/bin:$PATH"
autom8
```

## Comandos iniciais

```bash
autom8
autom8 --version
autom8 doctor
autom8 diagnose
autom8 update
autom8 clean
autom8 clean --dry-run
autom8 security
autom8 docker
autom8 users
autom8 report
autom8 self-update
```

## Estrutura

```txt
/opt/autom8/
├── bin/
├── config/
├── core/
├── modules/
├── profiles/
├── catalog/
├── i18n/
├── logs/
├── backups/
├── reports/
└── tmp/
```

## Distros planejadas

- Ubuntu
- Debian
- Fedora
- Rocky Linux
- AlmaLinux
- openSUSE
- Arch Linux
- Manjaro

## Site

https://autom8.oslabs.com.br

## Status

Versão inicial em desenvolvimento: 0.1.0.
