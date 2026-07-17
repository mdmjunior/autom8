use std::path::Path;

use adw::prelude::*;
use autom8_core::bootstrap::{
    BOOTSTRAP_STATE_PATH, BootstrapAnswers, NewUser, ProbeLevel, completed_state, run_preflight,
};
use autom8_core::{APPLICATION_ID, ProductInfo};
use gtk::glib;

const STYLE: &str = r#"
window, .autom8-root { background: #050b18; color: #f8fafc; }
.autom8-header { background: #081224; border-bottom: 1px solid rgba(56,189,248,.18); }
.autom8-page { padding: 24px 30px 36px; }
.autom8-hero { padding: 18px 20px; border-left: 4px solid #0866ff; border-radius: 12px; background: #0b1528; }
.autom8-title { color: #f8fafc; font-size: 23px; font-weight: 900; }
.autom8-copy { color: #94a3b8; font-size: 13px; }
.autom8-section { margin-top: 18px; color: #f8fafc; font-size: 16px; font-weight: 900; }
.autom8-card { padding: 18px; border: 1px solid rgba(148,163,184,.16); border-radius: 12px; background: #0b1528; }
.autom8-entry { min-height: 42px; border-radius: 10px; }
.autom8-primary { min-height: 44px; border-radius: 11px; background: #0866ff; color: white; font-weight: 900; }
.autom8-success { padding: 12px 14px; border-radius: 10px; background: rgba(34,197,94,.10); color: #86efac; }
.autom8-error { padding: 12px 14px; border-radius: 10px; background: rgba(239,68,68,.10); color: #fca5a5; }
.autom8-plan { padding: 14px; border-radius: 12px; background: #020817; color: #dbeafe; font-family: monospace; }
"#;

#[derive(Clone)]
struct Form {
    hostname: gtk::Entry,
    timezone: gtk::Entry,
    refresh_repositories: gtk::Switch,
    upgrade_packages: gtk::Switch,
    install_dependencies: gtk::Switch,
    configure_directories: gtk::Switch,
    validate_network: gtk::Switch,
    identify_hardware: gtk::Switch,
    install_basic_packages: gtk::Switch,
    editor: gtk::Entry,
    create_user: gtk::Switch,
    username: gtk::Entry,
    full_name: gtk::Entry,
    administrator: gtk::Switch,
}

fn main() -> glib::ExitCode {
    let application = adw::Application::builder()
        .application_id(APPLICATION_ID)
        .build();
    application.connect_startup(|_| install_style());
    application.connect_activate(build_ui);
    application.run()
}

fn install_style() {
    let provider = gtk::CssProvider::new();
    provider.load_from_data(STYLE);
    if let Some(display) = gtk::gdk::Display::default() {
        gtk::style_context_add_provider_for_display(
            &display,
            &provider,
            gtk::STYLE_PROVIDER_PRIORITY_APPLICATION,
        );
    }
}

fn build_ui(application: &adw::Application) {
    let product = ProductInfo::current();
    let shell = gtk::Box::new(gtk::Orientation::Vertical, 0);
    shell.add_css_class("autom8-root");

    let header = adw::HeaderBar::builder()
        .title_widget(&adw::WindowTitle::new(product.name, "Bootstrap inicial"))
        .build();
    header.add_css_class("autom8-header");
    shell.append(&header);

    if completed_state(Path::new(BOOTSTRAP_STATE_PATH)) {
        let done = adw::StatusPage::builder()
            .icon_name("emblem-ok-symbolic")
            .title("Bootstrap concluído")
            .description("Esta máquina já possui um bootstrap concluído sem erros.")
            .vexpand(true)
            .build();
        shell.append(&done);
    } else {
        shell.append(&bootstrap_page());
    }

    let window = adw::ApplicationWindow::builder()
        .application(application)
        .title(product.name)
        .default_width(1040)
        .default_height(820)
        .content(&shell)
        .build();
    window.present();
}

fn bootstrap_page() -> gtk::ScrolledWindow {
    let page = gtk::Box::new(gtk::Orientation::Vertical, 0);
    page.add_css_class("autom8-page");

    let hero = gtk::Box::new(gtk::Orientation::Horizontal, 24);
    hero.add_css_class("autom8-hero");
    hero.set_margin_bottom(22);

    let logo = gtk::Picture::for_filename(concat!(
        env!("CARGO_MANIFEST_DIR"),
        "/assets/logo-autom8-bootstrap.png"
    ));
    logo.set_size_request(220, 52);
    logo.set_can_shrink(true);

    let hero_text = gtk::Box::new(gtk::Orientation::Vertical, 5);
    hero_text.set_valign(gtk::Align::Center);
    hero_text.set_hexpand(true);
    let title = label("Configuração inicial", "autom8-title");
    let copy = label(
        "Prepare esta estação Linux antes de habilitar os demais módulos do AutoM8.",
        "autom8-copy",
    );
    copy.set_wrap(true);
    hero_text.append(&title);
    hero_text.append(&copy);
    hero.append(&logo);
    hero.append(&hero_text);
    page.append(&hero);

    page.append(&label("Identidade da máquina", "autom8-section"));
    let identity = gtk::Grid::builder()
        .column_spacing(16)
        .row_spacing(12)
        .column_homogeneous(true)
        .build();
    identity.add_css_class("autom8-card");
    identity.set_margin_top(10);

    let hostname = entry("autom8-workstation");
    let timezone = entry("America/Sao_Paulo");
    let editor = entry("nano");
    field(&identity, 0, 0, "Hostname", &hostname);
    field(&identity, 1, 0, "Timezone", &timezone);
    field(&identity, 0, 2, "Editor padrão", &editor);
    page.append(&identity);

    page.append(&label("Operações iniciais", "autom8-section"));
    let operations = gtk::Grid::builder()
        .column_spacing(24)
        .row_spacing(12)
        .column_homogeneous(true)
        .build();
    operations.add_css_class("autom8-card");
    operations.set_margin_top(10);

    let refresh_repositories = operation(&operations, 0, 0, "Atualizar repositórios", true);
    let upgrade_packages = operation(&operations, 1, 0, "Atualizar pacotes instalados", false);
    let install_dependencies = operation(&operations, 0, 1, "Instalar dependências", true);
    let configure_directories = operation(&operations, 1, 1, "Configurar diretórios", true);
    let validate_network = operation(&operations, 0, 2, "Validar rede e DNS", true);
    let identify_hardware = operation(&operations, 1, 2, "Identificar hardware", true);
    let install_basic_packages = operation(&operations, 0, 3, "Instalar pacotes básicos", true);
    page.append(&operations);

    page.append(&label("Usuário adicional", "autom8-section"));
    let user_card = gtk::Box::new(gtk::Orientation::Vertical, 12);
    user_card.add_css_class("autom8-card");
    user_card.set_margin_top(10);
    let create_user = row_switch("Criar um novo usuário", false);
    let create_user_switch = create_user.1.clone();
    user_card.append(&create_user.0);

    let user_fields = gtk::Grid::builder()
        .column_spacing(16)
        .row_spacing(12)
        .column_homogeneous(true)
        .visible(false)
        .build();
    let username = entry("usuario");
    let full_name = entry("Nome completo");
    field(&user_fields, 0, 0, "Login", &username);
    field(&user_fields, 1, 0, "Nome completo", &full_name);
    let admin = row_switch("Conceder acesso administrativo", false);
    user_fields.attach(&admin.0, 0, 2, 2, 1);
    let administrator = admin.1;
    let user_fields_for_toggle = user_fields.clone();
    create_user_switch.connect_active_notify(move |control| {
        user_fields_for_toggle.set_visible(control.is_active());
    });
    user_card.append(&user_fields);
    page.append(&user_card);

    page.append(&label("Plano para aprovação", "autom8-section"));
    let plan = gtk::TextView::builder()
        .editable(false)
        .cursor_visible(false)
        .monospace(true)
        .vexpand(false)
        .build();
    plan.add_css_class("autom8-plan");
    plan.set_margin_top(10);
    plan.set_size_request(-1, 250);
    page.append(&plan);

    let message = gtk::Label::builder()
        .halign(gtk::Align::Fill)
        .xalign(0.0)
        .wrap(true)
        .visible(false)
        .build();
    message.set_margin_top(14);
    page.append(&message);

    let approval = gtk::CheckButton::with_label("Revisei e aprovo este plano");
    approval.set_margin_top(16);
    page.append(&approval);

    let actions = gtk::Box::new(gtk::Orientation::Horizontal, 10);
    actions.set_halign(gtk::Align::End);
    actions.set_margin_top(14);
    let preview = gtk::Button::with_label("Gerar plano");
    let execute = gtk::Button::with_label("Executar verificações");
    execute.add_css_class("autom8-primary");
    execute.set_sensitive(false);
    actions.append(&preview);
    actions.append(&execute);
    page.append(&actions);

    let form = Form {
        hostname,
        timezone,
        refresh_repositories,
        upgrade_packages,
        install_dependencies,
        configure_directories,
        validate_network,
        identify_hardware,
        install_basic_packages,
        editor,
        create_user: create_user_switch,
        username,
        full_name,
        administrator,
    };

    let form_for_preview = form.clone();
    let plan_for_preview = plan.clone();
    let message_for_preview = message.clone();
    preview.connect_clicked(move |_| {
        render_plan(&form_for_preview, &plan_for_preview, &message_for_preview);
    });

    let execute_for_approval = execute.clone();
    approval.connect_toggled(move |control| {
        execute_for_approval.set_sensitive(control.is_active());
    });

    let form_for_execute = form;
    let plan_for_execute = plan;
    execute.connect_clicked(move |_| {
        if render_plan(&form_for_execute, &plan_for_execute, &message) {
            render_preflight(&form_for_execute, &plan_for_execute, &message);
        }
    });

    gtk::ScrolledWindow::builder()
        .hscrollbar_policy(gtk::PolicyType::Never)
        .vexpand(true)
        .child(&page)
        .build()
}

fn render_preflight(form: &Form, view: &gtk::TextView, message: &gtk::Label) {
    let answers = answers(form);
    let results = run_preflight(&answers);
    let failures = results
        .iter()
        .filter(|result| result.level == ProbeLevel::Failure)
        .count();

    let mut output = view
        .buffer()
        .text(
            &view.buffer().start_iter(),
            &view.buffer().end_iter(),
            false,
        )
        .to_string();
    output.push_str("\nVERIFICAÇÕES LOCAIS\n");

    for result in &results {
        let marker = match result.level {
            ProbeLevel::Success => "✓",
            ProbeLevel::Warning => "!",
            ProbeLevel::Failure => "✕",
        };
        output.push_str(&format!(
            "  {marker} {} — {}\n",
            result.title, result.detail
        ));
    }

    view.buffer().set_text(&output);
    if failures == 0 {
        show_message(
            message,
            "Verificações concluídas. As operações privilegiadas ainda não foram executadas.",
            false,
        );
    } else {
        show_message(
            message,
            "Uma ou mais verificações críticas falharam. O Bootstrap permanece incompleto.",
            true,
        );
    }
}

fn answers(form: &Form) -> BootstrapAnswers {
    BootstrapAnswers {
        hostname: form.hostname.text().to_string(),
        timezone: form.timezone.text().to_string(),
        refresh_repositories: form.refresh_repositories.is_active(),
        upgrade_packages: form.upgrade_packages.is_active(),
        install_dependencies: form.install_dependencies.is_active(),
        configure_directories: form.configure_directories.is_active(),
        validate_network: form.validate_network.is_active(),
        identify_hardware: form.identify_hardware.is_active(),
        install_basic_packages: form.install_basic_packages.is_active(),
        editor: form.editor.text().to_string(),
        new_user: form.create_user.is_active().then(|| NewUser {
            username: form.username.text().to_string(),
            full_name: form.full_name.text().to_string(),
            administrator: form.administrator.is_active(),
        }),
    }
}

fn render_plan(form: &Form, view: &gtk::TextView, message: &gtk::Label) -> bool {
    let answers = answers(form);
    let errors = answers.validate();
    if !errors.is_empty() {
        show_message(message, &errors.join("\n"), true);
        return false;
    }

    let mut output = format!(
        "Hostname: {}\nTimezone: {}\nEditor: {}\n\nETAPAS\n",
        answers.hostname, answers.timezone, answers.editor
    );
    for step in answers.plan().iter().filter(|step| step.enabled) {
        let privilege = if step.privileged {
            "requer autenticação"
        } else {
            "somente leitura"
        };
        output.push_str(&format!("  • {} — {}\n", step.title, privilege));
    }
    view.buffer().set_text(&output);
    show_message(message, "Plano válido. Revise antes de aprovar.", false);
    true
}

fn show_message(label: &gtk::Label, text: &str, error: bool) {
    label.remove_css_class(if error {
        "autom8-success"
    } else {
        "autom8-error"
    });
    label.add_css_class(if error {
        "autom8-error"
    } else {
        "autom8-success"
    });
    label.set_text(text);
    label.set_visible(true);
}

fn label(text: &str, class: &str) -> gtk::Label {
    let label = gtk::Label::builder()
        .label(text)
        .halign(gtk::Align::Start)
        .build();
    label.add_css_class(class);
    label
}

fn entry(placeholder: &str) -> gtk::Entry {
    let entry = gtk::Entry::builder()
        .placeholder_text(placeholder)
        .hexpand(true)
        .build();
    entry.add_css_class("autom8-entry");
    entry
}

fn field(grid: &gtk::Grid, column: i32, row: i32, title: &str, entry: &gtk::Entry) {
    let title = label(title, "autom8-copy");
    grid.attach(&title, column, row, 1, 1);
    grid.attach(entry, column, row + 1, 1, 1);
}

fn operation(grid: &gtk::Grid, column: i32, row: i32, title: &str, active: bool) -> gtk::Switch {
    let (container, control) = row_switch(title, active);
    grid.attach(&container, column, row, 1, 1);
    control
}

fn row_switch(title: &str, active: bool) -> (gtk::Box, gtk::Switch) {
    let row = gtk::Box::new(gtk::Orientation::Horizontal, 12);
    let title = gtk::Label::builder()
        .label(title)
        .halign(gtk::Align::Start)
        .hexpand(true)
        .build();
    let control = gtk::Switch::builder()
        .active(active)
        .valign(gtk::Align::Center)
        .build();
    row.append(&title);
    row.append(&control);
    (row, control)
}
