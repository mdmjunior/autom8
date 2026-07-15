# Deploy do site AutoM8

Este documento descreve o deploy do site na VPS compartilhada da OSLabs.

## Arquitetura

- Docker Swarm com a stack `autom8`.
- Serviço `autom8_autom8_site`.
- Proxy reverso Traefik pela rede externa `oslabs-public`.
- TLS automático pelo resolver `letsencrypt`.
- Imagem construída localmente na VPS, sem dependência de Node.js no host.

## Imagens imutáveis

Cada deploy cria uma tag formada pela versão e pela revisão Git:

    autom8-site:<versão>-<commit>

Exemplo:

    autom8-site:0.2.0-a1b2c3d4e5f6

A stack recebe a imagem por `AUTOM8_SITE_IMAGE`. O deploy usa `--resolve-image never`, pois a imagem é construída no próprio nó Swarm.

## Processo

O deploy:

1. exige o repositório limpo;
2. atualiza a branch apenas por fast-forward;
3. valida a rede externa;
4. sincroniza a documentação;
5. rejeita documentação gerada e não versionada;
6. copia o instalador para o contexto público;
7. constrói uma imagem imutável;
8. testa página inicial, `/healthz` e `install.sh` em container isolado;
9. publica a stack;
10. aguarda as réplicas e o healthcheck;
11. valida o domínio através do Traefik;
12. restaura a imagem anterior se a publicação falhar.

## Publicação

Na VPS:

    cd /opt/oslabs/repos/autom8
    ./scripts/deploy-site-vps.sh

A branch padrão é `main`. Para selecionar outra branch:

    AUTOM8_BRANCH=develop ./scripts/deploy-site-vps.sh

## Variáveis operacionais

- `AUTOM8_REPO_DIR`: repositório usado pelo script externo.
- `AUTOM8_BRANCH`: branch publicada pela VPS.
- `AUTOM8_APP_DIR`: diretório do projeto usado pelo deploy interno.
- `AUTOM8_STACK_FILE`: arquivo da stack.
- `AUTOM8_STACK_NAME`: nome da stack.
- `AUTOM8_SERVICE_NAME`: nome completo do serviço Swarm.
- `AUTOM8_SITE_IMAGE_REPOSITORY`: nome-base da imagem local.
- `AUTOM8_SITE_IMAGE`: imagem completa, quando definida manualmente.
- `AUTOM8_REPLICAS`: quantidade esperada de réplicas.
- `AUTOM8_DEPLOY_TIMEOUT`: prazo de estabilização em segundos.
- `AUTOM8_DOMAIN`: domínio público validado após o deploy.

## Validação

    docker stack services autom8
    docker service ps autom8_autom8_site --no-trunc
    docker service inspect autom8_autom8_site --pretty
    curl -fsS https://autom8.oslabs.com.br/healthz
    curl -I https://autom8.oslabs.com.br
    curl -I https://autom8.oslabs.com.br/install.sh

O endpoint de saúde deve retornar:

    ok

## Rollback

O Stack possui `failure_action: rollback`. O script também reaplica a imagem anterior usando o próprio arquivo da stack caso o serviço ou o domínio não estabilizem.

Para uma recuperação manual, identifique uma imagem anterior:

    docker image ls autom8-site

Depois reaplique a stack:

    AUTOM8_SITE_IMAGE=autom8-site:<tag-anterior> \
      docker stack deploy \
        --compose-file infra/docker-stack.yml \
        --resolve-image never \
        autom8

## Regras de segurança

- A rede externa não é criada nem renomeada pelo deploy.
- O deploy não utiliza `docker service update --force` isoladamente.
- O deploy não publica pacotes da suíte no site.
- Pacotes estáveis continuam sendo distribuídos pelo GitHub Releases.
- O host não precisa ter Node.js ou npm instalados.
