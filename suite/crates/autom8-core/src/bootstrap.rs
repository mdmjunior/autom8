use std::fs;
use std::path::Path;

use serde::{Deserialize, Serialize};

pub const BOOTSTRAP_STATE_PATH: &str = "/var/lib/autom8/bootstrap/state.json";

#[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
pub struct BootstrapAnswers {
    pub hostname: String,
    pub timezone: String,
    pub refresh_repositories: bool,
    pub upgrade_packages: bool,
    pub install_dependencies: bool,
    pub configure_directories: bool,
    pub validate_network: bool,
    pub identify_hardware: bool,
    pub install_basic_packages: bool,
    pub editor: String,
    pub new_user: Option<NewUser>,
}

#[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
pub struct NewUser {
    pub username: String,
    pub full_name: String,
    pub administrator: bool,
}

#[derive(Clone, Debug, Eq, PartialEq, Serialize)]
pub struct BootstrapStep {
    pub id: &'static str,
    pub title: &'static str,
    pub enabled: bool,
    pub privileged: bool,
}

#[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
pub struct BootstrapState {
    pub schema_version: u32,
    pub completed: bool,
    pub result: String,
}

#[derive(Clone, Debug, Eq, PartialEq, Serialize)]
pub enum ProbeLevel {
    Success,
    Warning,
    Failure,
}

#[derive(Clone, Debug, Eq, PartialEq, Serialize)]
pub struct ProbeResult {
    pub title: String,
    pub detail: String,
    pub level: ProbeLevel,
}

impl BootstrapAnswers {
    #[must_use]
    pub fn validate(&self) -> Vec<String> {
        let mut errors = Vec::new();
        let hostname = self.hostname.trim();

        if hostname.is_empty()
            || hostname.len() > 63
            || hostname.starts_with('-')
            || hostname.ends_with('-')
            || !hostname
                .chars()
                .all(|character| character.is_ascii_alphanumeric() || character == '-')
        {
            errors.push(
                "Hostname inválido; use letras, números e hífen, com até 63 caracteres.".into(),
            );
        }

        if self.timezone.trim().is_empty() {
            errors.push("Timezone é obrigatório.".into());
        }

        if self.editor.trim().is_empty() {
            errors.push("Editor padrão é obrigatório.".into());
        }

        if let Some(user) = &self.new_user
            && (user.username.is_empty()
                || !user.username.chars().all(|character| {
                    character.is_ascii_lowercase()
                        || character.is_ascii_digit()
                        || character == '-'
                        || character == '_'
                }))
        {
            errors.push("Nome do novo usuário inválido.".into());
        }

        errors
    }

    #[must_use]
    pub fn plan(&self) -> Vec<BootstrapStep> {
        vec![
            step("hostname", "Configurar hostname", true, true),
            step("timezone", "Configurar timezone", true, true),
            step(
                "repositories",
                "Atualizar repositórios",
                self.refresh_repositories,
                true,
            ),
            step(
                "packages",
                "Atualizar pacotes instalados",
                self.upgrade_packages,
                true,
            ),
            step(
                "dependencies",
                "Instalar dependências",
                self.install_dependencies,
                true,
            ),
            step(
                "directories",
                "Configurar diretórios",
                self.configure_directories,
                true,
            ),
            step(
                "network",
                "Validar rede e DNS",
                self.validate_network,
                false,
            ),
            step(
                "hardware",
                "Identificar hardware",
                self.identify_hardware,
                false,
            ),
            step("user", "Criar usuário", self.new_user.is_some(), true),
            step(
                "basic-packages",
                "Instalar pacotes básicos",
                self.install_basic_packages,
                true,
            ),
            step("editor", "Alterar editor padrão", true, true),
        ]
    }
}

#[must_use]
pub fn completed_state(path: &Path) -> bool {
    fs::read_to_string(path)
        .ok()
        .and_then(|content| serde_json::from_str::<BootstrapState>(&content).ok())
        .is_some_and(|state| state.completed && state.result == "success")
}

#[must_use]
pub fn run_preflight(answers: &BootstrapAnswers) -> Vec<ProbeResult> {
    let mut results = vec![probe_distribution()];

    if answers.validate_network {
        results.extend(probe_network());
    }

    if answers.identify_hardware {
        results.extend(probe_hardware());
    }

    results
}

fn probe_distribution() -> ProbeResult {
    let os_release = fs::read_to_string("/etc/os-release").unwrap_or_default();
    let id = os_release
        .lines()
        .find_map(|line| line.strip_prefix("ID="))
        .map(|value| value.trim_matches('"').to_lowercase());

    match id.as_deref() {
        Some("ubuntu") => success("Distribuição", "Ubuntu detectado"),
        Some("fedora") => success("Distribuição", "Fedora detectado"),
        Some(other) => warning(
            "Distribuição",
            &format!("{other} detectado; suporte inicial limitado a Ubuntu e Fedora"),
        ),
        None => failure(
            "Distribuição",
            "Não foi possível identificar a distribuição",
        ),
    }
}

fn probe_network() -> Vec<ProbeResult> {
    let interfaces = fs::read_dir("/sys/class/net")
        .ok()
        .into_iter()
        .flatten()
        .filter_map(Result::ok)
        .filter_map(|entry| entry.file_name().into_string().ok())
        .filter(|name| name != "lo")
        .collect::<Vec<_>>();

    let interface_result = if interfaces.is_empty() {
        warning(
            "Rede",
            "Nenhuma interface de rede além de loopback foi encontrada",
        )
    } else {
        success(
            "Rede",
            &format!("Interfaces detectadas: {}", interfaces.join(", ")),
        )
    };

    let resolv_conf = fs::read_to_string("/etc/resolv.conf").unwrap_or_default();
    let dns_result = if resolv_conf
        .lines()
        .any(|line| line.trim_start().starts_with("nameserver "))
    {
        success("DNS", "Configuração local de resolução encontrada")
    } else {
        warning(
            "DNS",
            "Nenhum nameserver foi encontrado em /etc/resolv.conf",
        )
    };

    vec![interface_result, dns_result]
}

fn probe_hardware() -> Vec<ProbeResult> {
    let cpu_info = fs::read_to_string("/proc/cpuinfo").unwrap_or_default();
    let cpu = cpu_info
        .lines()
        .filter_map(|line| line.split_once(':'))
        .find(|(key, _)| key.trim() == "model name")
        .map_or_else(
            || "Modelo não identificado".to_string(),
            |(_, value)| value.trim().to_string(),
        );

    let memory_info = fs::read_to_string("/proc/meminfo").unwrap_or_default();
    let memory = memory_info
        .lines()
        .find_map(|line| line.strip_prefix("MemTotal:"))
        .map_or_else(
            || "Memória não identificada".to_string(),
            |value| value.trim().to_string(),
        );

    vec![
        success("Arquitetura", std::env::consts::ARCH),
        success("Processador", &cpu),
        success("Memória", &memory),
    ]
}

fn success(title: &str, detail: &str) -> ProbeResult {
    probe(title, detail, ProbeLevel::Success)
}

fn warning(title: &str, detail: &str) -> ProbeResult {
    probe(title, detail, ProbeLevel::Warning)
}

fn failure(title: &str, detail: &str) -> ProbeResult {
    probe(title, detail, ProbeLevel::Failure)
}

fn probe(title: &str, detail: &str, level: ProbeLevel) -> ProbeResult {
    ProbeResult {
        title: title.into(),
        detail: detail.into(),
        level,
    }
}

const fn step(
    id: &'static str,
    title: &'static str,
    enabled: bool,
    privileged: bool,
) -> BootstrapStep {
    BootstrapStep {
        id,
        title,
        enabled,
        privileged,
    }
}

#[cfg(test)]
mod tests {
    use super::BootstrapAnswers;

    fn valid_answers() -> BootstrapAnswers {
        BootstrapAnswers {
            hostname: "autom8-workstation".into(),
            timezone: "America/Sao_Paulo".into(),
            refresh_repositories: true,
            upgrade_packages: true,
            install_dependencies: true,
            configure_directories: true,
            validate_network: true,
            identify_hardware: true,
            install_basic_packages: true,
            editor: "nano".into(),
            new_user: None,
        }
    }

    #[test]
    fn valid_answers_create_plan() {
        let answers = valid_answers();
        assert!(answers.validate().is_empty());
        assert_eq!(answers.plan().len(), 11);
    }

    #[test]
    fn invalid_hostname_is_rejected() {
        let mut answers = valid_answers();
        answers.hostname = "nome inválido".into();
        assert!(!answers.validate().is_empty());
    }
}
