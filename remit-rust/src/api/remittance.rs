use actix_web::{web, HttpResponse};
use paperclip::actix::{
    api_v2_operation,
    web::{Json, Path, Query},
};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use validator::Validate;

use crate::errors::{AppError, AppResult};
use crate::models::{Transaction, TransactionStatus, BankAccountDetails};
use crate::services::RemittanceService;

#[derive(Debug, Serialize, Deserialize, Validate)]
pub struct CreateTransactionRequest {
    #[validate(length(min = 1, max = 50))]
    pub user_id: String,
    
    #[validate(range(min = 1000, max = 1_000_000))]
    pub source_amount: Decimal,
    
    #[validate(length(min = 1, max = 50))]
    pub recipient_id: String,
    
    #[validate(length(min = 0, max = 500))]
    pub notes: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct EstimateExchangeRequest {
    pub source_amount: Decimal,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct EstimateExchangeResponse {
    pub source_amount: Decimal,
    pub source_currency: String,
    pub destination_amount: Decimal,
    pub destination_currency: String,
    pub exchange_rate: Decimal,
    pub fee: Decimal,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct InitiatePaymentResponse {
    pub transaction_id: String,
    pub payment_link: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TransactionListResponse {
    pub transactions: Vec<Transaction>,
    pub total: usize,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TransactionListQuery {
    pub page: Option<usize>,
    pub limit: Option<usize>,
    pub status: Option<String>,
}

/// Create a new remittance transaction
#[api_v2_operation(
    summary = "Create a new remittance transaction",
    description = "Creates a new transaction for remitting money from India to Canada",
    consumes = "application/json",
    produces = "application/json",
    tags(name = "Remittance"),
)]
pub async fn create_transaction(
    service: web::Data<RemittanceService>,
    Json(request): Json<CreateTransactionRequest>,
) -> AppResult<HttpResponse> {
    // Validate request
    request.validate()
        .map_err(|e| AppError::validation_error(format!("Invalid request: {}", e)))?;
    
    // Create transaction
    let transaction = service.create_transaction(
        request.user_id,
        request.source_amount,
        request.recipient_id,
        request.notes,
    ).await?;
    
    Ok(HttpResponse::Created().json(transaction))
}

/// Get a transaction by ID
#[api_v2_operation(
    summary = "Get transaction details",
    description = "Gets details of a specific remittance transaction",
    consumes = "application/json",
    produces = "application/json",
    tags(name = "Remittance"),
)]
pub async fn get_transaction(
    service: web::Data<RemittanceService>,
    Path(transaction_id): Path<String>,
) -> AppResult<HttpResponse> {
    let transaction = service.get_transaction(&transaction_id).await?;
    Ok(HttpResponse::Ok().json(transaction))
}

/// Get transactions for a user
#[api_v2_operation(
    summary = "Get user transactions",
    description = "Gets all remittance transactions for a specific user",
    consumes = "application/json",
    produces = "application/json",
    tags(name = "Remittance"),
)]
pub async fn get_user_transactions(
    service: web::Data<RemittanceService>,
    Path(user_id): Path<String>,
    Query(query): Query<TransactionListQuery>,
) -> AppResult<HttpResponse> {
    let limit = query.limit.map(|l| l as i32).or(Some(50));
    let transactions = service.get_user_transactions(&user_id, limit).await?;
    
    let response = TransactionListResponse {
        total: transactions.len(),
        transactions,
    };
    
    Ok(HttpResponse::Ok().json(response))
}

/// Initiate payment for a transaction
#[api_v2_operation(
    summary = "Initiate payment",
    description = "Initiates UPI payment for an existing transaction",
    consumes = "application/json",
    produces = "application/json",
    tags(name = "Remittance"),
)]
pub async fn initiate_payment(
    service: web::Data<RemittanceService>,
    Path(transaction_id): Path<String>,
) -> AppResult<HttpResponse> {
    let payment_link = service.initiate_payment(&transaction_id).await?;
    
    let response = InitiatePaymentResponse {
        transaction_id,
        payment_link,
    };
    
    Ok(HttpResponse::Ok().json(response))
}

/// Estimate exchange rate and destination amount
#[api_v2_operation(
    summary = "Estimate exchange",
    description = "Estimates the exchange rate and destination amount for a given source amount",
    consumes = "application/json",
    produces = "application/json",
    tags(name = "Remittance"),
)]
pub async fn estimate_exchange(
    service: web::Data<RemittanceService>,
    Json(request): Json<EstimateExchangeRequest>,
) -> AppResult<HttpResponse> {
    let source_amount = request.source_amount;
    let fee = service.calculate_fee(source_amount);
    let (destination_amount, exchange_rate) = service.calculate_destination_amount(source_amount).await?;
    
    let response = EstimateExchangeResponse {
        source_amount,
        source_currency: "INR".to_string(),
        destination_amount,
        destination_currency: "CAD".to_string(),
        exchange_rate,
        fee,
    };
    
    Ok(HttpResponse::Ok().json(response))
}

/// Check transaction status
#[api_v2_operation(
    summary = "Check transaction status",
    description = "Checks the current status of a transaction and updates it if needed",
    consumes = "application/json",
    produces = "application/json",
    tags(name = "Remittance"),
)]
pub async fn check_transaction_status(
    service: web::Data<RemittanceService>,
    Path(transaction_id): Path<String>,
) -> AppResult<HttpResponse> {
    let transaction = service.get_transaction(&transaction_id).await?;
    
    // Check status based on current state
    match transaction.status {
        TransactionStatus::Pending => {
            let status = service.check_payment_status(&transaction_id).await?;
            let updated_transaction = service.get_transaction(&transaction_id).await?;
            Ok(HttpResponse::Ok().json(updated_transaction))
        },
        TransactionStatus::Transferred => {
            let status = service.check_transfer_status(&transaction_id).await?;
            let updated_transaction = service.get_transaction(&transaction_id).await?;
            Ok(HttpResponse::Ok().json(updated_transaction))
        },
        _ => {
            Ok(HttpResponse::Ok().json(transaction))
        }
    }
}

/// Configure remittance routes
pub fn configure(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope("/remittance")
            .route("", web::post().to(create_transaction))
            .route("/estimate", web::post().to(estimate_exchange))
            .route("/{transaction_id}", web::get().to(get_transaction))
            .route("/{transaction_id}/payment", web::post().to(initiate_payment))
            .route("/{transaction_id}/status", web::get().to(check_transaction_status))
            .route("/user/{user_id}", web::get().to(get_user_transactions)),
    );
} 