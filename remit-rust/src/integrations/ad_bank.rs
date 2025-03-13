use reqwest::{Client, StatusCode};
use serde::{Deserialize, Serialize};
use std::time::Duration;
use chrono::{DateTime, Utc};
use rust_decimal::Decimal;
use uuid::Uuid;

use crate::config::get_config;
use crate::errors::{AppError, AppResult};
use crate::models::{ConversionDetails, ExchangeRate};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GetRateRequest {
    pub source_currency: String,
    pub destination_currency: String,
    pub client_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GetRateResponse {
    pub source_currency: String,
    pub destination_currency: String,
    pub rate: String,
    pub timestamp: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConvertCurrencyRequest {
    pub source_currency: String,
    pub destination_currency: String,
    pub source_amount: String,
    pub client_id: String,
    pub reference_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConvertCurrencyResponse {
    pub conversion_id: String,
    pub source_currency: String,
    pub destination_currency: String,
    pub source_amount: String,
    pub destination_amount: String,
    pub rate: String,
    pub fees: String,
    pub status: String,
    pub timestamp: DateTime<Utc>,
}

/// Client for AD Bank API
pub struct AdBankClient {
    http_client: Client,
    base_url: String,
    api_key: String,
    client_id: String,
}

impl AdBankClient {
    /// Create a new AD Bank client
    pub fn new() -> Self {
        let config = get_config();
        let timeout = Duration::from_secs(config.currency.ad_bank_timeout_seconds);
        
        let http_client = Client::builder()
            .timeout(timeout)
            .build()
            .unwrap_or_default();
            
        AdBankClient {
            http_client,
            base_url: config.currency.ad_bank_api_endpoint.clone(),
            api_key: config.currency.ad_bank_api_key.clone(),
            client_id: config.currency.ad_bank_client_id.clone(),
        }
    }
    
    /// Get current exchange rate
    pub async fn get_exchange_rate(&self, source_currency: &str, destination_currency: &str) -> AppResult<ExchangeRate> {
        let request = GetRateRequest {
            source_currency: source_currency.to_string(),
            destination_currency: destination_currency.to_string(),
            client_id: self.client_id.clone(),
        };
        
        let url = format!("{}/rates", self.base_url);
        
        let response = self.http_client.post(&url)
            .header("x-api-key", &self.api_key)
            .json(&request)
            .send()
            .await
            .map_err(|e| AppError::CurrencyError(format!("Failed to get exchange rate: {}", e)))?;
            
        match response.status() {
            StatusCode::OK => {
                let rate_response = response.json::<GetRateResponse>()
                    .await
                    .map_err(|e| AppError::CurrencyError(format!("Failed to parse exchange rate response: {}", e)))?;
                
                let rate = rate_response.rate.parse::<Decimal>()
                    .map_err(|e| AppError::CurrencyError(format!("Invalid exchange rate format: {}", e)))?;
                
                let exchange_rate = ExchangeRate::new(
                    source_currency.to_string(),
                    destination_currency.to_string(),
                    rate,
                    "AD Bank".to_string(),
                );
                
                Ok(exchange_rate)
            },
            _ => {
                let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
                Err(AppError::CurrencyError(format!("AD Bank returned error: {}", error_text)))
            }
        }
    }
    
    /// Convert currency
    pub async fn convert_currency(&self, source_currency: &str, destination_currency: &str, source_amount: Decimal) -> AppResult<(ConversionDetails, Decimal, Decimal)> {
        let reference_id = Uuid::new_v4().to_string();
        
        let request = ConvertCurrencyRequest {
            source_currency: source_currency.to_string(),
            destination_currency: destination_currency.to_string(),
            source_amount: source_amount.to_string(),
            client_id: self.client_id.clone(),
            reference_id: reference_id.clone(),
        };
        
        let url = format!("{}/convert", self.base_url);
        
        let response = self.http_client.post(&url)
            .header("x-api-key", &self.api_key)
            .json(&request)
            .send()
            .await
            .map_err(|e| AppError::CurrencyError(format!("Failed to convert currency: {}", e)))?;
            
        match response.status() {
            StatusCode::OK | StatusCode::CREATED => {
                let conversion_response = response.json::<ConvertCurrencyResponse>()
                    .await
                    .map_err(|e| AppError::CurrencyError(format!("Failed to parse conversion response: {}", e)))?;
                
                // Parse decimal values
                let rate = conversion_response.rate.parse::<Decimal>()
                    .map_err(|e| AppError::CurrencyError(format!("Invalid rate format: {}", e)))?;
                    
                let destination_amount = conversion_response.destination_amount.parse::<Decimal>()
                    .map_err(|e| AppError::CurrencyError(format!("Invalid destination amount format: {}", e)))?;
                
                let conversion_details = ConversionDetails {
                    conversion_id: Some(conversion_response.conversion_id),
                    conversion_time: Some(conversion_response.timestamp),
                    actual_exchange_rate: Some(rate),
                    reference_id: Some(reference_id),
                };
                
                Ok((conversion_details, rate, destination_amount))
            },
            _ => {
                let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
                Err(AppError::CurrencyError(format!("AD Bank returned error: {}", error_text)))
            }
        }
    }
} 