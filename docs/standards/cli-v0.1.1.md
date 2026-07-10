# AutoM8 CLI v0.1.1 — Padrão oficial

Este documento define o padrão oficial da CLI local do AutoM8 para a versão 0.1.1.

## Produto

- Produto principal: AutoM8 CLI local.
- Nome curto: AutoM8.
- Nome completo: AutoM8 · Linux Management Suite.
- Assinatura institucional: AutoM8 by OSLabs.
- Instalação padrão: /opt/autom8.
- Distribuição estável: GitHub Releases.
- Site oficial: https://autom8.oslabs.com.br.
- Repositório: mdmjunior/autom8.

## Objetivo da v0.1.1

A v0.1.1 é uma versão de base, visual e estabilidade.

Foco:

- visual terminal premium;
- estabilidade da CLI;
- instalador confiável;
- doctor mais forte;
- diagnose com modo privado;
- confirmação antes de ações reais;
- preparação para Apps v0.2.

Não faz parte da v0.1.1:

- implementar Apps;
- implementar Profiles;
- implementar Backup;
- migrar de Bash para outra linguagem;
- criar temas alternativos;
- aplicar self-update real com rollback;
- criar flag --yes.

## Stack da CLI

- Linguagem atual: Bash.
- Interface preferencial: gum.
- Fallback obrigatório: texto simples sem gum.
- A CLI deve continuar funcional mesmo sem gum.

## Identidade visual

A CLI deve seguir a identidade publicada do site:

- dark terminal premium;
- azul como cor principal;
- ciano para destaque;
- verde terminal para sucesso;
- amarelo para aviso;
- vermelho para erro;
- cinza para texto secundário.

Uso sugerido no gum:

- primary: 39;
- info: 45;
- success: 42;
- warning: 214;
- error: 196;
- muted: 244;
- text: 255.

## Comando padrão

O comando autom8 deve abrir Dashboard + Menu.

Experiência padrão:

1. cabeçalho AutoM8;
2. resumo do sistema;
3. permissões;
4. saúde rápida;
5. menu principal.

## Comandos diretos

Devem continuar funcionando:

    autom8 --version
    autom8 --help
    autom8 doctor
    autom8 diagnose
    autom8 diagnose --private
    autom8 update
    autom8 clean
    autom8 clean --dry-run
    autom8 security
    autom8 docker
    autom8 users
    autom8 config
    autom8 report
    autom8 self-update

## Regras de confirmação

Ações somente leitura não pedem confirmação.

Ações reais pedem confirmação:

- update real;
- clean real;
- instalação futura de apps;
- remoção futura de apps;
- alteração de usuários;
- alteração de segurança;
- self-update real futuro.

Não criar --yes na v0.1.1.

## Diagnose privado

O comando autom8 diagnose --private deve gerar relatório sanitizado.

Deve ocultar ou reduzir:

- hostname;
- nomes de usuários;
- caminhos de home;
- IPs;
- DNS;
- rotas;
- nomes de containers;
- processos sensíveis;
- dados que dificultem compartilhamento seguro.

## Doctor

O doctor deve verificar:

- estrutura da instalação;
- binário;
- configuração;
- dependências obrigatórias;
- dependências opcionais;
- PATH;
- sudo;
- distro suportada;
- origem GitHub Releases;
- versão online, sem bloquear em caso de falha.

## Apps v0.2

Apps será o próximo módulo forte após a v0.1.1.

Direção futura:

- catálogo local;
- atualização online quando houver mudanças no repo;
- instalação clara;
- revisão antes de executar;
- logs e resumo final.

## Apps v0.2

A arquitetura do módulo Apps deve seguir este padrão:

- catálogo fonte separado por categoria em suite/catalog/apps/;
- catálogo consolidado em suite/catalog/apps.json;
- geração do consolidado por scripts/build-apps-catalog.sh;
- CLI lendo o consolidado;
- status available para apps instaláveis pelos repositórios da distro;
- status advanced para apps que exigem repositório externo, Flatpak, AUR, multilib, non-free ou configuração especial;
- instalação e remoção sempre com confirmação explícita;
- suporte a --dry-run antes de qualquer ação real.

Categorias oficiais iniciais:

- desenvolvimento;
- produtividade;
- containers;
- sistema;
- rede;
- midia;
- design;
- games;
- escritorio;
- usuario-local.
