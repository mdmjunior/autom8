#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${AUTOM8_APP_DIR:-/opt/oslabs/repos/autom8}"
STACK_FILE="${AUTOM8_STACK_FILE:-$APP_DIR/infra/docker-stack.yml}"
STACK_NAME="${AUTOM8_STACK_NAME:-autom8}"
IMAGE_NAME="${AUTOM8_SITE_IMAGE:-autom8-site:latest}"
DOMAIN="${AUTOM8_DOMAIN:-https://autom8.oslabs.com.br}"
SERVICE_NAME="${AUTOM8_SERVICE_NAME:-autom8_autom8_site}"

log() {
  printf '\033[1;34m[AutoM8 Infra Deploy]\033[0m %s\n' "$1"
}

warn() {
  printf '\033[1;33m[AutoM8 Infra Deploy]\033[0m %s\n' "$1"
}

error() {
  printf '\033[1;31m[AutoM8 Infra Deploy]\033[0m %s\n' "$1" >&2
}

if [[ ! -d "$APP_DIR/.git" ]]; then
  error "Diretório do projeto não encontrado ou não é repo Git: $APP_DIR"
  exit 1
fi

if [[ ! -f "$STACK_FILE" ]]; then
  error "Stack file não encontrado: $STACK_FILE"
  exit 1
fi

cd "$APP_DIR"

cleanup_generated_files() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if [[ -n "$(git status --porcelain -- site/public/install.sh 2>/dev/null)" ]]; then
      warn "Restaurando site/public/install.sh para não deixar o repo sujo."
      git restore site/public/install.sh || true
    fi
  fi
}

trap cleanup_generated_files EXIT

log "Projeto: $APP_DIR"
log "Stack: $STACK_NAME"
log "Stack file: $STACK_FILE"
log "Imagem: $IMAGE_NAME"
log "Serviço: $SERVICE_NAME"

log "Validando rede externa declarada na stack sem alterá-la."

STACK_NETWORKS="$(
  awk '
    /^networks:/ { in_networks=1; next }
    in_networks && /^[^[:space:]]/ { in_networks=0 }
    in_networks && /^  [A-Za-z0-9_.-]+:/ {
      gsub(":", "", $1)
      print $1
    }
  ' "$STACK_FILE" | sort -u
)"

for network_name in $STACK_NETWORKS; do
  if grep -A4 -E "^  ${network_name}:" "$STACK_FILE" | grep -q "external: true"; then
    if ! docker network inspect "$network_name" >/dev/null 2>&1; then
      error "Rede externa declarada não existe no Docker: $network_name"
      error "Não vou criar, renomear ou trocar rede automaticamente."
      exit 1
    fi
    log "Rede externa OK: $network_name"
  fi
done

log "Removendo resíduos locais de pacote/site."
rm -rf "$APP_DIR/site/public/downloads"
rm -rf "$APP_DIR/site/dist"

log "Sincronizando documentação."
./scripts/sync-docs.sh

log "Sincronizando install.sh público para o contexto do build."
cp installer/install.sh site/public/install.sh
chmod +x site/public/install.sh

log "Construindo imagem Docker local."
docker build -t "$IMAGE_NAME" ./site

log "Validando imagem local."
docker image inspect "$IMAGE_NAME" >/dev/null

log "Publicando stack no Docker Swarm."
docker stack deploy -c "$STACK_FILE" "$STACK_NAME" --detach=false

log "Aguardando serviço estabilizar."
sleep 5

docker stack services "$STACK_NAME"
docker service ps "$SERVICE_NAME" --no-trunc | head -20

REPLICAS="$(docker service ls --filter "name=$SERVICE_NAME" --format '{{.Replicas}}' | head -1)"

if [[ "$REPLICAS" != "1/1" ]]; then
  error "Serviço não ficou saudável. Réplicas atuais: ${REPLICAS:-indisponível}"
  docker service ps "$SERVICE_NAME" --no-trunc | head -30
  exit 1
fi

log "Validando domínio."
curl -I "$DOMAIN" || true
curl -I "$DOMAIN/install.sh" || true

log "Deploy finalizado com sucesso."
