# AutoM8 0.3 — fundação Rust

Este diretório contém a nova fundação do AutoM8, ainda em desenvolvimento na
versão `0.3.0-alpha.1`.

O workspace possui três pacotes:

- `autom8-core`: contratos e metadados compartilhados;
- `autom8-cli`: interface rápida para terminal;
- `autom8-gnome`: aplicação nativa GTK 4/libadwaita.

A CLI implementa banner, `--help`, `--version` e o primeiro comando funcional:

```bash
autom8 status
autom8 status --json
```

A aplicação GNOME permanece como janela inicial, sem operações no sistema.

## Metadados estáveis preservados

`VERSION`, `catalog/` e `docs/` continuam descrevendo a versão estável `0.2.0`
durante a migração. Eles são preservados temporariamente para não modificar o
site, o instalador público ou a documentação estável nesta etapa. O novo código
Rust não consome esses arquivos.

## Desenvolvimento

No Fedora Workstation:

```bash
sudo dnf install rust cargo gcc pkgconf-pkg-config gtk4-devel libadwaita-devel
cd suite
cargo generate-lockfile
cargo fmt --all -- --check
cargo clippy --workspace --all-targets --locked -- -D warnings
cargo test --workspace --all-targets --locked
cargo run --locked -p autom8-cli -- --help
cargo run --locked -p autom8-gnome
```

Nenhum empacotamento ou instalação da versão 0.3 é oferecido nesta etapa.
