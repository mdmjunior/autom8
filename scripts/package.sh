#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

printf '%s\n' \
  '[AutoM8] ERRO: o empacotador Bash da versão 0.2 não é compatível com a nova fundação Rust.' \
  '[AutoM8] O empacotamento da versão 0.3 será implementado na Etapa 8, com checksum, assinatura e SBOM.' \
  '[AutoM8] Nenhum pacote foi criado.' >&2

exit 1
