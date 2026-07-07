# Variáveis do AutoM8

| Variável | Padrão | Escopo | Descrição |
| --- | --- | --- | --- |
| `AUTOM8_SITE_URL` | `https://autom8.oslabs.com.br` | install, docs | URL pública do site oficial do AutoM8. |
| `AUTOM8_GITHUB_REPO` | `mdmjunior/autom8` | install, release, self-update | Repositório GitHub usado para releases estáveis. |
| `AUTOM8_PACKAGE_URL` | `https://github.com/mdmjunior/autom8/releases/latest/download/autom8-latest.tar.gz` | install, self-update | URL do pacote estável usado pelo instalador e validação de atualização. |
| `AUTOM8_INSTALL_DIR` | `/opt/autom8` | install, runtime | Diretório onde a suíte é instalada. |
| `AUTOM8_PACKAGE_OUTPUT_DIR` | `diretório temporário em /tmp` | package | Diretório temporário usado para gerar pacotes antes de publicar uma release. |
| `AUTOM8_REPO_DIR` | `/opt/oslabs/repos/autom8` | deploy | Caminho do repositório na VPS. |
| `AUTOM8_BRANCH` | `main` | deploy | Branch publicada na VPS. |
| `AUTOM8_DOMAIN` | `https://autom8.oslabs.com.br` | deploy | Domínio validado no final do deploy. |
| `AUTOM8_SERVICE_NAME` | `` | deploy | Nome do serviço Docker Swarm que deve ser reiniciado após o build. |
| `AUTOM8_RESTART_SERVICE` | `1` | deploy | Use 0 para validar build sem reiniciar o serviço. |
