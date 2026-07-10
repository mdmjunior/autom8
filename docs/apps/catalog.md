# AutoM8 Apps Catalog

O módulo Apps usa catálogo local consolidado em:

    suite/catalog/apps.json

A fonte do catálogo fica separada por categoria em:

    suite/catalog/apps/

O arquivo consolidado deve ser gerado por:

    ./scripts/build-apps-catalog.sh

## Estrutura

Cada arquivo de categoria deve conter:

    {
      "category": {
        "slug": "desenvolvimento",
        "name": "Desenvolvimento",
        "description": "Editores, linguagens, compiladores e ferramentas."
      },
      "apps": []
    }

Cada app deve conter:

    {
      "id": "git",
      "name": "Git",
      "summary": "Controle de versão distribuído.",
      "status": "available",
      "tags": ["scm", "github"],
      "packages": {
        "apt": ["git"],
        "dnf": ["git"],
        "zypper": ["git"],
        "pacman": ["git"]
      },
      "notes": []
    }

## Status

`available` significa que o AutoM8 pode tentar instalar/remover o app usando o gerenciador da distro.

`advanced` significa que o app aparece no catálogo, mas não é instalado automaticamente nesta versão.

Use `advanced` para apps que exigem:

- repositório externo;
- Flatpak;
- AUR;
- multilib;
- repositório non-free;
- configuração manual;
- instalador específico do fornecedor.

## Categorias oficiais

- desenvolvimento
- produtividade
- containers
- sistema
- rede
- midia
- design
- games
- escritorio
- usuario-local

## Comandos relacionados

    autom8 apps categories
    autom8 apps list
    autom8 apps list --category desenvolvimento
    autom8 apps search docker
    autom8 apps show git
    autom8 --dry-run apps install git
    autom8 apps install htop
    autom8 --dry-run apps install-many git htop jq
    autom8 apps install-many git htop jq
    autom8 --dry-run apps remove htop
    autom8 apps remove htop
    autom8 --dry-run apps remove-many git htop
    autom8 apps remove-many git htop

## Política de segurança

Toda instalação ou remoção real deve exigir confirmação explícita.

O modo `--dry-run` deve mostrar o comando previsto sem alterar o sistema.
