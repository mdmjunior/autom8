# Documentação do AutoM8

Este diretório reúne a documentação técnica e operacional do projeto.

## Para usuários

- [Guia rápido](https://autom8.oslabs.com.br/docs)
- [README do projeto](../README.md)
- Ajuda local: `autom8 help` e `autom8 help <comando>`

## Para manutenção

- [Arquitetura](ARCHITECTURE.md)
- [Releases](RELEASES.md)
- [Variáveis](VARIABLES.md)
- [Contribuição](../CONTRIBUTING.md)
- [Segurança](../SECURITY.md)

## Fonte única

`docs/source/autom8-docs.json` alimenta o README, os dados do site e a ajuda da CLI.

Para sincronizar e validar:

```bash
./scripts/sync-docs.sh
./scripts/check.sh all
```

Não edite arquivos gerados sem atualizar a fonte ou o gerador.
