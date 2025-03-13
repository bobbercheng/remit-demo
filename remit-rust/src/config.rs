use config::{Config, ConfigError, Environment, File};
use serde::Deserialize;
use std::env;

/// AppConfig holds all the configuration settings for the application
#[derive(Debug, Deserialize, Clone)]
pub struct AppConfig {
    pub server: ServerConfig,
    pub database: DatabaseConfig,
    pub payment: PaymentConfig,
    pub currency: CurrencyConfig,
    pub transfer: TransferConfig,
    pub user_service: UserServiceConfig,
    pub business_rules: BusinessRulesConfig,
}

#[derive(Debug, Deserialize, Clone)]
pub struct ServerConfig {
    pub host: String,
    pub port: u16,
    pub workers: usize,
    pub log_level: String,
}

#[derive(Debug, Deserialize, Clone)]
pub struct DatabaseConfig {
    pub dynamodb_endpoint: String,
    pub region: String,
    pub access_key_id: String,
    pub secret_access_key: String,
    pub transactions_table: String,
    pub exchange_rates_table: String,
}

#[derive(Debug, Deserialize, Clone)]
pub struct PaymentConfig {
    pub upi_api_endpoint: String,
    pub upi_api_key: String,
    pub upi_callback_url: String,
    pub upi_timeout_seconds: u64,
}

#[derive(Debug, Deserialize, Clone)]
pub struct CurrencyConfig {
    pub ad_bank_api_endpoint: String,
    pub ad_bank_api_key: String,
    pub ad_bank_client_id: String,
    pub ad_bank_timeout_seconds: u64,
}

#[derive(Debug, Deserialize, Clone)]
pub struct TransferConfig {
    pub wise_api_endpoint: String,
    pub wise_api_key: String,
    pub wise_profile_id: String,
    pub wise_callback_url: String,
    pub wise_timeout_seconds: u64,
}

#[derive(Debug, Deserialize, Clone)]
pub struct UserServiceConfig {
    pub user_service_api_endpoint: String,
    pub user_service_api_key: String,
    pub user_service_timeout_seconds: u64,
}

#[derive(Debug, Deserialize, Clone)]
pub struct BusinessRulesConfig {
    pub min_transaction_amount_inr: u64,
    pub max_transaction_amount_inr: u64,
    pub fee_percentage: f64,
    pub min_fee_inr: u64,
    pub exchange_rate_cache_seconds: u64,
    pub transaction_expiry_hours: u64,
}

impl AppConfig {
    /// Load configuration from the specified environment
    /// Loads default.toml first, then environment-specific config, then environment variables
    pub fn load() -> Result<Self, ConfigError> {
        let run_mode = env::var("RUN_MODE").unwrap_or_else(|_| "development".into());

        let config = Config::builder()
            // Start with defaults
            .add_source(File::with_name("config/default"))
            // Add environment specific config
            .add_source(File::with_name(&format!("config/{}", run_mode)).required(false))
            // Add environment variables with prefix REMIT
            .add_source(Environment::with_prefix("REMIT").separator("__"))
            .build()?;

        config.try_deserialize()
    }
}

/// Get a singleton instance of AppConfig
pub fn get_config() -> AppConfig {
    static mut CONFIG: Option<AppConfig> = None;
    
    unsafe {
        if CONFIG.is_none() {
            CONFIG = Some(AppConfig::load().expect("Failed to load configuration"));
        }
        CONFIG.clone().unwrap()
    }
} 