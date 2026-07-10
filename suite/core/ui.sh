#!/usr/bin/env bash

AUTOM8_UI_PRIMARY="${AUTOM8_UI_PRIMARY:-39}"
AUTOM8_UI_INFO="${AUTOM8_UI_INFO:-45}"
AUTOM8_UI_SUCCESS="${AUTOM8_UI_SUCCESS:-42}"
AUTOM8_UI_WARN="${AUTOM8_UI_WARN:-214}"
AUTOM8_UI_ERROR="${AUTOM8_UI_ERROR:-196}"
AUTOM8_UI_MUTED="${AUTOM8_UI_MUTED:-244}"
AUTOM8_UI_TEXT="${AUTOM8_UI_TEXT:-255}"

autom8_has_gum() {
  command -v gum >/dev/null 2>&1
}

autom8_style() {
  local foreground="${1:-$AUTOM8_UI_TEXT}"
  shift

  if autom8_has_gum; then
    gum style --foreground "$foreground" "$@"
  else
    printf '%s\n' "$*"
  fi
}

autom8_header() {
  local title="${1:-AutoM8 · Linux Management Suite}"
  local subtitle="${2:-Automação Linux local com clareza e controle.}"

  if autom8_has_gum; then
    gum style \
      --border rounded \
      --padding "1 2" \
      --margin "1 0" \
      --foreground "$AUTOM8_UI_PRIMARY" \
      "$title"$'\n'"$subtitle"
  else
    printf '\n'
    printf '========================================\n'
    printf '%s\n' "$title"
    printf '%s\n' "$subtitle"
    printf '========================================\n'
    printf '\n'
  fi
}

autom8_title() {
  local text="$1"

  if autom8_has_gum; then
    gum style \
      --border rounded \
      --padding "1 2" \
      --margin "1 0" \
      --foreground "$AUTOM8_UI_PRIMARY" \
      "$text"
  else
    printf '\n=== %s ===\n\n' "$text"
  fi
}

autom8_section() {
  local text="$1"

  if autom8_has_gum; then
    gum style --foreground "$AUTOM8_UI_INFO" --bold "$text"
  else
    printf '\n%s\n' "$text"
  fi
}

autom8_divider() {
  if autom8_has_gum; then
    gum style --foreground "$AUTOM8_UI_MUTED" "────────────────────────────────────────"
  else
    printf '%s\n' '----------------------------------------'
  fi
}

autom8_key_value() {
  local key="$1"
  local value="${2:-}"

  printf '  %-22s %s\n' "$key:" "$value"
}

autom8_status_line() {
  local status="$1"
  local message="$2"
  local color="$AUTOM8_UI_TEXT"

  case "$status" in
    OK) color="$AUTOM8_UI_SUCCESS" ;;
    AVISO) color="$AUTOM8_UI_WARN" ;;
    FALHA|ERRO) color="$AUTOM8_UI_ERROR" ;;
  esac

  if autom8_has_gum; then
    printf '  '
    gum style --foreground "$color" --bold "$(printf '%-7s' "$status")"
    printf ' %s\n' "$message"
  else
    printf '  %-7s %s\n' "$status" "$message"
  fi
}

autom8_status_ok() {
  autom8_status_line "OK" "$1"
}

autom8_status_warn() {
  autom8_status_line "AVISO" "$1"
}

autom8_status_fail() {
  autom8_status_line "FALHA" "$1"
}

autom8_note() {
  local text="$1"
  autom8_style "$AUTOM8_UI_MUTED" "$text"
}

autom8_success() {
  local text="$1"

  if autom8_has_gum; then
    gum style --foreground "$AUTOM8_UI_SUCCESS" --bold "OK: $text"
  else
    printf 'OK: %s\n' "$text"
  fi
}

autom8_warn_ui() {
  local text="$1"

  if autom8_has_gum; then
    gum style --foreground "$AUTOM8_UI_WARN" --bold "AVISO: $text"
  else
    printf 'AVISO: %s\n' "$text"
  fi
}

autom8_error_ui() {
  local text="$1"

  if autom8_has_gum; then
    gum style --foreground "$AUTOM8_UI_ERROR" --bold "ERRO: $text" >&2
  else
    printf 'ERRO: %s\n' "$text" >&2
  fi
}

autom8_confirm() {
  local question="$1"

  if autom8_has_gum; then
    gum confirm "$question"
  else
    local answer
    read -r -p "$question [s/N]: " answer
    [[ "$answer" =~ ^[sS]$ ]]
  fi
}

autom8_choose() {
  local header="$1"
  shift

  if autom8_has_gum; then
    printf '%s\n' "$@" | gum choose --header "$header" --height 14
  else
    local options=("$@")
    local i
    local choice

    printf '\n%s\n' "$header"

    for i in "${!options[@]}"; do
      printf '%s) %s\n' "$((i + 1))" "${options[$i]}"
    done

    read -r -p "Escolha: " choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
      printf '%s\n' "${options[$((choice - 1))]}"
    else
      return 1
    fi
  fi
}

autom8_pause() {
  if autom8_has_gum; then
    gum input --placeholder "Pressione Enter para continuar..." >/dev/null || true
  else
    read -r -p "Pressione Enter para continuar..." _
  fi
}
