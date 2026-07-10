#!/usr/bin/env bash

AUTOM8_APPS_LIB_DIR="${AUTOM8_ROOT}/lib/apps"

autom8_apps_source_lib() {
  local lib_file="$1"

  if [[ ! -f "$lib_file" ]]; then
    printf 'AutoM8 Apps: biblioteca não encontrada: %s\n' "$lib_file" >&2
    return 1
  fi

  # shellcheck source=/dev/null
  source "$lib_file"
}

autom8_apps_source_lib "$AUTOM8_APPS_LIB_DIR/catalog.sh" || return 1
autom8_apps_source_lib "$AUTOM8_APPS_LIB_DIR/packages.sh" || return 1
autom8_apps_source_lib "$AUTOM8_APPS_LIB_DIR/install.sh" || return 1
autom8_apps_source_lib "$AUTOM8_APPS_LIB_DIR/remove.sh" || return 1
autom8_apps_source_lib "$AUTOM8_APPS_LIB_DIR/menu.sh" || return 1
autom8_apps_source_lib "$AUTOM8_APPS_LIB_DIR/module.sh" || return 1
