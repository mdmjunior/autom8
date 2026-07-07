# Arquitetura do AutoM8

O AutoM8 é dividido em quatro áreas principais:

```text
suite/      # suíte instalada em /opt/autom8
installer/  # instalador público install.sh
site/       # site oficial em Astro
scripts/    # sincronização, build, deploy, pacote e release
docs/       # fonte única e documentos auxiliares
```

## Runtime

A CLI principal fica em `suite/bin/autom8`.

Os módulos ficam em `suite/modules/`.

O núcleo compartilhado fica em `suite/core/`.

## Documentação

A documentação nasce em `docs/source/autom8-docs.json` e é sincronizada por `scripts/sync-docs.sh`.

## Pacotes

Pacotes são gerados temporariamente por `scripts/package.sh` e publicados por `scripts/release-stable.sh`.
