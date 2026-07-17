use clap::Parser;

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
}

#[cfg(test)]
mod tests {
    use clap::{CommandFactory, Parser};

    use super::Cli;

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
}
