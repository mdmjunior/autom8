#!/usr/bin/env bash
set -euo pipefail

echo "[1/8] Atualizando sistema..."
apt update && apt upgrade -y

echo "[2/8] Instalando pacotes base..."
apt install -y ca-certificates curl gnupg lsb-release git unzip nginx certbot python3-certbot-nginx apache2-utils

echo "[3/8] Instalando Docker..."
install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
fi
chmod a+r /etc/apt/keyrings/docker.gpg

cat >/etc/apt/sources.list.d/docker.list <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable
EOF

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "[4/8] Habilitando serviços..."
systemctl enable docker
systemctl start docker
systemctl enable nginx
systemctl start nginx

echo "[5/8] Criando diretórios..."
mkdir -p /opt/autom8-prod
mkdir -p /opt/autom8-dev

echo "[6/8] Ajustando ownership..."
if id deploy >/dev/null 2>&1; then
  chown -R deploy:deploy /opt/autom8-prod /opt/autom8-dev
fi

echo "[7/8] Criando arquivo de senha para DEV, se não existir..."
if [ ! -f /etc/nginx/.htpasswd-autom8-dev ]; then
  echo "Crie a senha do ambiente DEV com:"
  echo "htpasswd -c /etc/nginx/.htpasswd-autom8-dev marcio"
fi

echo "[8/8] Finalizado."
docker --version
docker compose version
nginx -v