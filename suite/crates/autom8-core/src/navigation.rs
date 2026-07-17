#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum NavigationSection {
    Overview,
    Diagnostics,
    Management,
    System,
    Results,
}

impl NavigationSection {
    #[must_use]
    pub const fn title(self) -> &'static str {
        match self {
            Self::Overview => "Visão geral",
            Self::Diagnostics => "Diagnóstico",
            Self::Management => "Gerenciamento",
            Self::System => "Sistema",
            Self::Results => "Resultados",
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct NavigationItem {
    pub section: NavigationSection,
    pub command: &'static str,
    pub title: &'static str,
    pub description: &'static str,
    pub icon: &'static str,
    pub available: bool,
}

const NAVIGATION_ITEMS: [NavigationItem; 12] = [
    NavigationItem {
        section: NavigationSection::Overview,
        command: "status",
        title: "Visão geral",
        description: "Informações deste computador",
        icon: "computer-symbolic",
        available: true,
    },
    NavigationItem {
        section: NavigationSection::Diagnostics,
        command: "doctor",
        title: "Diagnóstico",
        description: "Verifica a saúde do ambiente",
        icon: "system-search-symbolic",
        available: false,
    },
    NavigationItem {
        section: NavigationSection::Management,
        command: "apps",
        title: "Aplicativos",
        description: "Instalação e remoção de programas",
        icon: "system-software-install-symbolic",
        available: false,
    },
    NavigationItem {
        section: NavigationSection::Management,
        command: "profiles",
        title: "Perfis",
        description: "Configurações por objetivo",
        icon: "view-grid-symbolic",
        available: false,
    },
    NavigationItem {
        section: NavigationSection::Management,
        command: "update",
        title: "Atualizações",
        description: "Atualiza o sistema com segurança",
        icon: "software-update-available-symbolic",
        available: false,
    },
    NavigationItem {
        section: NavigationSection::Management,
        command: "clean",
        title: "Manutenção",
        description: "Limpeza segura do sistema",
        icon: "user-trash-symbolic",
        available: false,
    },
    NavigationItem {
        section: NavigationSection::System,
        command: "security",
        title: "Segurança",
        description: "Verificações de proteção local",
        icon: "security-high-symbolic",
        available: false,
    },
    NavigationItem {
        section: NavigationSection::System,
        command: "docker",
        title: "Docker",
        description: "Contêineres e ambiente Docker",
        icon: "package-x-generic-symbolic",
        available: false,
    },
    NavigationItem {
        section: NavigationSection::System,
        command: "users",
        title: "Usuários",
        description: "Contas e grupos locais",
        icon: "system-users-symbolic",
        available: false,
    },
    NavigationItem {
        section: NavigationSection::System,
        command: "backup",
        title: "Backup",
        description: "Proteção antes de alterações",
        icon: "document-save-symbolic",
        available: false,
    },
    NavigationItem {
        section: NavigationSection::Results,
        command: "report",
        title: "Relatórios",
        description: "Resultados e históricos",
        icon: "document-open-recent-symbolic",
        available: false,
    },
    NavigationItem {
        section: NavigationSection::Results,
        command: "config",
        title: "Configurações",
        description: "Preferências do AutoM8",
        icon: "emblem-system-symbolic",
        available: false,
    },
];

#[must_use]
pub const fn navigation_items() -> &'static [NavigationItem] {
    &NAVIGATION_ITEMS
}

#[cfg(test)]
mod tests {
    use super::{NavigationSection, navigation_items};

    #[test]
    fn navigation_is_complete_and_ordered() {
        let items = navigation_items();

        assert_eq!(items.len(), 12);
        assert_eq!(items[0].command, "status");
        assert_eq!(items[0].section, NavigationSection::Overview);
        assert!(items[0].available);
    }

    #[test]
    fn commands_are_unique() {
        let items = navigation_items();

        for (index, item) in items.iter().enumerate() {
            assert!(
                items
                    .iter()
                    .skip(index + 1)
                    .all(|candidate| candidate.command != item.command)
            );
        }
    }
}
