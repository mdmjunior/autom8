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

## Arquitetura interna do módulo Apps

A entrada pública do módulo continua em:

    suite/modules/apps.sh

Esse arquivo apenas carrega bibliotecas internas em:

    suite/lib/apps/

Divisão atual:

    suite/lib/apps/catalog.sh
    suite/lib/apps/packages.sh
    suite/lib/apps/install.sh
    suite/lib/apps/remove.sh
    suite/lib/apps/menu.sh
    suite/lib/apps/module.sh

Responsabilidades:

- catalog.sh: leitura do catálogo, categorias, busca, detalhes e filtros.
- packages.sh: verificação de pacotes disponíveis/instalados e comandos por gerenciador.
- install.sh: instalação individual e múltipla.
- remove.sh: remoção individual e múltipla.
- menu.sh: menu interativo.
- module.sh: roteamento do comando autom8 apps.

O empacotamento inclui automaticamente suite/lib/ porque o pacote é gerado a partir de suite/.
