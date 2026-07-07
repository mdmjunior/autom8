# Releases do AutoM8

Pacotes estáveis devem ser publicados somente no GitHub Releases.

## Política

- Fonte estável: GitHub Releases
- Pacote latest: `https://github.com/mdmjunior/autom8/releases/latest/download/autom8-latest.tar.gz`
- Padrão versionado: `https://github.com/mdmjunior/autom8/releases/download/v{version}/autom8-{version}.tar.gz`

A VPS e o ambiente local de desenvolvimento não devem manter pacotes publicados da suíte.

## Publicar release

A partir da branch `main` limpa:

```bash
./scripts/release-stable.sh
```

O script gera pacotes temporários, cria ou atualiza a release e remove os artefatos temporários ao final.
