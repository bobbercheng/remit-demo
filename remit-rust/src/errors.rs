use actix_web::{HttpResponse, ResponseError};
use serde::{Deserialize, Serialize};
use thiserror::Error;

/// AppError is the main error type for our application
#[derive(Debug, Error)]
pub enum AppError {
    #[error("Validation error: {0}")]
    ValidationError(String),
    
    #[error("User service error: {0}")]
    UserServiceError(String),
    
    #[error("Payment error: {0}")]
    PaymentError(String),
    
    #[error("Currency conversion error: {0}")]
    CurrencyError(String),
    
    #[error("Transfer error: {0}")]
    TransferError(String),
    
    #[error("Database error: {0}")]
    DatabaseError(String),
    
    #[error("Configuration error: {0}")]
    ConfigError(String),
    
    #[error("Transaction not found: {0}")]
    NotFoundError(String),
    
    #[error("Transaction in invalid state: current={current}, expected={expected}")]
    InvalidStateError { current: String, expected: String },
    
    #[error("External service error: {0}")]
    ExternalServiceError(String),
    
    #[error("Internal server error: {0}")]
    InternalError(String),
}

/// ErrorResponse is the structure we return to clients on error
#[derive(Serialize, Deserialize)]
pub struct ErrorResponse {
    pub status: String,
    pub message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error_code: Option<String>,
}

impl ResponseError for AppError {
    fn error_response(&self) -> HttpResponse {
        match self {
            AppError::ValidationError(_) => {
                HttpResponse::BadRequest().json(self.to_error_response("400"))
            }
            AppError::NotFoundError(_) => {
                HttpResponse::NotFound().json(self.to_error_response("404"))
            }
            AppError::InvalidStateError { .. } => {
                HttpResponse::UnprocessableEntity().json(self.to_error_response("422"))
            }
            AppError::UserServiceError(_)
            | AppError::PaymentError(_)
            | AppError::CurrencyError(_)
            | AppError::TransferError(_)
            | AppError::ExternalServiceError(_) => {
                HttpResponse::BadGateway().json(self.to_error_response("502"))
            }
            _ => HttpResponse::InternalServerError().json(self.to_error_response("500")),
        }
    }
}

impl AppError {
    fn to_error_response(&self, code: &str) -> ErrorResponse {
        ErrorResponse {
            status: "error".to_string(),
            message: self.to_string(),
            error_code: Some(code.to_string()),
        }
    }
    
    pub fn validation_error(message: impl Into<String>) -> Self {
        AppError::ValidationError(message.into())
    }
    
    pub fn not_found(message: impl Into<String>) -> Self {
        AppError::NotFoundError(message.into())
    }
    
    pub fn invalid_state(current: impl Into<String>, expected: impl Into<String>) -> Self {
        AppError::InvalidStateError {
            current: current.into(),
            expected: expected.into(),
        }
    }
    
    pub fn database_error(message: impl Into<String>) -> Self {
        AppError::DatabaseError(message.into())
    }
    
    pub fn internal_error(message: impl Into<String>) -> Self {
        AppError::InternalError(message.into())
    }
}

/// Convenient Result type alias for our application
pub type AppResult<T> = Result<T, AppError>; 