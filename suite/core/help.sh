#!/usr/bin/env bash

autom8_help_index() {
  local help_file="$AUTOM8_ROOT/docs/help.txt"

  if [[ -f "$help_file" ]]; then
    cat "$help_file"
    return 0
  fi

  cat <<'EOF_FALLBACK'
AutoM8 - Linux Management Suite

Uso:
  autom8
  autom8 help
  autom8 help <comando>
  autom8 --version

A documentação local não foi encontrada.
Execute autom8 doctor para validar a instalação.
EOF_FALLBACK
}

autom8_help_command() {
  local command_name="${1:-}"
  local help_dir="$AUTOM8_ROOT/docs/help"
  local help_file=""

  case "$command_name" in
    ""|help|--help|-h)
      autom8_help_index
      return 0
      ;;
    --version|-v|version)
      help_file="$help_dir/version.txt"
      ;;
    upgrade-distro)
      help_file="$help_dir/upgrade-distro.txt"
      ;;
    self-update)
      help_file="$help_dir/self-update.txt"
      ;;
    *)
      help_file="$help_dir/${command_name}.txt"
      ;;
  esac

  if [[ -f "$help_file" ]]; then
    cat "$help_file"
    return 0
  fi

  autom8_warn_ui "Ajuda específica não encontrada para: $command_name"
  echo
  autom8_help_index
}
