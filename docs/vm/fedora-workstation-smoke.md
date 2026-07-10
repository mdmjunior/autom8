# AutoM8 — Smoke test em Fedora Workstation

Este guia valida a branch `feature/apps-v0.2` em Fedora Workstation antes da release estável.

## Requisitos da VM

Recomendado:

- Fedora Workstation atual
- 2 vCPU
- 4 GB RAM mínimo
- 25 GB disco mínimo
- usuário com sudo
- snapshot antes do teste
- internet funcional

## Preparar a VM

    sudo dnf install -y git curl jq tar gzip

## Clonar a branch

    git clone -b feature/apps-v0.2 https://github.com/mdmjunior/autom8.git
    cd autom8

## Rodar smoke test Fedora

    ./scripts/smoke-fedora-workstation.sh

## Modo estrito

Por padrão, os testes de categorias e perfis em Fedora são exploratórios. Isso ajuda a mapear diferenças de pacotes entre distros sem bloquear o smoke inteiro.

Para transformar falhas exploratórias em erro:

    AUTOM8_FEDORA_STRICT=1 ./scripts/smoke-fedora-workstation.sh

## O que o smoke valida

- sintaxe shell;
- catálogo de apps;
- catálogo de perfis;
- instalador;
- comandos básicos da CLI;
- apps básicos em dry-run;
- bloqueio de app advanced;
- dry-runs exploratórios de categorias;
- dry-runs exploratórios de perfis;
- geração de pacote local temporário.

## Teste com pacote RC2

Depois de publicar `v0.2.0-rc2`:

    sudo rm -rf /opt/autom8
    sudo dnf install -y curl git jq tar gzip

    curl -fsSL https://autom8.oslabs.com.br/install.sh -o /tmp/autom8-install.sh

    AUTOM8_PACKAGE_URL=https://github.com/mdmjunior/autom8/releases/download/v0.2.0-rc2/autom8-0.2.0-rc2.tar.gz bash /tmp/autom8-install.sh

Depois:

    export PATH="/opt/autom8/bin:$PATH"

    autom8 --version
    autom8 doctor
    autom8 apps categories
    autom8 apps list --category sistema
    autom8 profiles list
    autom8 --dry-run apps install git
    autom8 --dry-run apps install-many git htop jq
    autom8 --dry-run profiles install dev-essential

## Critérios de sucesso

O smoke é considerado aprovado quando:

- scripts passam em `bash -n`;
- catálogos passam nos validadores;
- CLI responde;
- apps básicos em dry-run funcionam;
- app advanced é bloqueado;
- pacote local é gerado;
- falhas exploratórias são revisadas e classificadas.

## Observação

Fedora pode ter diferenças de nomes de pacotes em relação a Ubuntu. Quando um dry-run por categoria ou perfil falhar, avalie se o catálogo precisa ajustar o nome do pacote para `dnf`.
