# AutoM8

AutoM8 é uma ferramenta de pós-instalação para Linux, criada para simplificar a preparação de ambientes em **Ubuntu** e **Fedora**.

A proposta é simples: o usuário acessa a interface web, escolhe **perfis**, **pacotes** e **ações de sistema**, e o AutoM8 gera um pacote com scripts Bash prontos para execução.

## O que a ferramenta faz

O AutoM8 permite:

- selecionar a distribuição-alvo
- escolher perfis prontos, como:
  - Developer
  - Gamer
  - Designer
- combinar pacotes manualmente
- aplicar ações de sistema, como:
  - atualização do sistema
  - alteração de hostname
  - alteração de timezone
- gerar um build com:
  - scripts de instalação
  - manifesto
  - README
  - arquivo ZIP para download

## Principais recursos atuais

- wizard de geração de build
- catálogo versionado de distros, perfis, pacotes e ações
- preview técnico antes da geração
- geração de ZIP com hash SHA-256
- histórico de builds
- download direto dos builds
- reutilização de builds anteriores como base
- exclusão de builds
- logs e limpeza de artefatos antigos

## Ambientes

- **Produção**: `autom8.oslabs.com.br`
- **Desenvolvimento**: `autom8-dev.oslabs.com.br`

## Stack

- Laravel
- Livewire
- Tailwind CSS
- Vite
- MariaDB
- Docker
- Nginx

## Fluxo de branches

- `develop`: integração e ambiente de desenvolvimento
- `main`: releases e produção

## Release atual

- `v1.0.0`

## Licença

Uso interno e evolução contínua sob a iniciativa da OSLabs.
