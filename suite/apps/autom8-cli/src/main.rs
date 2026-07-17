mod banner;
mod cli;

use std::io::{self, Write};
use std::process::ExitCode;

use autom8_core::ProductInfo;
use autom8_core::navigation::{NavigationSection, navigation_items};
use autom8_core::status::{StatusError, SystemStatus};
use clap::Parser;
use cli::{Cli, Commands, StatusArgs};

const NAVIGATION_SECTIONS: [NavigationSection; 5] = [
    NavigationSection::Overview,
    NavigationSection::Diagnostics,
    NavigationSection::Management,
    NavigationSection::System,
    NavigationSection::Results,
];

fn write_home(cli: &Cli) -> io::Result<()> {
    let product = ProductInfo::current();
    let stdout = io::stdout();
    let mut output = stdout.lock();

    output.write_all(banner::render(banner::color_is_enabled(cli.no_color)).as_bytes())?;
    writeln!(
        output,
        "{} {} — {}",
        product.name, product.version, product.description
    )?;
    writeln!(
        output,
        "Execução local · Sem telemetria · Seguro por padrão"
    )?;

    for section in NAVIGATION_SECTIONS {
        writeln!(output)?;
        writeln!(output, "{}", section.title().to_uppercase())?;

        for item in navigation_items()
            .iter()
            .filter(|item| item.section == section)
        {
            let state = if item.available { "" } else { " [em breve]" };

            writeln!(
                output,
                "  {:<14} {}{}",
                item.command, item.description, state
            )?;
        }
    }

    writeln!(output)?;
    writeln!(
        output,
        "Use 'autom8 <comando> --help' para ver opções específicas."
    )
}

fn write_status(arguments: &StatusArgs) -> Result<(), StatusCommandError> {
    let status = SystemStatus::collect()?;
    let stdout = io::stdout();
    let mut output = stdout.lock();

    if arguments.json {
        serde_json::to_writer_pretty(&mut output, &status)?;
        writeln!(output)?;
    } else {
        writeln!(output, "AutoM8 · Visão geral")?;
        writeln!(output, "────────────────────────────────────────")?;
        writeln!(output, "Sistema")?;
        writeln!(output, "  Hostname       {}", status.hostname)?;
        writeln!(
            output,
            "  Distribuição   {} ({})",
            status.distribution.name, status.distribution.id
        )?;
        writeln!(output, "  Versão         {}", status.distribution.version)?;
        writeln!(output)?;
        writeln!(output, "Ambiente")?;
        writeln!(output, "  Kernel         {}", status.kernel)?;
        writeln!(output, "  Arquitetura    {}", status.architecture)?;
        writeln!(
            output,
            "  Desktop        {}",
            status.desktop.as_deref().unwrap_or("não detectado")
        )?;
        writeln!(
            output,
            "  Uptime         {} segundos",
            status.uptime_seconds
        )?;
        writeln!(output)?;
        writeln!(output, "✓ Informações atualizadas com sucesso")?;
    }

    Ok(())
}

#[derive(Debug)]
enum StatusCommandError {
    Collection(StatusError),
    Json(serde_json::Error),
    Output(io::Error),
}

impl From<StatusError> for StatusCommandError {
    fn from(error: StatusError) -> Self {
        Self::Collection(error)
    }
}

impl From<serde_json::Error> for StatusCommandError {
    fn from(error: serde_json::Error) -> Self {
        Self::Json(error)
    }
}

impl From<io::Error> for StatusCommandError {
    fn from(error: io::Error) -> Self {
        Self::Output(error)
    }
}

fn main() -> ExitCode {
    let cli = Cli::parse();

    match &cli.command {
        None => match write_home(&cli) {
            Ok(()) => ExitCode::SUCCESS,
            Err(error) if error.kind() == io::ErrorKind::BrokenPipe => ExitCode::SUCCESS,
            Err(error) => {
                eprintln!("autom8: falha ao escrever a saída: {error}");
                ExitCode::FAILURE
            }
        },
        Some(Commands::Status(arguments)) => match write_status(arguments) {
            Ok(()) => ExitCode::SUCCESS,
            Err(StatusCommandError::Output(error)) if error.kind() == io::ErrorKind::BrokenPipe => {
                ExitCode::SUCCESS
            }
            Err(StatusCommandError::Collection(error)) => {
                eprintln!("autom8: não foi possível coletar o status: {error}");
                ExitCode::FAILURE
            }
            Err(StatusCommandError::Json(error)) => {
                eprintln!("autom8: não foi possível gerar o JSON: {error}");
                ExitCode::FAILURE
            }
            Err(StatusCommandError::Output(error)) => {
                eprintln!("autom8: falha ao escrever a saída: {error}");
                ExitCode::FAILURE
            }
        },
    }
}
