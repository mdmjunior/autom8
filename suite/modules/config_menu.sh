#!/usr/bin/env bash

# Variáveis globais alteradas neste módulo são persistidas por autom8_save_config.
# shellcheck disable=SC2034

autom8_module_config() {
  autom8_title "Configurações"

  local option
  option="$(autom8_choose "Escolha uma configuração" \
    "Idioma" \
    "Modo padrão" \
    "Nível de limpeza padrão" \
    "Mostrar configuração atual" \
    "Voltar")" || return 0

  case "$option" in
    "Idioma")
      local lang
      lang="$(autom8_choose "Idioma" "pt-BR" "en-US")" || return 0
      AUTOM8_LANGUAGE="$lang"
      autom8_save_config
      autom8_success "Idioma salvo: $lang"
      ;;
    "Modo padrão")
      local mode
      mode="$(autom8_choose "Modo padrão" "safe" "complete")" || return 0
      AUTOM8_MODE="$mode"
      autom8_save_config
      autom8_success "Modo salvo: $mode"
      ;;
    "Nível de limpeza padrão")
      local level
      level="$(autom8_choose "Nível de limpeza" "safe" "advanced" "aggressive")" || return 0
      AUTOM8_DEFAULT_CLEAN_LEVEL="$level"
      autom8_save_config
      autom8_success "Nível salvo: $level"
      ;;
    "Mostrar configuração atual")
      cat "$AUTOM8_CONFIG_FILE"
      ;;
    *)
      return 0
      ;;
  esac

  autom8_summary_ok "Configurações verificadas/alteradas"
}
