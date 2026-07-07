#!/usr/bin/env bash

autom8_module_self_update() {
  autom8_title "AutoM8 self-update"

  local repo="${AUTOM8_GITHUB_REPO:-mdmjunior/autom8}"
  local package_url="${AUTOM8_PACKAGE_URL:-https://github.com/${repo}/releases/latest/download/autom8-latest.tar.gz}"
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  autom8_warn_ui "Self-update ainda está em modo inicial."
  autom8_note "Origem estável configurada:"
  autom8_note "$package_url"
  autom8_note "A atualização automática com rollback será implementada em versão futura."

  if autom8_confirm "Deseja baixar o pacote estável mais recente para validação?"; then
    if curl -fsSL "$package_url" -o "$tmp_dir/autom8-latest.tar.gz"; then
      autom8_success "Pacote baixado para validação: $tmp_dir/autom8-latest.tar.gz"
      tar -tzf "$tmp_dir/autom8-latest.tar.gz" >/dev/null
      autom8_success "Arquivo tar.gz validado."
      autom8_summary_ok "Pacote estável validado"
    else
      autom8_error_ui "Não foi possível baixar o pacote estável."
      autom8_summary_fail "Falha ao baixar pacote estável"
      rm -rf "$tmp_dir"
      return 1
    fi
  else
    autom8_warn_ui "Validação de pacote cancelada."
    autom8_summary_warn "Self-update cancelado"
  fi

  rm -rf "$tmp_dir"
}
