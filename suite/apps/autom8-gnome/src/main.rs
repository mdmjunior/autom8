use adw::prelude::*;
use autom8_core::{APPLICATION_ID, ProductInfo};
use gtk::glib;

fn main() -> glib::ExitCode {
    let application = adw::Application::builder()
        .application_id(APPLICATION_ID)
        .build();

    application.connect_activate(build_ui);
    application.run()
}

fn build_ui(application: &adw::Application) {
    let product = ProductInfo::current();
    let window_title = adw::WindowTitle::new(product.name, product.description);
    let header = adw::HeaderBar::builder()
        .title_widget(&window_title)
        .build();
    let status = adw::StatusPage::builder()
        .icon_name("utilities-system-monitor-symbolic")
        .title(product.name)
        .description(format!(
            "Fundação da interface GNOME — versão {}",
            product.version
        ))
        .vexpand(true)
        .build();
    let content = gtk::Box::new(gtk::Orientation::Vertical, 0);

    content.append(&header);
    content.append(&status);

    let window = adw::ApplicationWindow::builder()
        .application(application)
        .title(product.name)
        .default_width(900)
        .default_height(620)
        .content(&content)
        .build();

    window.present();
}
