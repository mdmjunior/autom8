#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common/project.sh"

target="${1:-all}"

case "$target" in
  cli)
    "${PROJECT_ROOT}/scripts/cli/check.sh"
    ;;

  website)
    "${PROJECT_ROOT}/scripts/website/check.sh"
    ;;

  all)
    "${PROJECT_ROOT}/scripts/cli/check.sh"
    "${PROJECT_ROOT}/scripts/website/check.sh"
    ;;

  *)
    error "Uso: ./scripts/check.sh [all|cli|website]"
    ;;
esac

log "Validação concluída: ${target}"
