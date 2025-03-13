use reqwest::{Client, StatusCode};
use serde::{Deserialize, Serialize};
use std::time::Duration;

use crate::config::get_config;
use crate::errors::{AppError, AppResult};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserDetails {
    pub user_id: String,
    pub name: String,
    pub email: String,
    pub phone: String,
    pub kyc_status: String,
    pub kyc_verified: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecipientDetails {
    pub recipient_id: String,
    pub name: String,
    pub account_holder_name: String,
    pub account_number: String,
    pub bank_name: String,
    pub ifsc_or_swift_code: String,
    pub relationship: String,
}

/// Client for the User Service API
pub struct UserServiceClient {
    http_client: Client,
    base_url: String,
    api_key: String,
}

impl UserServiceClient {
    /// Create a new User Service client
    pub fn new() -> Self {
        let config = get_config();
        let timeout = Duration::from_secs(config.user_service.user_service_timeout_seconds);
        
        let http_client = Client::builder()
            .timeout(timeout)
            .build()
            .unwrap_or_default();
            
        UserServiceClient {
            http_client,
            base_url: config.user_service.user_service_api_endpoint.clone(),
            api_key: config.user_service.user_service_api_key.clone(),
        }
    }
    
    /// Get user details by user ID
    pub async fn get_user(&self, user_id: &str) -> AppResult<UserDetails> {
        let url = format!("{}/users/{}", self.base_url, user_id);
        
        let response = self.http_client.get(&url)
            .header("x-api-key", &self.api_key)
            .send()
            .await
            .map_err(|e| AppError::UserServiceError(format!("Failed to fetch user details: {}", e)))?;
            
        match response.status() {
            StatusCode::OK => {
                let user = response.json::<UserDetails>()
                    .await
                    .map_err(|e| AppError::UserServiceError(format!("Failed to parse user details: {}", e)))?;
                Ok(user)
            },
            StatusCode::NOT_FOUND => {
                Err(AppError::not_found(format!("User not found: {}", user_id)))
            },
            _ => {
                let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
                Err(AppError::UserServiceError(format!("User service returned error: {}", error_text)))
            }
        }
    }
    
    /// Verify if a user is eligible for remittance
    pub async fn verify_eligibility(&self, user_id: &str) -> AppResult<bool> {
        let user = self.get_user(user_id).await?;
        
        // Check if KYC is verified
        if !user.kyc_verified {
            return Err(AppError::validation_error("User KYC not verified"));
        }
        
        // Additional eligibility checks can be added here
        
        Ok(true)
    }
    
    /// Get recipient details by recipient ID
    pub async fn get_recipient(&self, user_id: &str, recipient_id: &str) -> AppResult<RecipientDetails> {
        let url = format!("{}/users/{}/recipients/{}", self.base_url, user_id, recipient_id);
        
        let response = self.http_client.get(&url)
            .header("x-api-key", &self.api_key)
            .send()
            .await
            .map_err(|e| AppError::UserServiceError(format!("Failed to fetch recipient details: {}", e)))?;
            
        match response.status() {
            StatusCode::OK => {
                let recipient = response.json::<RecipientDetails>()
                    .await
                    .map_err(|e| AppError::UserServiceError(format!("Failed to parse recipient details: {}", e)))?;
                Ok(recipient)
            },
            StatusCode::NOT_FOUND => {
                Err(AppError::not_found(format!("Recipient not found: {}", recipient_id)))
            },
            _ => {
                let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
                Err(AppError::UserServiceError(format!("User service returned error: {}", error_text)))
            }
        }
    }
    
    /// List all recipients for a user
    pub async fn list_recipients(&self, user_id: &str) -> AppResult<Vec<RecipientDetails>> {
        let url = format!("{}/users/{}/recipients", self.base_url, user_id);
        
        let response = self.http_client.get(&url)
            .header("x-api-key", &self.api_key)
            .send()
            .await
            .map_err(|e| AppError::UserServiceError(format!("Failed to fetch recipients: {}", e)))?;
            
        match response.status() {
            StatusCode::OK => {
                let recipients = response.json::<Vec<RecipientDetails>>()
                    .await
                    .map_err(|e| AppError::UserServiceError(format!("Failed to parse recipients: {}", e)))?;
                Ok(recipients)
            },
            _ => {
                let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
                Err(AppError::UserServiceError(format!("User service returned error: {}", error_text)))
            }
        }
    }
} 