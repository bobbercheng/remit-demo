use reqwest::{Client, StatusCode};
use serde::{Deserialize, Serialize};
use std::time::Duration;
use chrono::{DateTime, Utc};
use uuid::Uuid;

use crate::config::get_config;
use crate::errors::{AppError, AppResult};
use crate::models::PaymentDetails;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreatePaymentRequest {
    pub amount: String,
    pub currency: String,
    pub description: String,
    pub reference_id: String,
    pub callback_url: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreatePaymentResponse {
    pub payment_id: String,
    pub payment_link: String,
    pub status: String,
    pub expiry_time: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PaymentStatusResponse {
    pub payment_id: String,
    pub status: String,
    pub amount: String,
    pub currency: String,
    pub reference_id: String,
    pub payment_time: Option<DateTime<Utc>>,
    pub upi_transaction_id: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpiWebhookPayload {
    pub payment_id: String,
    pub status: String,
    pub reference_id: String,
    pub payment_time: DateTime<Utc>,
    pub upi_transaction_id: String,
}

/// Enum for payment status
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PaymentStatus {
    Pending,
    Completed,
    Failed,
    Expired,
}

impl From<&str> for PaymentStatus {
    fn from(status: &str) -> Self {
        match status.to_lowercase().as_str() {
            "completed" | "success" => PaymentStatus::Completed,
            "failed" | "failure" => PaymentStatus::Failed,
            "expired" => PaymentStatus::Expired,
            _ => PaymentStatus::Pending,
        }
    }
}

/// Client for UPI Payment Gateway
pub struct UpiClient {
    http_client: Client,
    base_url: String,
    api_key: String,
    callback_url: String,
}

impl UpiClient {
    /// Create a new UPI client
    pub fn new() -> Self {
        let config = get_config();
        let timeout = Duration::from_secs(config.payment.upi_timeout_seconds);
        
        let http_client = Client::builder()
            .timeout(timeout)
            .build()
            .unwrap_or_default();
            
        UpiClient {
            http_client,
            base_url: config.payment.upi_api_endpoint.clone(),
            api_key: config.payment.upi_api_key.clone(),
            callback_url: config.payment.upi_callback_url.clone(),
        }
    }
    
    /// Create a payment request
    pub async fn create_payment(&self, amount: String, description: String) -> AppResult<PaymentDetails> {
        let reference_id = Uuid::new_v4().to_string();
        
        let request = CreatePaymentRequest {
            amount,
            currency: "INR".to_string(),
            description,
            reference_id: reference_id.clone(),
            callback_url: self.callback_url.clone(),
        };
        
        let url = format!("{}/payments", self.base_url);
        
        let response = self.http_client.post(&url)
            .header("x-api-key", &self.api_key)
            .json(&request)
            .send()
            .await
            .map_err(|e| AppError::PaymentError(format!("Failed to create payment: {}", e)))?;
            
        match response.status() {
            StatusCode::CREATED | StatusCode::OK => {
                let payment_response = response.json::<CreatePaymentResponse>()
                    .await
                    .map_err(|e| AppError::PaymentError(format!("Failed to parse payment response: {}", e)))?;
                
                let payment_details = PaymentDetails {
                    payment_id: Some(payment_response.payment_id),
                    payment_link: Some(payment_response.payment_link),
                    payment_time: None,
                    reference_id: Some(reference_id),
                };
                
                Ok(payment_details)
            },
            _ => {
                let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
                Err(AppError::PaymentError(format!("Payment gateway returned error: {}", error_text)))
            }
        }
    }
    
    /// Check payment status
    pub async fn check_status(&self, payment_id: &str) -> AppResult<PaymentStatus> {
        let url = format!("{}/payments/{}", self.base_url, payment_id);
        
        let response = self.http_client.get(&url)
            .header("x-api-key", &self.api_key)
            .send()
            .await
            .map_err(|e| AppError::PaymentError(format!("Failed to check payment status: {}", e)))?;
            
        match response.status() {
            StatusCode::OK => {
                let status_response = response.json::<PaymentStatusResponse>()
                    .await
                    .map_err(|e| AppError::PaymentError(format!("Failed to parse payment status: {}", e)))?;
                
                let status = PaymentStatus::from(status_response.status.as_str());
                Ok(status)
            },
            StatusCode::NOT_FOUND => {
                Err(AppError::not_found(format!("Payment not found: {}", payment_id)))
            },
            _ => {
                let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
                Err(AppError::PaymentError(format!("Payment gateway returned error: {}", error_text)))
            }
        }
    }
    
    /// Process a webhook notification
    pub fn process_webhook(&self, payload: UpiWebhookPayload) -> AppResult<PaymentDetails> {
        // Validate webhook payload
        let status = PaymentStatus::from(payload.status.as_str());
        
        if status != PaymentStatus::Completed {
            return Err(AppError::PaymentError(format!("Payment failed with status: {}", payload.status)));
        }
        
        let payment_details = PaymentDetails {
            payment_id: Some(payload.payment_id),
            payment_link: None,
            payment_time: Some(payload.payment_time),
            reference_id: Some(payload.reference_id),
        };
        
        Ok(payment_details)
    }
} 