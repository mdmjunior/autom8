#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${AUTOM8_APP_DIR:-/opt/oslabs/repos/autom8}"
STACK_FILE="${AUTOM8_STACK_FILE:-$APP_DIR/infra/docker-stack.yml}"
STACK_NAME="${AUTOM8_STACK_NAME:-autom8}"
IMAGE_REPOSITORY="${AUTOM8_SITE_IMAGE_REPOSITORY:-autom8-site}"
DOMAIN="${AUTOM8_DOMAIN:-https://autom8.oslabs.com.br}"
SERVICE_NAME="${AUTOM8_SERVICE_NAME:-autom8_autom8_site}"
REPLICAS="${AUTOM8_REPLICAS:-1}"
DEPLOY_TIMEOUT="${AUTOM8_DEPLOY_TIMEOUT:-180}"

TEST_CONTAINER=""
PREVIOUS_IMAGE=""
IMAGE_NAME=""

log() {
  printf '\033[1;34m[AutoM8 Infra Deploy]\033[0m %s\n' "$1"
}

warn() {
  printf '\033[1;33m[AutoM8 Infra Deploy]\033[0m %s\n' "$1"
}

error() {
  printf '\033[1;31m[AutoM8 Infra Deploy]\033[0m %s\n' "$1" >&2
}

cleanup() {
  if [[ -n "$TEST_CONTAINER" ]]; then
    docker rm --force "$TEST_CONTAINER" \
      >/dev/null 2>&1 || true
  fi

  if ! git rev-parse --is-inside-work-tree \
    >/dev/null 2>&1
  then
    return
  fi

  if [[ -z "$(
    git status --porcelain -- \
      site/public/install.sh 2>/dev/null
  )" ]]; then
    return
  fi

  warn "Restaurando site/public/install.sh."

  if git ls-files --error-unmatch \
    site/public/install.sh \
    >/dev/null 2>&1
  then
    git restore site/public/install.sh || true
  else
    rm -f site/public/install.sh
  fi
}

trap cleanup EXIT

if [[ ! "$REPLICAS" =~ ^[1-9][0-9]*$ ]]; then
  error "AUTOM8_REPLICAS deve ser um inteiro maior que zero."
  exit 1
fi

if [[ ! "$DEPLOY_TIMEOUT" =~ ^[1-9][0-9]*$ ]]; then
  error "AUTOM8_DEPLOY_TIMEOUT deve ser um inteiro maior que zero."
  exit 1
fi

if [[ ! -d "$APP_DIR/.git" ]]; then
  error "Diretório do projeto não encontrado ou não é repo Git: $APP_DIR"
  exit 1
fi

if [[ ! -f "$STACK_FILE" ]]; then
  error "Stack file não encontrado: $STACK_FILE"
  exit 1
fi

cd "$APP_DIR"

DOMAIN="${DOMAIN%/}"

AUTOM8_VERSION="$(
  tr -d '[:space:]' \
    < suite/VERSION
)"

AUTOM8_REVISION="$(
  git rev-parse --short=12 HEAD
)"

AUTOM8_BUILD_DATE="$(
  date -u '+%Y-%m-%dT%H:%M:%SZ'
)"

IMAGE_NAME="${AUTOM8_SITE_IMAGE:-${IMAGE_REPOSITORY}:${AUTOM8_VERSION}-${AUTOM8_REVISION}}"

log "Projeto: $APP_DIR"
log "Stack: $STACK_NAME"
log "Stack file: $STACK_FILE"
log "Versão: $AUTOM8_VERSION"
log "Revisão: $AUTOM8_REVISION"
log "Imagem imutável: $IMAGE_NAME"
log "Serviço: $SERVICE_NAME"
log "Réplicas esperadas: $REPLICAS"

validate_external_networks() {
  local stack_networks
  local network_name

  stack_networks="$(
    awk '
      /^networks:/ {
        in_networks=1
        next
      }

      in_networks && /^[^[:space:]]/ {
        in_networks=0
      }

      in_networks && /^  [A-Za-z0-9_.-]+:/ {
        gsub(":", "", $1)
        print $1
      }
    ' "$STACK_FILE" |
      sort -u
  )"

  for network_name in $stack_networks; do
    if ! grep -A4 -E \
      "^  ${network_name}:" \
      "$STACK_FILE" |
      grep -q "external: true"
    then
      continue
    fi

    if ! docker network inspect \
      "$network_name" \
      >/dev/null 2>&1
    then
      error "Rede externa declarada não existe: $network_name"
      error "A rede não será criada ou substituída automaticamente."
      return 1
    fi

    log "Rede externa OK: $network_name"
  done
}

wait_for_image_container() {
  local port="$1"
  local attempt
  local health=""

  attempt=1

  while (( attempt <= 30 )); do
    health="$(
      curl \
        --fail \
        --silent \
        --show-error \
        --connect-timeout 2 \
        --max-time 5 \
        "http://127.0.0.1:${port}/healthz" \
        2>/dev/null || true
    )"

    if [[ "$health" == "ok" ]]; then
      return 0
    fi

    sleep 1
    attempt=$((attempt + 1))
  done

  return 1
}

test_local_image() {
  local container_port
  local homepage
  local installer_script

  TEST_CONTAINER="autom8-site-image-test-${$}-${RANDOM}"

  log "Iniciando validação isolada da imagem."

  docker run \
    --detach \
    --name "$TEST_CONTAINER" \
    --publish 127.0.0.1::80 \
    "$IMAGE_NAME" \
    >/dev/null

  container_port="$(
    docker port \
      "$TEST_CONTAINER" \
      80/tcp |
      head -n 1 |
      awk -F: '{print $NF}'
  )"

  if [[ -z "$container_port" ]]; then
    error "Não foi possível determinar a porta do container de teste."
    docker logs "$TEST_CONTAINER" >&2 || true
    return 1
  fi

  if ! wait_for_image_container "$container_port"; then
    error "A imagem não ficou saudável dentro do prazo."
    docker logs "$TEST_CONTAINER" >&2 || true
    return 1
  fi

  homepage="$(
    curl \
      --fail \
      --silent \
      --show-error \
      "http://127.0.0.1:${container_port}/"
  )"

  if ! grep -qi '<html' <<< "$homepage"; then
    error "A página inicial retornada não contém HTML."
    return 1
  fi

  installer_script="$(
    curl \
      --fail \
      --silent \
      --show-error \
      "http://127.0.0.1:${container_port}/install.sh"
  )"

  if ! grep -q \
    'autom8-latest.tar.gz' \
    <<< "$installer_script"
  then
    error "O instalador público não contém a referência esperada."
    return 1
  fi

  docker rm --force "$TEST_CONTAINER" \
    >/dev/null

  TEST_CONTAINER=""

  log "Imagem validada: página, healthcheck e instalador OK."
}

service_image() {
  docker service inspect \
    "$SERVICE_NAME" \
    --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' \
    2>/dev/null || true
}

wait_for_service() {
  local attempts
  local attempt
  local replicas
  local update_state
  local container_ids
  local container_id
  local health
  local all_healthy

  attempts=$((DEPLOY_TIMEOUT / 2))

  if (( attempts < 1 )); then
    attempts=1
  fi

  attempt=1

  while (( attempt <= attempts )); do
    if ! docker service inspect \
      "$SERVICE_NAME" \
      >/dev/null 2>&1
    then
      sleep 2
      attempt=$((attempt + 1))
      continue
    fi

    replicas="$(
      docker service ls \
        --filter "name=$SERVICE_NAME" \
        --format '{{.Replicas}}' |
        head -n 1
    )"

    update_state="$(
      docker service inspect \
        "$SERVICE_NAME" \
        --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{else}}none{{end}}'
    )"

    if [[ "$update_state" == "paused" ]]; then
      error "Atualização do serviço foi pausada pelo Swarm."
      return 1
    fi

    if [[ "$replicas" != "${REPLICAS}/${REPLICAS}" ]]; then
      sleep 2
      attempt=$((attempt + 1))
      continue
    fi

    mapfile -t container_ids < <(
      docker ps \
        --filter "label=com.docker.swarm.service.name=$SERVICE_NAME" \
        --format '{{.ID}}'
    )

    if (( ${#container_ids[@]} == 0 )); then
      sleep 2
      attempt=$((attempt + 1))
      continue
    fi

    all_healthy=true

    for container_id in "${container_ids[@]}"; do
      health="$(
        docker inspect \
          --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' \
          "$container_id"
      )"

      if [[ "$health" != "healthy" &&
            "$health" != "none" ]]; then
        all_healthy=false
        break
      fi
    done

    if [[ "$all_healthy" == true ]]; then
      return 0
    fi

    sleep 2
    attempt=$((attempt + 1))
  done

  return 1
}

deploy_stack_with_image() {
  local image="$1"

  AUTOM8_SITE_IMAGE="$image" \
  AUTOM8_REPLICAS="$REPLICAS" \
    docker stack deploy \
      --compose-file "$STACK_FILE" \
      --resolve-image never \
      --detach=false \
      "$STACK_NAME"
}

rollback_stack() {
  if [[ -z "$PREVIOUS_IMAGE" ]]; then
    warn "Não existe imagem anterior para rollback automático."
    return 1
  fi

  warn "Restaurando imagem anterior: $PREVIOUS_IMAGE"

  if ! deploy_stack_with_image "$PREVIOUS_IMAGE"; then
    error "Não foi possível reaplicar a imagem anterior."
    return 1
  fi

  if ! wait_for_service; then
    error "O serviço anterior não estabilizou após o rollback."
    return 1
  fi

  log "Rollback concluído."
}

wait_for_public_domain() {
  local attempts
  local attempt
  local health

  attempts=$((DEPLOY_TIMEOUT / 2))

  if (( attempts < 1 )); then
    attempts=1
  fi

  attempt=1

  while (( attempt <= attempts )); do
    health="$(
      curl \
        --fail \
        --silent \
        --show-error \
        --location \
        --connect-timeout 5 \
        --max-time 15 \
        "${DOMAIN}/healthz" \
        2>/dev/null || true
    )"

    if [[ "$health" == "ok" ]]; then
      curl \
        --fail \
        --silent \
        --show-error \
        --head \
        --connect-timeout 5 \
        --max-time 15 \
        "$DOMAIN" \
        >/dev/null

      curl \
        --fail \
        --silent \
        --show-error \
        --head \
        --connect-timeout 5 \
        --max-time 15 \
        "${DOMAIN}/install.sh" \
        >/dev/null

      return 0
    fi

    sleep 2
    attempt=$((attempt + 1))
  done

  return 1
}

validate_external_networks

log "Removendo resíduos locais de site e pacotes."
rm -rf "$APP_DIR/site/public/downloads"
rm -rf "$APP_DIR/site/dist"

log "Sincronizando documentação."
./scripts/sync-docs.sh

generated_paths=(
  docs
  suite/docs
  site/src/data
)

if ! git diff --quiet -- "${generated_paths[@]}"; then
  error "A sincronização gerou alterações não commitadas."
  error "Atualize e versione os documentos antes do deploy."

  git diff --stat -- "${generated_paths[@]}" >&2
  exit 1
fi

log "Sincronizando install.sh público como arquivo estático."
install -m 0644 \
  installer/install.sh \
  site/public/install.sh

PREVIOUS_IMAGE="$(service_image)"

if [[ -n "$PREVIOUS_IMAGE" ]]; then
  log "Imagem atualmente publicada: $PREVIOUS_IMAGE"
else
  log "O serviço ainda não possui uma imagem publicada."
fi

log "Construindo imagem Docker imutável."

docker build \
  --pull \
  --build-arg "AUTOM8_VERSION=$AUTOM8_VERSION" \
  --build-arg "AUTOM8_REVISION=$AUTOM8_REVISION" \
  --build-arg "AUTOM8_BUILD_DATE=$AUTOM8_BUILD_DATE" \
  --tag "$IMAGE_NAME" \
  ./site

docker image inspect \
  "$IMAGE_NAME" \
  >/dev/null

test_local_image

log "Publicando stack no Docker Swarm."

if ! deploy_stack_with_image "$IMAGE_NAME"; then
  error "docker stack deploy falhou."

  rollback_stack || true
  exit 1
fi

log "Aguardando serviço e healthcheck estabilizarem."

if ! wait_for_service; then
  error "O serviço não ficou saudável dentro de ${DEPLOY_TIMEOUT}s."

  docker stack services "$STACK_NAME" >&2 || true
  docker service ps "$SERVICE_NAME" --no-trunc >&2 || true

  rollback_stack || true
  exit 1
fi

DEPLOYED_IMAGE="$(service_image)"

if [[ "$DEPLOYED_IMAGE" != "$IMAGE_NAME" ]]; then
  error "A imagem efetivamente publicada não corresponde à esperada."
  error "Esperada: $IMAGE_NAME"
  error "Publicada: ${DEPLOYED_IMAGE:-indisponível}"

  rollback_stack || true
  exit 1
fi

log "Validando domínio público e Traefik."

if ! wait_for_public_domain; then
  error "O domínio não ficou saudável dentro de ${DEPLOY_TIMEOUT}s."

  docker stack services "$STACK_NAME" >&2 || true
  docker service ps "$SERVICE_NAME" --no-trunc >&2 || true

  rollback_stack || true
  exit 1
fi

docker stack services "$STACK_NAME"
docker service ps "$SERVICE_NAME" --no-trunc | head -20

log "Deploy finalizado com sucesso."
log "Imagem publicada: $IMAGE_NAME"
log "Domínio saudável: $DOMAIN"
