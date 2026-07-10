#!/usr/bin/env bash

# AutoM8 Apps internal library.
# Este arquivo é carregado por suite/modules/apps.sh.

autom8_apps_package_available() {
  local package_name="$1"

  case "$AUTOM8_PACKAGE_MANAGER" in
    apt)
      if command -v dpkg-query >/dev/null 2>&1 && dpkg-query -W -f='${Status}' "$package_name" 2>/dev/null | grep -q "install ok installed"; then
        return 0
      fi

      if command -v apt-cache >/dev/null 2>&1; then
        local candidate
        candidate="$(apt-cache policy "$package_name" 2>/dev/null | awk '/Candidate:/ {print $2; exit}')"
        [[ -n "$candidate" && "$candidate" != "(none)" ]]
        return $?
      fi
      ;;

    dnf)
      if command -v rpm >/dev/null 2>&1 && rpm -q "$package_name" >/dev/null 2>&1; then
        return 0
      fi

      dnf list "$package_name" >/dev/null 2>&1
      return $?
      ;;

    zypper)
      if command -v rpm >/dev/null 2>&1 && rpm -q "$package_name" >/dev/null 2>&1; then
        return 0
      fi

      zypper --non-interactive search --match-exact "$package_name" 2>/dev/null | awk -F'|' -v pkg="$package_name" '
        NR > 2 {
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
          if ($2 == pkg) found=1
        }
        END {exit found ? 0 : 1}
      '
      return $?
      ;;

    pacman)
      pacman -Qi "$package_name" >/dev/null 2>&1 || pacman -Si "$package_name" >/dev/null 2>&1
      return $?
      ;;
  esac

  return 1
}

autom8_apps_validate_packages_available() {
  local package_name
  local missing=0

  autom8_section "Validação de pacotes"

  for package_name in "$@"; do
    if autom8_apps_package_available "$package_name"; then
      autom8_status_ok "Pacote disponível: $package_name"
    else
      autom8_status_fail "Pacote indisponível: $package_name"
      missing=$((missing + 1))
    fi
  done

  if [[ "$missing" -gt 0 ]]; then
    autom8_warn_ui "Um ou mais pacotes não estão disponíveis nos repositórios atuais."
    autom8_note "Atualize o catálogo/repositórios ou habilite o repositório necessário antes de instalar."
    return 1
  fi

  return 0
}

autom8_apps_package_installed() {
  local package_name="$1"

  case "$AUTOM8_PACKAGE_MANAGER" in
    apt)
      command -v dpkg-query >/dev/null 2>&1 || return 1
      dpkg-query -W -f='${Status}' "$package_name" 2>/dev/null | grep -q "install ok installed"
      ;;
    dnf|zypper)
      command -v rpm >/dev/null 2>&1 || return 1
      rpm -q "$package_name" >/dev/null 2>&1
      ;;
    pacman)
      pacman -Qi "$package_name" >/dev/null 2>&1
      ;;
    *)
      return 1
      ;;
  esac
}

autom8_apps_installed_package_list() {
  local package_name

  for package_name in "$@"; do
    if autom8_apps_package_installed "$package_name"; then
      printf '%s\n' "$package_name"
    fi
  done
}

autom8_apps_install_command_preview() {
  local packages=("$@")

  case "$AUTOM8_PACKAGE_MANAGER" in
    apt) printf 'sudo apt update && sudo apt install -y %s\n' "${packages[*]}" ;;
    dnf) printf 'sudo dnf install -y %s\n' "${packages[*]}" ;;
    zypper) printf 'sudo zypper install -y %s\n' "${packages[*]}" ;;
    pacman) printf 'sudo pacman -Sy --needed --noconfirm %s\n' "${packages[*]}" ;;
    *) printf 'Gerenciador não suportado\n' ;;
  esac
}

autom8_apps_install_packages() {
  local packages=("$@")

  case "$AUTOM8_PACKAGE_MANAGER" in
    apt)
      autom8_sudo "atualizar índice APT" apt update || return 1
      autom8_sudo "instalar apps via APT" apt install -y "${packages[@]}" || return 1
      ;;
    dnf)
      autom8_sudo "instalar apps via DNF" dnf install -y "${packages[@]}" || return 1
      ;;
    zypper)
      autom8_sudo "instalar apps via Zypper" zypper install -y "${packages[@]}" || return 1
      ;;
    pacman)
      autom8_sudo "instalar apps via Pacman" pacman -Sy --needed --noconfirm "${packages[@]}" || return 1
      ;;
    *)
      autom8_error_ui "Gerenciador de pacotes não suportado para apps: $AUTOM8_PACKAGE_MANAGER"
      return 1
      ;;
  esac
}

autom8_apps_remove_command_preview() {
  local packages=("$@")

  case "$AUTOM8_PACKAGE_MANAGER" in
    apt) printf 'sudo apt remove -y %s\n' "${packages[*]}" ;;
    dnf) printf 'sudo dnf remove -y %s\n' "${packages[*]}" ;;
    zypper) printf 'sudo zypper remove -y %s\n' "${packages[*]}" ;;
    pacman) printf 'sudo pacman -Rns --noconfirm %s\n' "${packages[*]}" ;;
    *) printf 'Gerenciador não suportado\n' ;;
  esac
}

autom8_apps_remove_packages() {
  local packages=("$@")

  case "$AUTOM8_PACKAGE_MANAGER" in
    apt)
      autom8_sudo "remover apps via APT" apt remove -y "${packages[@]}" || return 1
      ;;
    dnf)
      autom8_sudo "remover apps via DNF" dnf remove -y "${packages[@]}" || return 1
      ;;
    zypper)
      autom8_sudo "remover apps via Zypper" zypper remove -y "${packages[@]}" || return 1
      ;;
    pacman)
      autom8_sudo "remover apps via Pacman" pacman -Rns --noconfirm "${packages[@]}" || return 1
      ;;
    *)
      autom8_error_ui "Gerenciador de pacotes não suportado para remoção: $AUTOM8_PACKAGE_MANAGER"
      return 1
      ;;
  esac
}
