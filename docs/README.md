# Documentação do AutoM8

A documentação oficial é gerada a partir de uma fonte única:

```text
docs/source/autom8-docs.json
```

Esse arquivo alimenta:

- README.md
- site/src/data/docs.json
- site/src/data/modules.json
- site/src/data/roadmap.json
- site/src/data/changelog.json
- site/src/data/documentation.json
- suite/docs/help.txt
- suite/docs/help/<comando>.txt

Para sincronizar:

```bash
./scripts/sync-docs.sh
```
