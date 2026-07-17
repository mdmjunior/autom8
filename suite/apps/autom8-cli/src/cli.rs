use clap::{Args, Parser, Subcommand};

#[derive(Debug, Parser)]
#[command(
    name = "autom8",
    version,
    about = "Linux Management Suite",
    long_about = "AutoM8 — gerenciamento rápido, previsível e seguro para desktops Linux."
)]
pub struct Cli {
    /// Desativa cores ANSI na saída.
    #[arg(long, global = true)]
    pub no_color: bool,

    #[command(subcommand)]
    pub command: Option<Commands>,
}

#[derive(Debug, Subcommand)]
pub enum Commands {
    /// Prepara e valida a configuração inicial da máquina.
    Bootstrap(BootstrapArgs),

    /// Exibe informações do sistema sem realizar alterações.
    Status(StatusArgs),
}

#[derive(Debug, Args)]
pub struct BootstrapArgs {
    /// Hostname desejado para a máquina.
    #[arg(long)]
    pub hostname: String,

    /// Timezone desejado, por exemplo America/Sao_Paulo.
    #[arg(long)]
    pub timezone: String,

    /// Editor padrão desejado.
    #[arg(long, default_value = "nano")]
    pub editor: String,

    /// Atualiza os metadados dos repositórios.
    #[arg(long)]
    pub refresh_repositories: bool,

    /// Atualiza os pacotes instalados.
    #[arg(long)]
    pub upgrade_packages: bool,

    /// Instala dependências do AutoM8.
    #[arg(long)]
    pub install_dependencies: bool,

    /// Configura os diretórios gerenciados.
    #[arg(long)]
    pub configure_directories: bool,

    /// Executa verificações locais de rede e DNS.
    #[arg(long)]
    pub validate_network: bool,

    /// Identifica arquitetura, processador e memória.
    #[arg(long)]
    pub identify_hardware: bool,

    /// Inclui o conjunto inicial de pacotes básicos.
    #[arg(long)]
    pub install_basic_packages: bool,

    /// Executa agora as verificações somente leitura.
    #[arg(long)]
    pub check: bool,

    /// Produz saída JSON para automação.
    #[arg(long)]
    pub json: bool,
}

#[derive(Debug, Args)]
pub struct StatusArgs {
    /// Produz saída JSON para automação.
    #[arg(long)]
    pub json: bool,
}

#[cfg(test)]
mod tests {
    use clap::{CommandFactory, Parser};

    use super::{Cli, Commands};

    #[test]
    fn clap_definition_is_valid() {
        Cli::command().debug_assert();
    }

    #[test]
    fn no_color_flag_is_parsed() {
        let cli = Cli::try_parse_from(["autom8", "--no-color"]);

        assert!(cli.is_ok());
        assert!(cli.is_ok_and(|parsed| parsed.no_color));
    }

    #[test]
    fn status_json_is_parsed() {
        let cli = Cli::try_parse_from(["autom8", "status", "--json"]);

        assert!(matches!(
            cli,
            Ok(Cli {
                command: Some(Commands::Status(arguments)),
                ..
            }) if arguments.json
        ));
    }

    #[test]
    fn bootstrap_minimum_is_parsed() {
        let cli = Cli::try_parse_from([
            "autom8",
            "bootstrap",
            "--hostname",
            "workstation",
            "--timezone",
            "America/Sao_Paulo",
        ]);

        assert!(matches!(
            cli,
            Ok(Cli {
                command: Some(Commands::Bootstrap(_)),
                ..
            })
        ));
    }
}
