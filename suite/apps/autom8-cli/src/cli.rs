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
    /// Exibe informações do sistema sem realizar alterações.
    Status(StatusArgs),
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
}
