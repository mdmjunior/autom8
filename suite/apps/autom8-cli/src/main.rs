mod banner;
mod cli;

use std::io::{self, Write};
use std::process::ExitCode;

use autom8_core::ProductInfo;
use clap::Parser;
use cli::Cli;

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
        "Use 'autom8 --help' para ver as opções disponíveis."
    )
}

fn main() -> ExitCode {
    let cli = Cli::parse();

    match write_home(&cli) {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) if error.kind() == io::ErrorKind::BrokenPipe => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("autom8: falha ao escrever a saída: {error}");
            ExitCode::FAILURE
        }
    }
}
