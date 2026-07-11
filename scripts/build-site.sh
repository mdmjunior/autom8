#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

printf '[AutoM8] AVISO: scripts/build-site.sh é um wrapper transitório.\n' >&2
printf '[AutoM8] Use ./scripts/website/build.sh.\n' >&2

exec "${PROJECT_ROOT}/scripts/website/build.sh"
