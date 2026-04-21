#!/usr/bin/env bash
set -euo pipefail

########################################
# AutoM8 VPS Bootstrap
# Ubuntu 24.04 + Docker + Nginx host
########################################

### ===== VARIÁVEIS AJUSTÁVEIS =====
DEPLOY_USER="deploy"
DEPLOY_GROUP="www-data"

SSH_KEY_NAME="id_ed25519"
SSH_DIR="/home/${DEPLOY_USER}/.ssh"
SSH_PRIVATE_KEY="${SSH_DIR}/${SSH_KEY_NAME}"
SSH_PUBLIC_KEY="${SSH_PRIVATE_KEY}.pub"

REPO_URL="git@github.com:mdmjunior/autom8.git"
PROD_BRANCH="main"
DEV_BRANCH="develop"

BASE_DIR="/opt"
PROD_ROOT="${BASE_DIR}/autom8-prod"
DEV_ROOT="${BASE_DIR}/autom8-dev"

PROD_APP_DIR="${PROD_ROOT}/app"
DEV_APP_DIR="${DEV_ROOT}/app"

PROD_HOST="autom8.oslabs.com.br"
DEV_HOST="autom8-dev.oslabs.com.br"

DEV_BASIC_AUTH_USER="marcio"
DEV_BASIC_AUTH_PASS="sc4r4lh0"

NGINX_SITE_FILE="/etc/nginx/sites-available/autom8"
NGINX_HTPASSWD_FILE="/etc/nginx/.htpasswd-autom8-dev"

PROD_WEB_PORT="8081"
DEV_WEB_PORT="8082"

### ===== FUNÇÕES =====
log() {
  echo
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

require_root() {
  if [ "${EUID}" -ne 0 ]; then
    echo "Execute este script como root."
    exit 1
  fi
}

create_user_if_missing() {
  if id "${DEPLOY_USER}" >/dev/null 2>&1; then
    echo "Usuário ${DEPLOY_USER} já existe."
  else
    adduser --disabled-password --gecos "" "${DEPLOY_USER}"
    usermod -aG sudo "${DEPLOY_USER}"
  fi
}

install_base_packages() {
  apt update
  apt upgrade -y

  apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    unzip \
    wget \
    ufw \
    nginx \
    certbot \
    python3-certbot-nginx \
    apache2-utils
}

install_docker_official() {
  install -m 0755 -d /etc/apt/keyrings

  if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  fi

  chmod a+r /etc/apt/keyrings/docker.gpg

  cat >/etc/apt/sources.list.d/docker.list <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable
EOF

  apt update
  apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
}

configure_user_groups() {
  usermod -aG docker "${DEPLOY_USER}"
  usermod -aG "${DEPLOY_GROUP}" "${DEPLOY_USER}"
}

create_directories() {
  mkdir -p "${PROD_ROOT}"
  mkdir -p "${DEV_ROOT}"

  chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${PROD_ROOT}" "${DEV_ROOT}"
  chmod -R 775 "${PROD_ROOT}" "${DEV_ROOT}"
}

prepare_deploy_ssh_dir() {
  mkdir -p "${SSH_DIR}"
  chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${SSH_DIR}"
  chmod 700 "${SSH_DIR}"
}

generate_deploy_ssh_key_if_missing() {
  if [ -f "${SSH_PRIVATE_KEY}" ] && [ -f "${SSH_PUBLIC_KEY}" ]; then
    echo "Chave SSH do usuário ${DEPLOY_USER} já existe."
    return
  fi

  sudo -u "${DEPLOY_USER}" ssh-keygen -t ed25519 -C "${DEPLOY_USER}@$(hostname)-autom8" -f "${SSH_PRIVATE_KEY}" -N ""
  chown "${DEPLOY_USER}:${DEPLOY_USER}" "${SSH_PRIVATE_KEY}" "${SSH_PUBLIC_KEY}"
  chmod 600 "${SSH_PRIVATE_KEY}"
  chmod 644 "${SSH_PUBLIC_KEY}"
}

prepare_github_known_hosts() {
  sudo -u "${DEPLOY_USER}" bash -lc "touch '${SSH_DIR}/known_hosts' && ssh-keyscan -H github.com >> '${SSH_DIR}/known_hosts'"
  chown "${DEPLOY_USER}:${DEPLOY_USER}" "${SSH_DIR}/known_hosts"
  chmod 644 "${SSH_DIR}/known_hosts"
}

clone_or_update_repo() {
  local app_dir="$1"
  local branch="$2"

  if [ -d "${app_dir}/.git" ]; then
    echo "Repositório já existe em ${app_dir}. Atualizando..."
    sudo -u "${DEPLOY_USER}" bash -lc "cd '${app_dir}' && git fetch origin && git checkout '${branch}' && git pull origin '${branch}'"
  else
    mkdir -p "$(dirname "${app_dir}")"
    sudo -u "${DEPLOY_USER}" bash -lc "git clone '${REPO_URL}' '${app_dir}'"
    sudo -u "${DEPLOY_USER}" bash -lc "cd '${app_dir}' && git checkout '${branch}' || true"
  fi
}

prepare_app_tree() {
  local app_dir="$1"

  mkdir -p "${app_dir}/storage/app/autom8/builds"
  mkdir -p "${app_dir}/storage/app/autom8/artifacts"
  mkdir -p "${app_dir}/storage/logs"
  mkdir -p "${app_dir}/bootstrap/cache"

  chown -R "${DEPLOY_USER}:${DEPLOY_GROUP}" "${app_dir}"
  chmod -R 775 "${app_dir}/storage" "${app_dir}/bootstrap/cache" || true

  if [ ! -f "${app_dir}/storage/app/autom8/builds/.gitignore" ]; then
    printf "*\n!.gitignore\n" > "${app_dir}/storage/app/autom8/builds/.gitignore"
  fi

  if [ ! -f "${app_dir}/storage/app/autom8/artifacts/.gitignore" ]; then
    printf "*\n!.gitignore\n" > "${app_dir}/storage/app/autom8/artifacts/.gitignore"
  fi

  chown -R "${DEPLOY_USER}:${DEPLOY_GROUP}" "${app_dir}/storage" "${app_dir}/bootstrap/cache"
}

create_env_files_if_missing() {
  local app_dir="$1"
  local env_type="$2"

  if [ ! -f "${app_dir}/.env" ] && [ -f "${app_dir}/.env.docker.example" ]; then
    cp "${app_dir}/.env.docker.example" "${app_dir}/.env"
    chown "${DEPLOY_USER}:${DEPLOY_GROUP}" "${app_dir}/.env"

    if [ "${env_type}" = "prod" ]; then
      sed -i "s|^APP_ENV=.*|APP_ENV=production|" "${app_dir}/.env" || true
      sed -i "s|^APP_DEBUG=.*|APP_DEBUG=false|" "${app_dir}/.env" || true
      sed -i "s|^APP_URL=.*|APP_URL=https://${PROD_HOST}|" "${app_dir}/.env" || true
    else
      sed -i "s|^APP_ENV=.*|APP_ENV=staging|" "${app_dir}/.env" || true
      sed -i "s|^APP_DEBUG=.*|APP_DEBUG=true|" "${app_dir}/.env" || true
      sed -i "s|^APP_URL=.*|APP_URL=https://${DEV_HOST}|" "${app_dir}/.env" || true
    fi
  fi
}

configure_nginx() {
  cat > "${NGINX_SITE_FILE}" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${PROD_HOST};

    access_log /var/log/nginx/autom8_access.log;
    error_log /var/log/nginx/autom8_error.log;

    location / {
        proxy_pass http://127.0.0.1:${PROD_WEB_PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
    }
}

server {
    listen 80;
    listen [::]:80;
    server_name ${DEV_HOST};

    access_log /var/log/nginx/autom8_dev_access.log;
    error_log /var/log/nginx/autom8_dev_error.log;

    auth_basic "AutoM8 DEV";
    auth_basic_user_file ${NGINX_HTPASSWD_FILE};

    location / {
        proxy_pass http://127.0.0.1:${DEV_WEB_PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
    }
}
EOF

  ln -sf "${NGINX_SITE_FILE}" /etc/nginx/sites-enabled/autom8
  rm -f /etc/nginx/sites-enabled/default
}

create_dev_basic_auth() {
  printf "%s:%s\n" "${DEV_BASIC_AUTH_USER}" "$(openssl passwd -apr1 "${DEV_BASIC_AUTH_PASS}")" > "${NGINX_HTPASSWD_FILE}"
  chmod 640 "${NGINX_HTPASSWD_FILE}"
  chown root:"${DEPLOY_GROUP}" "${NGINX_HTPASSWD_FILE}" || true
}

configure_firewall() {
  ufw allow OpenSSH || true
  ufw allow 'Nginx Full' || true
  ufw --force enable || true
}

enable_services() {
  systemctl enable docker
  systemctl start docker
  systemctl enable nginx
  systemctl restart nginx
}

validate() {
  nginx -t
  docker --version
  docker compose version
  systemctl is-active nginx
  systemctl is-active docker
}

print_next_steps() {
  cat <<EOF

Bootstrap concluído.

Estrutura criada:
- ${PROD_APP_DIR}
- ${DEV_APP_DIR}

Nginx configurado para:
- ${PROD_HOST} -> 127.0.0.1:${PROD_WEB_PORT}
- ${DEV_HOST}  -> 127.0.0.1:${DEV_WEB_PORT} com Basic Auth

Usuário criado/ajustado:
- ${DEPLOY_USER}

Próximos passos:
1. Verifique/edite os arquivos .env:
   - ${PROD_APP_DIR}/.env
   - ${DEV_APP_DIR}/.env

2. Suba os containers:
   Produção:
   cd ${PROD_APP_DIR}
   docker compose -f docker-compose.prod.yml up -d --build

   Desenvolvimento:
   cd ${DEV_APP_DIR}
   docker compose -f docker-compose.dev.yml up -d --build

3. Gere APP_KEY e rode migrations:
   Produção:
   docker compose -f docker-compose.prod.yml exec app php artisan key:generate
   docker compose -f docker-compose.prod.yml exec app php artisan migrate --force
   docker compose -f docker-compose.prod.yml exec app php artisan autom8:sync-catalog --publish-version=0.1.0

   Desenvolvimento:
   docker compose -f docker-compose.dev.yml exec app php artisan key:generate
   docker compose -f docker-compose.dev.yml exec app php artisan migrate --force
   docker compose -f docker-compose.dev.yml exec app php artisan autom8:sync-catalog --publish-version=0.1.0-dev

4. Quando os DNS estiverem apontando, emitir SSL:
   sudo certbot --nginx -d ${PROD_HOST} -d ${DEV_HOST}
   sudo certbot renew --dry-run

5. Troque a senha DEV no script/arquivo se ainda estiver usando valor temporário.
EOF
}

print_deploy_pubkey() {
  echo
  echo "============================================================"
  echo "CHAVE PÚBLICA SSH DO USUÁRIO ${DEPLOY_USER}"
  echo "Cadastre esta chave em GitHub > Repo > Settings > Deploy keys"
  echo "============================================================"
  cat "${SSH_PUBLIC_KEY}"
  echo
}

### ===== EXECUÇÃO =====
require_root

log "1/10 - Instalando pacotes base"
install_base_packages

log "2/10 - Instalando Docker oficial"
install_docker_official

log "3/10 - Criando usuário e grupos"
create_user_if_missing
configure_user_groups

log "4/10 - Criando estrutura de diretórios"
create_directories

log "4/11 - Preparando SSH do usuário deploy"
prepare_deploy_ssh_dir
generate_deploy_ssh_key_if_missing
prepare_github_known_hosts

log "5/10 - Clonando/atualizando repositório de produção"
clone_or_update_repo "${PROD_APP_DIR}" "${PROD_BRANCH}"

log "6/10 - Clonando/atualizando repositório de desenvolvimento"
clone_or_update_repo "${DEV_APP_DIR}" "${DEV_BRANCH}"

log "7/10 - Preparando árvores da aplicação"
prepare_app_tree "${PROD_APP_DIR}"
prepare_app_tree "${DEV_APP_DIR}"
create_env_files_if_missing "${PROD_APP_DIR}" "prod"
create_env_files_if_missing "${DEV_APP_DIR}" "dev"

log "8/10 - Configurando Basic Auth do DEV"
create_dev_basic_auth

log "9/10 - Configurando Nginx e firewall"
configure_nginx
configure_firewall

log "10/10 - Habilitando serviços e validando"
enable_services
validate

print_next_steps
print_deploy_pubkey