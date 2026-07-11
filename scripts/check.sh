#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# shellcheck source=/dev/null
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common/project.sh"

target="${1:-all}"

case "$target" in
  repo)
    "${PROJECT_ROOT}/scripts/common/check-repository.sh"
    ;;

  cli)
    "${PROJECT_ROOT}/scripts/common/check-repository.sh"
    "${PROJECT_ROOT}/scripts/cli/check.sh"
    ;;

  website)
    "${PROJECT_ROOT}/scripts/common/check-repository.sh"
    "${PROJECT_ROOT}/scripts/website/check.sh"
    ;;

  all)
    "${PROJECT_ROOT}/scripts/common/check-repository.sh"
    "${PROJECT_ROOT}/scripts/cli/check.sh"
    "${PROJECT_ROOT}/scripts/website/check.sh"
    ;;

  *)
    error "Uso: ./scripts/check.sh [repo|cli|website|all]"
    ;;
esac

log "Validação concluída: ${target}"
