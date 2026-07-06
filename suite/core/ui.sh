#!/usr/bin/env bash

autom8_has_gum() {
  command -v gum >/dev/null 2>&1
}

autom8_title() {
  local text="$1"
  if autom8_has_gum; then
    gum style --border rounded --padding "1 2" --margin "1 0" --foreground 39 "$text"
  else
    printf '\n=== %s ===\n\n' "$text"
  fi
}

autom8_note() {
  local text="$1"
  if autom8_has_gum; then
    gum style --foreground 244 "$text"
  else
    printf '%s\n' "$text"
  fi
}

autom8_success() {
  local text="$1"
  if autom8_has_gum; then
    gum style --foreground 42 "OK: $text"
  else
    printf 'OK: %s\n' "$text"
  fi
}

autom8_warn_ui() {
  local text="$1"
  if autom8_has_gum; then
    gum style --foreground 214 "AVISO: $text"
  else
    printf 'AVISO: %s\n' "$text"
  fi
}

autom8_error_ui() {
  local text="$1"
  if autom8_has_gum; then
    gum style --foreground 196 "ERRO: $text"
  else
    printf 'ERRO: %s\n' "$text" >&2
  fi
}

autom8_confirm() {
  local question="$1"
  if autom8_has_gum; then
    gum confirm "$question"
  else
    read -r -p "$question [s/N]: " answer
    [[ "$answer" =~ ^[sS]$ ]]
  fi
}

autom8_choose() {
  local header="$1"
  shift

  if autom8_has_gum; then
    printf '%s\n' "$@" | gum choose --header "$header"
  else
    local options=("$@")
    local i
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
