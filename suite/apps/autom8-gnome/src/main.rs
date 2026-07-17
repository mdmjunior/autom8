use std::cell::RefCell;
use std::rc::Rc;

use adw::prelude::*;
use autom8_core::navigation::navigation_items;
use autom8_core::{
    APPLICATION_ID, ProductInfo,
    status::{StatusError, SystemStatus},
};
use gtk::glib;

const STYLE: &str = r#"
window,
.autom8-root {
  background: #0b1220;
  color: #f8fafc;
}

.autom8-window-bar {
  min-height: 50px;
  background: rgba(11, 18, 32, 0.96);
  color: #f8fafc;
  border-bottom: 1px solid rgba(148, 163, 184, 0.18);
}

.autom8-sidebar {
  min-width: 278px;
  background: #0b1324;
  border-right: 1px solid rgba(148, 163, 184, 0.18);
  padding: 24px 18px 20px;
}

.autom8-brand-name {
  color: #f8fafc;
  font-size: 18px;
  font-weight: 900;
}

.autom8-brand-name-accent {
  color: #38bdf8;
}

.autom8-muted {
  color: #94a3b8;
}

.autom8-section {
  margin-top: 16px;
  margin-bottom: 5px;
  color: #64748b;
  font-size: 11px;
  font-weight: 800;
}

.autom8-menu-button {
  min-height: 44px;
  margin: 2px 0;
  border: 1px solid transparent;
  border-radius: 10px;
  background: transparent;
  color: #94a3b8;
  box-shadow: none;
}

.autom8-menu-button:hover {
  border-color: rgba(56, 189, 248, 0.22);
  background: rgba(37, 99, 235, 0.10);
  color: #dbeafe;
}

.autom8-menu-button-active {
  border-color: rgba(56, 189, 248, 0.42);
  background: linear-gradient(90deg, rgba(37, 99, 235, 0.34), rgba(56, 189, 248, 0.10));
  color: #f8fafc;
}

.autom8-coming-soon {
  color: #64748b;
  font-size: 9px;
  font-weight: 800;
}

.autom8-content {
  padding: 0;
}

.autom8-page-title {
  color: #f8fafc;
  font-size: 30px;
  font-weight: 900;
}

.autom8-kicker {
  color: #22c55e;
  font-size: 12px;
  font-weight: 800;
}

.autom8-card {
  min-height: 126px;
  border: 1px solid rgba(148, 163, 184, 0.18);
  border-radius: 16px;
  background: rgba(15, 23, 42, 0.88);
  padding: 20px;
}

.autom8-card:hover {
  border-color: rgba(56, 189, 248, 0.38);
  background: #111c31;
}

.autom8-card-icon {
  color: #38bdf8;
}

.autom8-card-title {
  color: #94a3b8;
  font-size: 12px;
  font-weight: 700;
}

.autom8-card-value {
  color: #f8fafc;
  font-size: 17px;
  font-weight: 800;
}

.autom8-success {
  border: 1px solid rgba(34, 197, 94, 0.25);
  border-radius: 14px;
  background: rgba(34, 197, 94, 0.08);
  color: #86efac;
  padding: 12px 14px;
}

.autom8-error {
  border: 1px solid rgba(239, 68, 68, 0.28);
  border-radius: 14px;
  background: rgba(239, 68, 68, 0.08);
  color: #fca5a5;
  padding: 12px 14px;
}

.autom8-refresh {
  min-height: 40px;
  border-radius: 12px;
  background: #2563eb;
  color: #ffffff;
  font-weight: 800;
}

.autom8-page {
  padding: 30px 34px 38px;
}

.autom8-hero {
  min-height: 170px;
  padding: 28px 30px;
  border: 1px solid rgba(56, 189, 248, 0.22);
  border-radius: 22px;
  background: linear-gradient(125deg, rgba(37, 99, 235, 0.30), rgba(15, 23, 42, 0.96) 55%, rgba(34, 197, 94, 0.10));
}

.autom8-hero-eyebrow {
  color: #7dd3fc;
  font-size: 11px;
  font-weight: 900;
  letter-spacing: 1px;
}

.autom8-hero-title {
  color: #f8fafc;
  font-size: 32px;
  font-weight: 900;
}

.autom8-hero-copy {
  color: #cbd5e1;
  font-size: 14px;
}

.autom8-online-pill {
  padding: 8px 12px;
  border: 1px solid rgba(34, 197, 94, 0.30);
  border-radius: 999px;
  background: rgba(34, 197, 94, 0.10);
  color: #86efac;
  font-size: 11px;
  font-weight: 900;
}

.autom8-block-title {
  color: #f8fafc;
  font-size: 18px;
  font-weight: 900;
}

.autom8-action-card {
  min-height: 82px;
  padding: 14px 16px;
  border: 1px solid rgba(148, 163, 184, 0.16);
  border-radius: 14px;
  background: #0f172a;
  color: #f8fafc;
  box-shadow: none;
}

.autom8-action-card:hover {
  border-color: rgba(56, 189, 248, 0.40);
  background: #111e34;
}

.autom8-action-title {
  color: #f8fafc;
  font-weight: 800;
}

.autom8-action-copy {
  color: #94a3b8;
  font-size: 11px;
}

.autom8-footer {
  color: #64748b;
  font-size: 11px;
}

.autom8-sidebar-toggle {
  min-width: 36px;
  min-height: 36px;
  border-radius: 10px;
  color: #cbd5e1;
}
"#;

struct StatusCards {
    hostname: gtk::Label,
    distribution: gtk::Label,
    kernel: gtk::Label,
    architecture: gtk::Label,
    desktop: gtk::Label,
    uptime: gtk::Label,
    message: gtk::Label,
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

    let window_title = adw::WindowTitle::new(product.name, product.description);
    let window_bar = adw::HeaderBar::builder()
        .title_widget(&window_title)
        .build();
    window_bar.add_css_class("autom8-window-bar");

    let root = gtk::Box::new(gtk::Orientation::Horizontal, 0);
    root.set_vexpand(true);

    let sidebar = build_sidebar(&product);
    let (main_content, cards, refresh_button) = build_dashboard();

    let sidebar_icon = gtk::Image::from_icon_name("sidebar-hide-symbolic");
    sidebar_icon.set_pixel_size(18);
    let sidebar_toggle = gtk::Button::builder()
        .child(&sidebar_icon)
        .tooltip_text("Recolher menu")
        .build();
    sidebar_toggle.add_css_class("flat");
    sidebar_toggle.add_css_class("autom8-sidebar-toggle");
    window_bar.pack_start(&sidebar_toggle);

    let sidebar_for_toggle = sidebar.clone();
    sidebar_toggle.connect_clicked(move |button| {
        let visible = !sidebar_for_toggle.is_visible();
        sidebar_for_toggle.set_visible(visible);
        sidebar_icon.set_icon_name(Some(if visible {
            "sidebar-hide-symbolic"
        } else {
            "sidebar-show-symbolic"
        }));
        button.set_tooltip_text(Some(if visible {
            "Recolher menu"
        } else {
            "Expandir menu"
        }));
    });

    root.append(&sidebar);
    root.append(&main_content);
    shell.append(&window_bar);
    shell.append(&root);

    let cards = Rc::new(cards);
    let refresh_cards = Rc::clone(&cards);

    refresh_button.connect_clicked(move |_| {
        refresh_status(&refresh_cards);
    });

    refresh_status(&cards);

    let window = adw::ApplicationWindow::builder()
        .application(application)
        .title(product.name)
        .default_width(1180)
        .default_height(760)
        .content(&shell)
        .build();

    window.present();
}

fn build_sidebar(product: &ProductInfo) -> gtk::Box {
    let sidebar = gtk::Box::new(gtk::Orientation::Vertical, 0);
    sidebar.add_css_class("autom8-sidebar");

    let brand = gtk::Box::new(gtk::Orientation::Horizontal, 13);
    brand.set_margin_bottom(18);
    brand.set_margin_start(5);
    brand.set_margin_end(5);

    let logo = brand_logo();
    let brand_text = gtk::Box::new(gtk::Orientation::Vertical, 2);
    brand_text.set_valign(gtk::Align::Center);

    let product_name = gtk::Label::builder()
        .label(product.name)
        .halign(gtk::Align::Start)
        .build();
    product_name.add_css_class("autom8-brand-name");

    let version = gtk::Label::builder()
        .label(format!("{} · {}", product.version, product.description))
        .halign(gtk::Align::Start)
        .build();
    version.add_css_class("autom8-muted");

    brand_text.append(&product_name);
    brand_text.append(&version);
    brand.append(&logo);
    brand.append(&brand_text);
    sidebar.append(&brand);

    let menu_content = gtk::Box::new(gtk::Orientation::Vertical, 0);
    let current_section = RefCell::new(None);

    for item in navigation_items() {
        if *current_section.borrow() != Some(item.section) {
            let section = gtk::Label::builder()
                .label(item.section.title().to_uppercase())
                .halign(gtk::Align::Start)
                .build();
            section.add_css_class("autom8-section");
            menu_content.append(&section);
            current_section.replace(Some(item.section));
        }

        menu_content.append(&navigation_button(item));
    }

    let menu_scroll = gtk::ScrolledWindow::builder()
        .hscrollbar_policy(gtk::PolicyType::Never)
        .vexpand(true)
        .child(&menu_content)
        .build();

    let footer = gtk::Label::builder()
        .label("● Execução local · Sem telemetria")
        .halign(gtk::Align::Start)
        .build();
    footer.add_css_class("autom8-footer");
    footer.set_margin_top(14);

    sidebar.append(&menu_scroll);
    sidebar.append(&footer);
    sidebar
}

fn brand_logo() -> gtk::Picture {
    let picture = gtk::Picture::for_filename(concat!(
        env!("CARGO_MANIFEST_DIR"),
        "/assets/logo-autom8-icon.svg"
    ));

    picture.set_size_request(40, 40);
    picture.set_can_shrink(true);
    picture
}

fn navigation_button(item: &autom8_core::navigation::NavigationItem) -> gtk::Button {
    let content = gtk::Box::new(gtk::Orientation::Horizontal, 10);
    content.set_margin_start(5);
    content.set_margin_end(5);

    let icon = gtk::Image::from_icon_name(item.icon);
    icon.set_pixel_size(18);

    let label = gtk::Label::builder()
        .label(item.title)
        .hexpand(true)
        .halign(gtk::Align::Start)
        .build();

    content.append(&icon);
    content.append(&label);

    if !item.available {
        let badge = gtk::Label::new(Some("EM BREVE"));
        badge.add_css_class("autom8-coming-soon");
        content.append(&badge);
    }

    let button = gtk::Button::builder()
        .child(&content)
        .sensitive(item.available)
        .build();

    button.add_css_class("autom8-menu-button");

    if item.command == "status" {
        button.add_css_class("autom8-menu-button-active");
    }

    button
}

fn build_dashboard() -> (gtk::Box, StatusCards, gtk::Button) {
    let content = gtk::Box::new(gtk::Orientation::Vertical, 0);
    content.add_css_class("autom8-content");
    content.set_hexpand(true);

    let page = gtk::Box::new(gtk::Orientation::Vertical, 0);
    page.add_css_class("autom8-page");

    let hero = gtk::Box::new(gtk::Orientation::Horizontal, 24);
    hero.add_css_class("autom8-hero");
    hero.set_margin_bottom(26);

    let hero_copy = gtk::Box::new(gtk::Orientation::Vertical, 7);
    hero_copy.set_hexpand(true);
    hero_copy.set_valign(gtk::Align::Center);

    let eyebrow = gtk::Label::builder()
        .label("AUTOM8 · LINUX MANAGEMENT SUITE")
        .halign(gtk::Align::Start)
        .build();
    eyebrow.add_css_class("autom8-hero-eyebrow");

    let title = gtk::Label::builder()
        .label("Seu Linux, sob controle.")
        .halign(gtk::Align::Start)
        .build();
    title.add_css_class("autom8-hero-title");

    let description = gtk::Label::builder()
        .label("Gerencie, diagnostique e proteja sua estação com operações locais, previsíveis e seguras.")
        .halign(gtk::Align::Start)
        .wrap(true)
        .max_width_chars(64)
        .build();
    description.add_css_class("autom8-hero-copy");

    hero_copy.append(&eyebrow);
    hero_copy.append(&title);
    hero_copy.append(&description);

    let hero_side = gtk::Box::new(gtk::Orientation::Vertical, 14);
    hero_side.set_valign(gtk::Align::Center);
    hero_side.set_halign(gtk::Align::End);

    let online = gtk::Label::new(Some("● SISTEMA CONECTADO"));
    online.add_css_class("autom8-online-pill");

    let refresh_button = gtk::Button::builder()
        .label("Atualizar status")
        .icon_name("view-refresh-symbolic")
        .valign(gtk::Align::Center)
        .build();
    refresh_button.add_css_class("autom8-refresh");

    hero_side.append(&online);
    hero_side.append(&refresh_button);
    hero.append(&hero_copy);
    hero.append(&hero_side);

    let system_heading = section_heading(
        "Visão geral do sistema",
        "Informações essenciais coletadas localmente nesta estação.",
    );
    system_heading.set_margin_bottom(14);

    let cards_grid = gtk::Grid::builder()
        .column_spacing(14)
        .row_spacing(14)
        .column_homogeneous(true)
        .build();

    let (hostname_card, hostname) = status_card("computer-symbolic", "Hostname");
    let (distribution_card, distribution) =
        status_card("drive-harddisk-system-symbolic", "Distribuição");
    let (desktop_card, desktop) = status_card("video-display-symbolic", "Ambiente gráfico");
    let (kernel_card, kernel) = status_card("utilities-terminal-symbolic", "Kernel");
    let (architecture_card, architecture) = status_card("cpu-symbolic", "Arquitetura");
    let (uptime_card, uptime) = status_card("appointment-soon-symbolic", "Tempo ligado");

    cards_grid.attach(&hostname_card, 0, 0, 1, 1);
    cards_grid.attach(&distribution_card, 1, 0, 1, 1);
    cards_grid.attach(&desktop_card, 2, 0, 1, 1);
    cards_grid.attach(&kernel_card, 0, 1, 1, 1);
    cards_grid.attach(&architecture_card, 1, 1, 1, 1);
    cards_grid.attach(&uptime_card, 2, 1, 1, 1);

    let actions_heading = section_heading(
        "Próximas ferramentas",
        "A fundação visual já está preparada para os próximos módulos.",
    );
    actions_heading.set_margin_top(28);
    actions_heading.set_margin_bottom(14);

    let actions = gtk::Grid::builder()
        .column_spacing(14)
        .column_homogeneous(true)
        .build();
    actions.attach(
        &action_card(
            "system-search-symbolic",
            "Diagnóstico",
            "Verifique a saúde do ambiente",
        ),
        0,
        0,
        1,
        1,
    );
    actions.attach(
        &action_card(
            "system-software-install-symbolic",
            "Aplicativos",
            "Instale programas com segurança",
        ),
        1,
        0,
        1,
        1,
    );
    actions.attach(
        &action_card(
            "security-high-symbolic",
            "Segurança",
            "Fortaleça a proteção local",
        ),
        2,
        0,
        1,
        1,
    );

    let message = gtk::Label::builder()
        .halign(gtk::Align::Fill)
        .xalign(0.0)
        .wrap(true)
        .visible(false)
        .build();
    message.set_margin_top(18);

    page.append(&hero);
    page.append(&system_heading);
    page.append(&cards_grid);
    page.append(&actions_heading);
    page.append(&actions);
    page.append(&message);

    let scrolled = gtk::ScrolledWindow::builder()
        .hscrollbar_policy(gtk::PolicyType::Never)
        .vexpand(true)
        .child(&page)
        .build();

    content.append(&scrolled);

    (
        content,
        StatusCards {
            hostname,
            distribution,
            kernel,
            architecture,
            desktop,
            uptime,
            message,
        },
        refresh_button,
    )
}

fn section_heading(title: &str, copy: &str) -> gtk::Box {
    let heading = gtk::Box::new(gtk::Orientation::Vertical, 3);

    let title = gtk::Label::builder()
        .label(title)
        .halign(gtk::Align::Start)
        .build();
    title.add_css_class("autom8-block-title");

    let copy = gtk::Label::builder()
        .label(copy)
        .halign(gtk::Align::Start)
        .build();
    copy.add_css_class("autom8-muted");

    heading.append(&title);
    heading.append(&copy);
    heading
}

fn action_card(icon_name: &str, title: &str, copy: &str) -> gtk::Button {
    let row = gtk::Box::new(gtk::Orientation::Horizontal, 12);

    let icon = gtk::Image::from_icon_name(icon_name);
    icon.set_pixel_size(22);
    icon.add_css_class("autom8-card-icon");

    let labels = gtk::Box::new(gtk::Orientation::Vertical, 3);
    labels.set_hexpand(true);

    let title = gtk::Label::builder()
        .label(title)
        .halign(gtk::Align::Start)
        .build();
    title.add_css_class("autom8-action-title");

    let copy = gtk::Label::builder()
        .label(copy)
        .halign(gtk::Align::Start)
        .ellipsize(gtk::pango::EllipsizeMode::End)
        .build();
    copy.add_css_class("autom8-action-copy");

    let arrow = gtk::Image::from_icon_name("go-next-symbolic");
    arrow.add_css_class("autom8-muted");

    labels.append(&title);
    labels.append(&copy);
    row.append(&icon);
    row.append(&labels);
    row.append(&arrow);

    let button = gtk::Button::builder().child(&row).sensitive(false).build();
    button.add_css_class("autom8-action-card");
    button
}

fn status_card(icon_name: &str, title: &str) -> (gtk::Box, gtk::Label) {
    let card = gtk::Box::new(gtk::Orientation::Vertical, 9);
    card.add_css_class("autom8-card");
    card.set_hexpand(true);

    let icon = gtk::Image::from_icon_name(icon_name);
    icon.set_pixel_size(24);
    icon.set_halign(gtk::Align::Start);
    icon.add_css_class("autom8-card-icon");

    let title_label = gtk::Label::builder()
        .label(title)
        .halign(gtk::Align::Start)
        .build();
    title_label.add_css_class("autom8-card-title");

    let value = gtk::Label::builder()
        .label("Carregando…")
        .halign(gtk::Align::Start)
        .ellipsize(gtk::pango::EllipsizeMode::End)
        .build();
    value.add_css_class("autom8-card-value");

    card.append(&icon);
    card.append(&title_label);
    card.append(&value);

    (card, value)
}

fn refresh_status(cards: &StatusCards) {
    match SystemStatus::collect() {
        Ok(status) => display_status(cards, &status),
        Err(error) => display_error(cards, &error),
    }
}

fn display_status(cards: &StatusCards, status: &SystemStatus) {
    cards.hostname.set_text(&status.hostname);
    cards.distribution.set_text(&distribution_name(status));
    cards.kernel.set_text(&status.kernel);
    cards.architecture.set_text(&status.architecture);
    cards
        .desktop
        .set_text(status.desktop.as_deref().unwrap_or("Não detectado"));
    cards.uptime.set_text(&format_uptime(status.uptime_seconds));

    cards.message.remove_css_class("autom8-error");
    cards.message.add_css_class("autom8-success");
    cards
        .message
        .set_text("✓ Informações atualizadas com sucesso.");
    cards.message.set_visible(true);
}

fn display_error(cards: &StatusCards, error: &StatusError) {
    cards.message.remove_css_class("autom8-success");
    cards.message.add_css_class("autom8-error");
    cards.message.set_text(&format!(
        "Não foi possível atualizar as informações: {error}"
    ));
    cards.message.set_visible(true);
}

fn distribution_name(status: &SystemStatus) -> String {
    if status.distribution.version.is_empty() {
        status.distribution.name.clone()
    } else {
        format!(
            "{} {}",
            status.distribution.name, status.distribution.version
        )
    }
}

fn format_uptime(total_seconds: u64) -> String {
    let days = total_seconds / 86_400;
    let hours = total_seconds % 86_400 / 3_600;
    let minutes = total_seconds % 3_600 / 60;

    if days > 0 {
        format!("{days}d {hours}h {minutes}min")
    } else if hours > 0 {
        format!("{hours}h {minutes}min")
    } else {
        format!("{minutes}min")
    }
}
