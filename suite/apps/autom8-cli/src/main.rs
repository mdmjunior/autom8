mod banner;
mod cli;

use std::io::{self, Write};
use std::process::ExitCode;

use autom8_core::ProductInfo;
use autom8_core::bootstrap::{BootstrapAnswers, ProbeLevel, run_preflight};
use autom8_core::status::{StatusError, SystemStatus};
use clap::Parser;
use cli::{BootstrapArgs, Cli, Commands, StatusArgs};

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

    writeln!(output)?;
    writeln!(output, "BOOTSTRAP")?;
    writeln!(output, "  bootstrap      Configuração inicial da máquina")?;
    writeln!(output)?;
    writeln!(output, "SUPORTE")?;
    writeln!(output, "  status         Informações somente leitura")?;
    writeln!(output)?;
    writeln!(output, "Use 'autom8 bootstrap --help' para iniciar.")
}

fn write_bootstrap(arguments: &BootstrapArgs) -> Result<(), BootstrapCommandError> {
    let answers = BootstrapAnswers {
        hostname: arguments.hostname.clone(),
        timezone: arguments.timezone.clone(),
        refresh_repositories: arguments.refresh_repositories,
        upgrade_packages: arguments.upgrade_packages,
        install_dependencies: arguments.install_dependencies,
        configure_directories: arguments.configure_directories,
        validate_network: arguments.validate_network,
        identify_hardware: arguments.identify_hardware,
        install_basic_packages: arguments.install_basic_packages,
        editor: arguments.editor.clone(),
        new_user: None,
    };
    let errors = answers.validate();
    if !errors.is_empty() {
        return Err(BootstrapCommandError::Validation(errors));
    }

    let plan = answers.plan();
    let probes = arguments.check.then(|| run_preflight(&answers));
    let stdout = io::stdout();
    let mut output = stdout.lock();

    if arguments.json {
        let document = serde_json::json!({
            "answers": answers,
            "plan": plan,
            "preflight": probes,
            "changes_applied": false,
        });
        serde_json::to_writer_pretty(&mut output, &document)?;
        writeln!(output)?;
        return Ok(());
    }

    writeln!(output, "AutoM8 · Bootstrap")?;
    writeln!(output, "────────────────────────────────────────")?;
    writeln!(output, "Hostname    {}", answers.hostname)?;
    writeln!(output, "Timezone    {}", answers.timezone)?;
    writeln!(output, "Editor      {}", answers.editor)?;
    writeln!(output)?;
    writeln!(output, "Plano")?;
    for step in plan.iter().filter(|step| step.enabled) {
        let privilege = if step.privileged {
            "autenticação"
        } else {
            "leitura"
        };
        writeln!(output, "  • {:<30} {privilege}", step.title)?;
    }

    if let Some(probes) = probes {
        writeln!(output)?;
        writeln!(output, "Verificações locais")?;
        for probe in probes {
            let marker = match probe.level {
                ProbeLevel::Success => "✓",
                ProbeLevel::Warning => "!",
                ProbeLevel::Failure => "✕",
            };
            writeln!(output, "  {marker} {} — {}", probe.title, probe.detail)?;
        }
    }

    writeln!(output)?;
    writeln!(output, "Nenhuma alteração foi aplicada.")?;
    Ok(())
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

#[derive(Debug)]
enum BootstrapCommandError {
    Validation(Vec<String>),
    Json(serde_json::Error),
    Output(io::Error),
}

impl From<serde_json::Error> for BootstrapCommandError {
    fn from(error: serde_json::Error) -> Self {
        Self::Json(error)
    }
}

impl From<io::Error> for BootstrapCommandError {
    fn from(error: io::Error) -> Self {
        Self::Output(error)
    }
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
        Some(Commands::Bootstrap(arguments)) => match write_bootstrap(arguments) {
            Ok(()) => ExitCode::SUCCESS,
            Err(BootstrapCommandError::Output(error))
                if error.kind() == io::ErrorKind::BrokenPipe =>
            {
                ExitCode::SUCCESS
            }
            Err(BootstrapCommandError::Validation(errors)) => {
                for error in errors {
                    eprintln!("autom8: {error}");
                }
                ExitCode::from(2)
            }
            Err(BootstrapCommandError::Json(error)) => {
                eprintln!("autom8: não foi possível gerar o JSON: {error}");
                ExitCode::FAILURE
            }
            Err(BootstrapCommandError::Output(error)) => {
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
