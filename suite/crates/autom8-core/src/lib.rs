#![forbid(unsafe_code)]

pub mod bootstrap;
pub mod navigation;
pub mod status;

/// Nome público do produto.
pub const PRODUCT_NAME: &str = "AutoM8";

/// Descrição curta compartilhada pelas interfaces.
pub const PRODUCT_DESCRIPTION: &str = "Linux Management Suite";

/// Identificador da aplicação desktop.
pub const APPLICATION_ID: &str = "br.com.oslabs.AutoM8";

/// Metadados básicos apresentados por todas as interfaces.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ProductInfo {
    pub name: &'static str,
    pub description: &'static str,
    pub version: &'static str,
}

impl ProductInfo {
    #[must_use]
    pub const fn current() -> Self {
        Self {
            name: PRODUCT_NAME,
            description: PRODUCT_DESCRIPTION,
            version: env!("CARGO_PKG_VERSION"),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::{APPLICATION_ID, PRODUCT_DESCRIPTION, PRODUCT_NAME, ProductInfo};

    #[test]
    fn current_product_info_is_complete() {
        let product = ProductInfo::current();

        assert_eq!(product.name, PRODUCT_NAME);
        assert_eq!(product.description, PRODUCT_DESCRIPTION);
        assert!(!product.version.is_empty());
        assert_eq!(APPLICATION_ID, "br.com.oslabs.AutoM8");
    }
}
