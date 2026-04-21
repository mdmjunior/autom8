# Changelog

## v1.0.0

### Added

- lançamento inicial do AutoM8
- suporte a geração de builds para Ubuntu e Fedora
- seleção por perfis e por pacotes individuais
- ações de sistema integradas ao build
- wizard completo de geração
- preview antes da criação do build
- geração de ZIP com manifesto e hash SHA-256
- histórico de builds com busca e filtros
- reutilização de build anterior como base
- exclusão de builds
- logs básicos do pipeline
- limpeza de builds antigos e órfãos
- testes automatizados do fluxo principal

### Infrastructure

- estrutura preparada para ambientes separados de desenvolvimento e produção
- deploy em Docker na VPS
- reverse proxy com Nginx
- suporte a HTTPS
- ambiente dev protegido por autenticação

### Notes

- esta versão marca a primeira release funcional do AutoM8
- foco em geração de builds, operação estável e base para evolução futura
