# AutoM8 v0.2 — Smoke test em Ubuntu Desktop

Este guia valida a branch `feature/apps-v0.2` em uma VM Ubuntu Desktop antes da release oficial.

## Quando usar

Use este fluxo para teste de desenvolvimento.

Ainda não use o instalador público:

    curl -fsSL https://autom8.oslabs.com.br/install.sh | bash

O instalador público baixa a última release estável publicada no GitHub Releases, não a branch de desenvolvimento.

## Requisitos da VM

Recomendado:

- Ubuntu Desktop 24.04 LTS ou superior
- 2 vCPU
- 4 GB RAM mínimo
- 25 GB disco mínimo
- usuário com sudo
- snapshot antes do teste

## Preparar a VM

    sudo apt update
    sudo apt install -y git curl jq

## Clonar a branch

    git clone -b feature/apps-v0.2 https://github.com/mdmjunior/autom8.git
    cd autom8

## Rodar smoke test seguro

    ./scripts/smoke-ubuntu-desktop.sh

O smoke test executa:

- validação de shell scripts;
- geração do catálogo de apps;
- validação do catálogo de apps;
- validação do catálogo de perfis;
- validação do instalador;
- comandos básicos da CLI;
- dry-runs de apps;
- dry-runs de perfis;
- validação de bloqueio de apps advanced;
- geração de pacote local temporário.

## Comandos úteis para teste manual

    ./suite/bin/autom8 --version
    ./suite/bin/autom8 doctor
    ./suite/bin/autom8 apps categories
    ./suite/bin/autom8 apps list --category sistema
    ./suite/bin/autom8 apps list --category desenvolvimento
    ./suite/bin/autom8 apps show git
    ./suite/bin/autom8 profiles list
    ./suite/bin/autom8 profiles show dev-essential
    ./suite/bin/autom8 --dry-run apps install-category sistema
    ./suite/bin/autom8 --dry-run profiles install dev-essential

## Teste real controlado

Somente em VM descartável:

    ./suite/bin/autom8 apps install git
    ./suite/bin/autom8 apps install-category sistema
    ./suite/bin/autom8 profiles install dev-essential

Antes de rodar instalação real, confirme:

- snapshot criado;
- VM descartável;
- rede ok;
- apt update executado;
- você aceita instalar/remover pacotes reais.

## Critérios de sucesso

O smoke é considerado aprovado quando:

- scripts passam em `bash -n`;
- catálogos passam nos validadores;
- `doctor` não quebra execução;
- comandos `apps` listam categorias e apps;
- comandos `profiles` listam e detalham perfis;
- dry-runs não alteram sistema;
- app advanced, como steam, é bloqueado;
- pacote local temporário contém bin, modules, lib, catalog e docs.

## Quando usar o instalador público

Apenas após:

1. merge da branch v0.2 na main;
2. publicação da release v0.2.0;
3. confirmação de asset `autom8-latest.tar.gz` no GitHub Releases;
4. deploy do site atualizado.

Depois disso:

    curl -fsSL https://autom8.oslabs.com.br/install.sh | bash

## Teste com pacote RC publicado

Depois que a prerelease `v0.2.0-rc1` estiver publicada:

    curl -fsSL https://autom8.oslabs.com.br/install.sh -o /tmp/autom8-install.sh
    AUTOM8_PACKAGE_URL=https://github.com/mdmjunior/autom8/releases/download/v0.2.0-rc1/autom8-0.2.0-rc1.tar.gz bash /tmp/autom8-install.sh

Depois:

    export PATH="/opt/autom8/bin:$PATH"

    autom8 --version
    autom8 doctor
    autom8 apps categories
    autom8 apps list --category sistema
    autom8 profiles list
    autom8 --dry-run apps install-category sistema
    autom8 --dry-run profiles install dev-essential

O comando público direto abaixo continua reservado para release estável:

    curl -fsSL https://autom8.oslabs.com.br/install.sh | bash

## Verificação pós-instalação do RC

Após instalar o RC em `/opt/autom8`, copie ou baixe o script de verificação e rode:

    /opt/autom8/bin/autom8 --version

Se estiver trabalhando pelo clone da branch:

    ./scripts/verify-installed-rc.sh

Ou apontando manualmente para o binário instalado:

    AUTOM8_BIN=/opt/autom8/bin/autom8 AUTOM8_EXPECTED_VERSION=0.2.0-rc1 ./scripts/verify-installed-rc.sh

Esse script valida:

- versão instalada;
- doctor;
- apps;
- profiles;
- dry-runs;
- bloqueio de app advanced.
