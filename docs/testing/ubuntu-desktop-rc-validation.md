# AutoM8 v0.2.0-rc1 — Validação em Ubuntu Desktop

Este checklist valida o AutoM8 v0.2.0-rc1 em uma VM Ubuntu Desktop descartável.

## Ambiente recomendado

- Ubuntu Desktop 24.04 LTS ou superior
- 2 vCPU
- 4 GB RAM mínimo
- 25 GB disco mínimo
- usuário comum com sudo
- snapshot antes do teste
- internet funcional

## Dados do teste

Preencher após execução:

    Data:
    VM:
    Ubuntu:
    CPU:
    RAM:
    Disco:
    Usuário:
    Snapshot criado: sim/não
    Resultado geral: aprovado/reprovado/parcial

## Fase 1 — Preparar VM

    sudo apt update
    sudo apt install -y curl git jq

Critério:

- comandos instalam sem erro;
- usuário consegue usar sudo.

## Fase 2 — Testar por clone da branch

    git clone -b feature/apps-v0.2 https://github.com/mdmjunior/autom8.git
    cd autom8

    ./scripts/smoke-ubuntu-desktop.sh

Critérios:

- smoke termina com sucesso;
- catálogos passam;
- dry-runs passam;
- app advanced é bloqueado;
- package temporário é gerado.

## Fase 3 — Testar instalador com pacote RC

Em uma nova VM ou após restaurar snapshot:

    sudo apt update
    sudo apt install -y curl

    curl -fsSL https://autom8.oslabs.com.br/install.sh -o /tmp/autom8-install.sh

    AUTOM8_PACKAGE_URL=https://github.com/mdmjunior/autom8/releases/download/v0.2.0-rc1/autom8-0.2.0-rc1.tar.gz bash /tmp/autom8-install.sh

Depois:

    export PATH="/opt/autom8/bin:$PATH"

    autom8 --version
    autom8 doctor

Critérios:

- instalação conclui;
- `autom8 --version` mostra 0.2.0-rc1;
- `autom8 doctor` executa;
- PATH funciona na sessão atual.

## Fase 4 — Validar Apps

    autom8 apps categories
    autom8 apps list --category sistema
    autom8 apps list --category desenvolvimento
    autom8 apps show git
    autom8 apps show steam

    autom8 --dry-run apps install git
    autom8 --dry-run apps install-many git htop jq
    autom8 --dry-run apps install-category sistema
    autom8 --dry-run apps install-category desenvolvimento
    autom8 --dry-run apps install steam || true

Critérios:

- categorias são listadas;
- apps aparecem por categoria;
- `git` mostra detalhes;
- `steam` aparece como advanced;
- dry-runs não alteram sistema;
- steam é bloqueado para instalação automática.

## Fase 5 — Validar Perfis

    autom8 profiles list
    autom8 profiles show dev-essential
    autom8 profiles show server-basic

    autom8 --dry-run profiles install dev-essential
    autom8 --dry-run profiles install server-basic
    autom8 --dry-run profiles remove dev-essential

Critérios:

- perfis são listados;
- detalhes mostram apps;
- dry-runs não alteram sistema;
- instalação/remoção de perfil reaproveita fluxo de apps.

## Fase 6 — Instalação real controlada

Executar somente em VM descartável com snapshot.

    autom8 apps install git
    autom8 apps install-category sistema
    autom8 profiles install dev-essential

Critérios:

- cada ação pede confirmação;
- pacotes são validados antes da instalação;
- instalação executa sem quebrar a CLI;
- comando `autom8 doctor` ainda funciona depois.

## Fase 7 — Remoção real controlada

Executar somente se a VM puder ser descartada.

    autom8 apps remove git
    autom8 apps remove-category sistema

Critérios:

- cada ação pede confirmação;
- pacotes instalados são detectados;
- ação informa risco de afetar uso fora do AutoM8;
- remoção não quebra a CLI.

## Fase 8 — Relatório final

Registrar:

    Resultado geral:
    Bloqueios:
    Bugs:
    Ajustes necessários:
    Pode promover para v0.2.0 estável? sim/não

## Critérios para promover para v0.2.0

Promover apenas se:

- smoke passou;
- RC instalou via override de `AUTOM8_PACKAGE_URL`;
- CLI executou após instalação;
- Apps funcionaram em dry-run;
- Perfis funcionaram em dry-run;
- apps advanced foram bloqueados;
- nenhuma ação real quebrou a VM de teste;
- não há bug crítico aberto.
