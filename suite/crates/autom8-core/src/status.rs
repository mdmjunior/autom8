use std::env;
use std::error::Error;
use std::fmt;
use std::fs;
use std::io;
use std::process::Command;

use serde::Serialize;

#[derive(Clone, Debug, Eq, PartialEq, Serialize)]
pub struct Distribution {
    pub id: String,
    pub name: String,
    pub version: String,
}

#[derive(Clone, Debug, Eq, PartialEq, Serialize)]
pub struct SystemStatus {
    pub hostname: String,
    pub distribution: Distribution,
    pub kernel: String,
    pub architecture: String,
    pub desktop: Option<String>,
    pub uptime_seconds: u64,
}

#[derive(Debug)]
pub enum StatusError {
    ReadFile {
        path: &'static str,
        source: io::Error,
    },
    CommandFailed {
        command: &'static str,
    },
    InvalidUptime,
}

impl fmt::Display for StatusError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::ReadFile { path, source } => {
                write!(formatter, "não foi possível ler {path}: {source}")
            }
            Self::CommandFailed { command } => {
                write!(
                    formatter,
                    "o comando '{command}' não retornou um valor válido"
                )
            }
            Self::InvalidUptime => formatter.write_str("o conteúdo de /proc/uptime é inválido"),
        }
    }
}

impl Error for StatusError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        match self {
            Self::ReadFile { source, .. } => Some(source),
            Self::CommandFailed { .. } | Self::InvalidUptime => None,
        }
    }
}

impl SystemStatus {
    pub fn collect() -> Result<Self, StatusError> {
        let os_release = read_file("/etc/os-release")?;
        let hostname = read_file("/etc/hostname")?;
        let uptime = read_file("/proc/uptime")?;

        Ok(Self {
            hostname: parse_hostname(&hostname),
            distribution: parse_os_release(&os_release),
            kernel: uname("-r", "uname -r")?,
            architecture: uname("-m", "uname -m")?,
            desktop: detect_desktop(),
            uptime_seconds: parse_uptime(&uptime)?,
        })
    }
}

fn read_file(path: &'static str) -> Result<String, StatusError> {
    fs::read_to_string(path).map_err(|source| StatusError::ReadFile { path, source })
}

fn uname(argument: &str, description: &'static str) -> Result<String, StatusError> {
    let output =
        Command::new("uname")
            .arg(argument)
            .output()
            .map_err(|_| StatusError::CommandFailed {
                command: description,
            })?;

    if !output.status.success() {
        return Err(StatusError::CommandFailed {
            command: description,
        });
    }

    let value = String::from_utf8_lossy(&output.stdout).trim().to_owned();

    if value.is_empty() {
        return Err(StatusError::CommandFailed {
            command: description,
        });
    }

    Ok(value)
}

fn parse_hostname(contents: &str) -> String {
    let hostname = contents.trim();

    if hostname.is_empty() {
        "desconhecido".to_owned()
    } else {
        hostname.to_owned()
    }
}

fn parse_os_release(contents: &str) -> Distribution {
    let value = |key: &str| {
        contents
            .lines()
            .filter_map(|line| line.split_once('='))
            .find(|(candidate, _)| *candidate == key)
            .map(|(_, raw)| decode_os_release_value(raw))
    };

    let id = value("ID").unwrap_or_else(|| "unknown".to_owned());
    let name = value("PRETTY_NAME")
        .or_else(|| value("NAME"))
        .unwrap_or_else(|| id.clone());
    let version = value("VERSION_ID").unwrap_or_default();

    Distribution { id, name, version }
}

fn decode_os_release_value(raw: &str) -> String {
    let value = raw.trim();
    let unquoted = if value.len() >= 2
        && ((value.starts_with('"') && value.ends_with('"'))
            || (value.starts_with('\'') && value.ends_with('\'')))
    {
        &value[1..value.len() - 1]
    } else {
        value
    };

    unquoted
        .replace("\\\"", "\"")
        .replace("\\'", "'")
        .replace("\\\\", "\\")
}

fn detect_desktop() -> Option<String> {
    env::var("XDG_CURRENT_DESKTOP")
        .ok()
        .filter(|value| !value.trim().is_empty())
        .or_else(|| {
            env::var("DESKTOP_SESSION")
                .ok()
                .filter(|value| !value.trim().is_empty())
        })
}

fn parse_uptime(contents: &str) -> Result<u64, StatusError> {
    let seconds = contents
        .split_whitespace()
        .next()
        .ok_or(StatusError::InvalidUptime)?
        .parse::<f64>()
        .map_err(|_| StatusError::InvalidUptime)?;

    if !seconds.is_finite() || seconds.is_sign_negative() {
        return Err(StatusError::InvalidUptime);
    }

    Ok(seconds.floor() as u64)
}

#[cfg(test)]
mod tests {
    use super::{parse_hostname, parse_os_release, parse_uptime};

    #[test]
    fn parses_fedora_os_release() {
        let distribution = parse_os_release(
            "NAME=\"Fedora Linux\"\n\
             VERSION_ID=42\n\
             ID=fedora\n\
             PRETTY_NAME=\"Fedora Linux 42 (Workstation Edition)\"\n",
        );

        assert_eq!(distribution.id, "fedora");
        assert_eq!(distribution.name, "Fedora Linux 42 (Workstation Edition)");
        assert_eq!(distribution.version, "42");
    }

    #[test]
    fn parses_ubuntu_os_release() {
        let distribution = parse_os_release(
            "NAME=\"Ubuntu\"\n\
             VERSION_ID=\"24.04\"\n\
             ID=ubuntu\n\
             PRETTY_NAME=\"Ubuntu 24.04 LTS\"\n",
        );

        assert_eq!(distribution.id, "ubuntu");
        assert_eq!(distribution.name, "Ubuntu 24.04 LTS");
        assert_eq!(distribution.version, "24.04");
    }

    #[test]
    fn unknown_distribution_uses_safe_defaults() {
        let distribution = parse_os_release("CUSTOM=value\n");

        assert_eq!(distribution.id, "unknown");
        assert_eq!(distribution.name, "unknown");
        assert!(distribution.version.is_empty());
    }

    #[test]
    fn empty_hostname_uses_safe_fallback() {
        assert_eq!(parse_hostname(" \n"), "desconhecido");
    }

    #[test]
    fn uptime_is_rounded_down() {
        assert!(parse_uptime("12345.67 54321.00\n").is_ok_and(|uptime| uptime == 12_345));
    }

    #[test]
    fn invalid_uptime_is_rejected() {
        assert!(parse_uptime("not-a-number\n").is_err());
        assert!(parse_uptime("-10.0 20.0\n").is_err());
    }
}
