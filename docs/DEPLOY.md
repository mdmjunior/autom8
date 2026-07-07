# Deploy do site AutoM8

Este documento descreve o deploy real do site do AutoM8 na VPS compartilhada da OSLabs.

## Regra principal

O site é publicado como uma stack Docker Swarm chamada `autom8`.

O serviço principal é:

    autom8_autom8_site

A imagem local usada pela stack é:

    autom8-site:latest

## O que o deploy faz

O deploy oficial:

- atualiza o repositório na VPS;
- sincroniza a documentação;
- copia `installer/install.sh` para o contexto público do site durante o build;
- remove resíduos de `site/public/downloads`;
- remove resíduos de `site/dist`;
- constrói a imagem local `autom8-site:latest`;
- publica a stack com `docker stack deploy`;
- valida o serviço e o domínio.

## O que o deploy não faz

O deploy não deve:

- gerar pacote da suíte para a VPS;
- publicar `autom8-latest.tar.gz` no site;
- alterar redes Docker;
- alterar labels do Traefik;
- usar `docker service update --force` isolado;
- depender de `npm` instalado no host.

## Pacotes da suíte

Pacotes estáveis da suíte são publicados somente no GitHub Releases.

O instalador público baixa:

    https://github.com/mdmjunior/autom8/releases/latest/download/autom8-latest.tar.gz

## Deploy

Na VPS:

    cd /opt/oslabs/repos/autom8
    ./scripts/deploy-site-vps.sh

## Validação

Após o deploy:

    docker stack services autom8
    docker service ps autom8_autom8_site --no-trunc
    curl -I https://autom8.oslabs.com.br
    curl -I https://autom8.oslabs.com.br/install.sh

## Rede Docker

A rede declarada em `infra/docker-stack.yml` é considerada fonte da verdade.

O script valida se a rede externa existe, mas não cria, renomeia nem substitui redes.
