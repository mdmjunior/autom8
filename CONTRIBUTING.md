# Contribuindo com o AutoM8

O desenvolvimento contínuo acontece em `develop`. A branch `main` representa
o estado promovido e deve receber mudanças somente por pull request.

## Fluxo

```bash
git checkout develop
git pull --ff-only origin develop
./scripts/sync-docs.sh
./scripts/check.sh all
```

Depois da validação, faça commit e push para `develop`. A promoção para
`main` deve ocorrer com o Quality Gate aprovado.

## Regras

- Preserve a compatibilidade da CLI e a versão estável, salvo mudança planejada.
- Atualize `docs/source/autom8-docs.json` quando comandos ou status mudarem.
- Execute `./scripts/sync-docs.sh` antes de versionar documentação.
- Não edite apenas arquivos gerados.
- Não inclua credenciais, logs sensíveis ou artefatos de runtime.
