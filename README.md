# AutoM8

AutoM8 é uma ferramenta para gerar pacotes de pós-instalação Linux a partir de uma interface web.

O projeto permite selecionar distro, perfis, pacotes e ações de sistema para gerar um build executável, empacotado e pronto para download.

## Objetivo

Simplificar a preparação de ambientes Linux com builds reproduzíveis, organizados e administráveis por catálogo.

## O que o AutoM8 faz

- seleciona a distro alvo
- resolve perfis, pacotes e ações
- aceita inputs para ações de sistema
- gera script de instalação
- gera manifesto do build
- gera README do build
- empacota o resultado em ZIP
- calcula hash SHA-256
- registra builds gerados em histórico

## Funcionalidades atuais

### Geração de builds

- wizard de geração de build
- validação de hostname
- validação de timezone
- preview técnico da seleção
- geração de build persistida no banco
- geração de ZIP
- download do build

### Histórico

- listagem de builds gerados
- download de builds antigos
- ações no histórico
- reutilização de builds anteriores como base

### Catálogo

- suporte a distros
- suporte a perfis
- suporte a pacotes
- suporte a ações de sistema
- versionamento básico de catálogo
- sincronização/publicação de catálogo

### Administração

- painel admin base
- CRUD inicial de perfis
- CRUD inicial de pacotes

### Infraestrutura

- ambiente local para desenvolvimento
- ambiente dev em VPS com Docker
- ambiente prod em VPS com Docker
- Nginx como reverse proxy
- HTTPS em dev e prod
- CI/CD com GitHub Actions
- deploy automático via branch

## Fluxo de branches

- `develop`: integração e ambiente de desenvolvimento
- `main`: produção e releases

## Ambientes

- Produção: `autom8.oslabs.com.br`
- Desenvolvimento: `autom8-dev.oslabs.com.br`

## Stack

- Laravel
- Livewire
- Tailwind CSS
- Vite
- MariaDB
- Docker
- Nginx
- GitHub Actions

## Release atual

- `v1.0.0`

## Roadmap de curto prazo

- admin de ações de sistema
- vínculos entre perfis, pacotes e ações
- publicação visual de catálogo
- melhoria do wizard
- expansão da suíte de testes

## Licença

Uso interno e evolução contínua pela OSLabs.
