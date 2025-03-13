use reqwest::{Client, StatusCode};
use serde::{Deserialize, Serialize};
use std::time::Duration;
use chrono::{DateTime, Utc};
use uuid::Uuid;

use crate::config::get_config;
use crate::errors::{AppError, AppResult};
use crate::models::{BankAccountDetails, TransferDetails};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecipientAccountRequest {
    pub profile_id: String,
    pub account_holder_name: String,
    pub currency: String,
    pub account_number: String,
    pub bank_code: String,
    pub bank_name: String,
    pub country: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecipientAccountResponse {
    pub id: String,
    pub profile_id: String,
    pub account_holder_name: String,
    pub currency: String,
    pub country: String,
    pub status: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateTransferRequest {
    pub source_currency: String,
    pub source_amount: String,
    pub target_currency: String,
    pub target_account_id: String,
    pub profile_id: String,
    pub reference: String,
    pub payment_purpose: String,
    pub quote_id: Option<String>,
    pub customer_transaction_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateTransferResponse {
    pub id: String,
    pub source_currency: String,
    pub source_amount: String,
    pub target_currency: String,
    pub target_amount: String,
    pub status: String,
    pub created_at: DateTime<Utc>,
    pub estimated_delivery: Option<DateTime<Utc>>,
    pub tracking_url: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TransferStatusResponse {
    pub id: String,
    pub status: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub error_code: Option<String>,
    pub error_message: Option<String>,
    pub tracking_url: Option<String>,
    pub estimated_delivery: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WiseWebhookPayload {
    pub event_type: String,
    pub transfer_id: String,
    pub status: String,
    pub timestamp: DateTime<Utc>,
    pub tracking_url: Option<String>,
    pub estimated_delivery: Option<DateTime<Utc>>,
}

/// Enum for transfer status
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum TransferStatus {
    Processing,
    Completed,
    Failed,
    Cancelled,
}

impl From<&str> for TransferStatus {
    fn from(status: &str) -> Self {
        match status.to_lowercase().as_str() {
            "completed" | "outgoing_payment_sent" => TransferStatus::Completed,
            "failed" | "outgoing_payment_failed" => TransferStatus::Failed,
            "cancelled" | "outgoing_payment_cancelled" => TransferStatus::Cancelled,
            _ => TransferStatus::Processing,
        }
    }
}

/// Client for Wise API
pub struct WiseClient {
    http_client: Client,
    base_url: String,
    api_key: String,
    profile_id: String,
    callback_url: String,
}

impl WiseClient {
    /// Create a new Wise client
    pub fn new() -> Self {
        let config = get_config();
        let timeout = Duration::from_secs(config.transfer.wise_timeout_seconds);
        
        let http_client = Client::builder()
            .timeout(timeout)
            .build()
            .unwrap_or_default();
            
        WiseClient {
            http_client,
            base_url: config.transfer.wise_api_endpoint.clone(),
            api_key: config.transfer.wise_api_key.clone(),
            profile_id: config.transfer.wise_profile_id.clone(),
            callback_url: config.transfer.wise_callback_url.clone(),
        }
    }
    
    /// Create a recipient account
    async fn create_recipient_account(&self, bank_details: &BankAccountDetails) -> AppResult<String> {
        let request = RecipientAccountRequest {
            profile_id: self.profile_id.clone(),
            account_holder_name: bank_details.account_holder_name.clone(),
            currency: "CAD".to_string(),
            account_number: bank_details.account_number.clone(),
            bank_code: bank_details.ifsc_or_swift_code.clone(),
            bank_name: bank_details.bank_name.clone(),
            country: "CA".to_string(),
        };
        
        let url = format!("{}/accounts", self.base_url);
        
        let response = self.http_client.post(&url)
            .header("Authorization", format!("Bearer {}", self.api_key))
            .json(&request)
            .send()
            .await
            .map_err(|e| AppError::TransferError(format!("Failed to create recipient account: {}", e)))?;
            
        match response.status() {
            StatusCode::OK | StatusCode::CREATED => {
                let account_response = response.json::<RecipientAccountResponse>()
                    .await
                    .map_err(|e| AppError::TransferError(format!("Failed to parse account response: {}", e)))?;
                
                Ok(account_response.id)
            },
            _ => {
                let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
                Err(AppError::TransferError(format!("Wise returned error: {}", error_text)))
            }
        }
    }
    
    /// Initiate a transfer to Canada
    pub async fn transfer_funds(
        &self,
        source_currency: &str,
        source_amount: &str,
        bank_details: &BankAccountDetails,
        description: &str,
    ) -> AppResult<TransferDetails> {
        // First create a recipient account
        let target_account_id = self.create_recipient_account(bank_details).await?;
        
        let reference_id = Uuid::new_v4().to_string();
        
        let request = CreateTransferRequest {
            source_currency: source_currency.to_string(),
            source_amount: source_amount.to_string(),
            target_currency: "CAD".to_string(),
            target_account_id,
            profile_id: self.profile_id.clone(),
            reference: description.to_string(),
            payment_purpose: "remittance".to_string(),
            quote_id: None,
            customer_transaction_id: reference_id.clone(),
        };
        
        let url = format!("{}/transfers", self.base_url);
        
        let response = self.http_client.post(&url)
            .header("Authorization", format!("Bearer {}", self.api_key))
            .json(&request)
            .send()
            .await
            .map_err(|e| AppError::TransferError(format!("Failed to create transfer: {}", e)))?;
            
        match response.status() {
            StatusCode::OK | StatusCode::CREATED => {
                let transfer_response = response.json::<CreateTransferResponse>()
                    .await
                    .map_err(|e| AppError::TransferError(format!("Failed to parse transfer response: {}", e)))?;
                
                let transfer_details = TransferDetails {
                    transfer_id: Some(transfer_response.id),
                    transfer_time: Some(transfer_response.created_at),
                    tracking_url: transfer_response.tracking_url,
                    estimated_delivery: transfer_response.estimated_delivery,
                    reference_id: Some(reference_id),
                };
                
                Ok(transfer_details)
            },
            _ => {
                let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
                Err(AppError::TransferError(format!("Wise returned error: {}", error_text)))
            }
        }
    }
    
    /// Check transfer status
    pub async fn check_status(&self, transfer_id: &str) -> AppResult<TransferStatus> {
        let url = format!("{}/transfers/{}", self.base_url, transfer_id);
        
        let response = self.http_client.get(&url)
            .header("Authorization", format!("Bearer {}", self.api_key))
            .send()
            .await
            .map_err(|e| AppError::TransferError(format!("Failed to check transfer status: {}", e)))?;
            
        match response.status() {
            StatusCode::OK => {
                let status_response = response.json::<TransferStatusResponse>()
                    .await
                    .map_err(|e| AppError::TransferError(format!("Failed to parse transfer status: {}", e)))?;
                
                let status = TransferStatus::from(status_response.status.as_str());
                
                // If failed, include error message in the error
                if status == TransferStatus::Failed && status_response.error_message.is_some() {
                    return Err(AppError::TransferError(format!(
                        "Transfer failed: {}", 
                        status_response.error_message.unwrap_or_default()
                    )));
                }
                
                Ok(status)
            },
            StatusCode::NOT_FOUND => {
                Err(AppError::not_found(format!("Transfer not found: {}", transfer_id)))
            },
            _ => {
                let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
                Err(AppError::TransferError(format!("Wise returned error: {}", error_text)))
            }
        }
    }
    
    /// Process a webhook notification
    pub fn process_webhook(&self, payload: WiseWebhookPayload) -> AppResult<TransferDetails> {
        // Validate webhook payload
        let status = TransferStatus::from(payload.status.as_str());
        
        if status == TransferStatus::Failed {
            return Err(AppError::TransferError(format!("Transfer failed with status: {}", payload.status)));
        }
        
        let transfer_details = TransferDetails {
            transfer_id: Some(payload.transfer_id),
            transfer_time: Some(payload.timestamp),
            tracking_url: payload.tracking_url,
            estimated_delivery: payload.estimated_delivery,
            reference_id: None, // Webhook doesn't provide reference_id
        };
        
        Ok(transfer_details)
    }
} 