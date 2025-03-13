pub mod remittance;
pub mod webhooks;

pub fn configure(cfg: &mut actix_web::web::ServiceConfig) {
    remittance::configure(cfg);
    webhooks::configure(cfg);
} 