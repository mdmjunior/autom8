#!/usr/bin/env bash

# AutoM8 Apps internal library.
# Este arquivo é carregado por suite/modules/apps.sh.

autom8_apps_menu() {
  while true; do
    clear || true
    autom8_header "Apps" "Instalação por catálogo local atualizável."

    local choice
    choice="$(autom8_choose "O que deseja fazer?" \
      "Listar apps" \
      "Listar categorias" \
      "Listar por categoria" \
      "Buscar app" \
      "Ver detalhes" \
      "Instalar app" \
      "Instalar vários apps" \
      "Instalar categoria" \
      "Remover app" \
      "Remover vários apps" \
      "Remover categoria" \
      "Atualizar catálogo" \
      "Voltar")" || return 0

    clear || true

    case "$choice" in
      "Listar apps")
        autom8_apps_list
        ;;
      "Listar categorias")
        autom8_apps_categories
        ;;
      "Listar por categoria")
        local category
        if autom8_has_gum; then
          category="$(jq -r '.categories[].slug' "$(autom8_apps_catalog_file)" | gum choose --header "Categoria" --height 12)"
        else
          read -r -p "Categoria: " category
        fi
        autom8_apps_list --category "$category"
        ;;
      "Buscar app")
        local query
        if autom8_has_gum; then
          query="$(gum input --placeholder "Termo de busca")"
        else
          read -r -p "Termo de busca: " query
        fi
        autom8_apps_search "$query"
        ;;
      "Ver detalhes")
        local app_id
        if autom8_has_gum; then
          app_id="$(gum input --placeholder "ID do app")"
        else
          read -r -p "ID do app: " app_id
        fi
        autom8_apps_show "$app_id"
        ;;
      "Instalar app")
        local install_id
        if autom8_has_gum; then
          install_id="$(gum input --placeholder "ID do app")"
        else
          read -r -p "ID do app: " install_id
        fi
        autom8_apps_install "$install_id"
        ;;
      "Remover app")
        local remove_id
        if autom8_has_gum; then
          remove_id="$(gum input --placeholder "ID do app")"
        else
          read -r -p "ID do app: " remove_id
        fi
        autom8_apps_remove "$remove_id"
        ;;
      "Instalar vários apps")
        autom8_apps_install_many
        ;;
      "Instalar categoria")
        autom8_apps_install_category
        ;;
      "Remover vários apps")
        autom8_apps_remove_many
        ;;
      "Remover categoria")
        autom8_apps_remove_category
        ;;
      "Atualizar catálogo")
        autom8_apps_update_catalog
        ;;
      "Voltar")
        return 0
        ;;
    esac

    echo
    autom8_print_summary
    echo
    autom8_pause
    autom8_reset_summary
  done
}
