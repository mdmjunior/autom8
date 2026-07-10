#!/usr/bin/env bash

# AutoM8 Apps internal library.
# Este arquivo é carregado por suite/modules/apps.sh.

autom8_module_apps() {
  local action="${1:-menu}"
  shift || true

  case "$action" in
    menu|"")
      autom8_apps_menu
      ;;
    list)
      autom8_apps_list "$@"
      ;;
    categories)
      autom8_apps_categories "$@"
      ;;
    search)
      autom8_apps_search "$@"
      ;;
    show)
      autom8_apps_show "$@"
      ;;
    install)
      autom8_apps_install "$@"
      ;;
    install-many)
      autom8_apps_install_many "$@"
      ;;
    install-category)
      autom8_apps_install_category "$@"
      ;;
    remove)
      autom8_apps_remove "$@"
      ;;
    remove-many)
      autom8_apps_remove_many "$@"
      ;;
    remove-category)
      autom8_apps_remove_category "$@"
      ;;
    update-catalog)
      autom8_apps_update_catalog "$@"
      ;;
    *)
      autom8_error_ui "Ação desconhecida em apps: $action"
      autom8_note "Uso: autom8 apps [categories|list|list --category <categoria>|search|show|install|install-many|install-category|remove|remove-many|remove-category|update-catalog]"
      autom8_summary_fail "Ação de apps desconhecida"
      return 1
      ;;
  esac
}
