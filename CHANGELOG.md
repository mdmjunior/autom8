# Changelog

## v1.0.0

### Added

- lançamento funcional inicial do AutoM8
- wizard para geração de builds
- seleção de distro, perfis, pacotes e ações
- suporte a inputs para ações de sistema
- validação de hostname
- validação de timezone
- preview técnico da seleção
- geração de manifesto
- geração de script de instalação
- geração de README do build
- empacotamento em ZIP
- cálculo de hash SHA-256
- persistência de builds gerados
- histórico de builds
- download de builds gerados
- reutilização de builds anteriores como base
- ações iniciais no histórico
- limpeza de builds e artefatos antigos
- logs básicos de operação

### Catalog

- estrutura de catálogo para distros, perfis, pacotes e ações
- suporte a versionamento de catálogo
- sincronização/publicação básica de catálogo

### Admin

- painel admin base
- CRUD inicial de perfis
- CRUD inicial de pacotes

### Infra

- ambiente local de desenvolvimento
- ambiente dev em VPS com Docker
- ambiente prod em VPS com Docker
- reverse proxy com Nginx
- HTTPS em desenvolvimento e produção
- proteção por autenticação no ambiente dev
- scripts operacionais de deploy
- isolamento entre ambientes dev e prod

### CI/CD

- pipeline de testes com GitHub Actions
- deploy automático no ambiente dev via `develop`
- deploy automático no ambiente prod via `main`

### Tests

- testes do resolver
- testes do gerador de build
- testes de download
- testes de prune
- testes de validação do wizard
- ajustes da suíte para o schema atual do projeto

### Notes

- esta release representa a primeira versão operacional do AutoM8
- foco da versão: geração de builds, histórico, base de catálogo e fundação operacional
