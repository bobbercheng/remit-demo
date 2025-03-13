use actix_web::{web, HttpResponse};
use paperclip::actix::{
    api_v2_operation,
    web::Json,
};
use serde_json::to_string;

use crate::errors::{AppError, AppResult};
use crate::integrations::{UpiWebhookPayload, WiseWebhookPayload};
use crate::models::TransactionStatus;
use crate::repositories::TransactionRepository;
use crate::services::RemittanceService;

/// Process UPI payment webhook
#[api_v2_operation(
    summary = "UPI Payment Webhook",
    description = "Receives payment notifications from UPI payment gateway",
    consumes = "application/json",
    produces = "application/json",
    tags(name = "Webhooks"),
)]
pub async fn upi_webhook(
    service: web::Data<RemittanceService>,
    repo: web::Data<TransactionRepository>,
    Json(payload): Json<UpiWebhookPayload>,
) -> AppResult<HttpResponse> {
    // Find transaction by reference_id
    let reference_id = payload.reference_id.clone();
    
    // Query transactions by reference_id is not directly supported,
    // so we need to get all transactions and filter
    let transactions = repo.get_by_status(TransactionStatus::Pending, None).await?;
    
    let transaction = transactions.into_iter()
        .find(|t| {
            t.payment_details.reference_id.as_ref().map_or(false, |r| r == &reference_id)
        })
        .ok_or_else(|| AppError::not_found(format!("Transaction not found for reference_id: {}", reference_id)))?;
    
    // Process the UPI payment
    let payment_details = service
        .upi_client
        .process_webhook(payload)?;
    
    // Update transaction
    service.process_payment(&transaction.transaction_id, payment_details).await?;
    
    Ok(HttpResponse::Ok().json(serde_json::json!({
        "status": "success",
        "message": "Payment webhook processed successfully"
    })))
}

/// Process Wise transfer webhook
#[api_v2_operation(
    summary = "Wise Transfer Webhook",
    description = "Receives transfer notifications from Wise",
    consumes = "application/json",
    produces = "application/json",
    tags(name = "Webhooks"),
)]
pub async fn wise_webhook(
    service: web::Data<RemittanceService>,
    repo: web::Data<TransactionRepository>,
    Json(payload): Json<WiseWebhookPayload>,
) -> AppResult<HttpResponse> {
    // Find transaction by transfer_id
    let transfer_id = payload.transfer_id.clone();
    
    // Query transactions by transfer_id is not directly supported,
    // so we need to get all transactions and filter
    let transactions = repo.get_by_status(TransactionStatus::Transferred, None).await?;
    
    let transaction = transactions.into_iter()
        .find(|t| {
            t.transfer_details.transfer_id.as_ref().map_or(false, |id| id == &transfer_id)
        })
        .ok_or_else(|| AppError::not_found(format!("Transaction not found for transfer_id: {}", transfer_id)))?;
    
    // Process the Wise webhook based on status
    if payload.status.to_lowercase() == "completed" || payload.status.to_lowercase() == "outgoing_payment_sent" {
        // Mark transaction as COMPLETED
        service.complete_transaction(&transaction.transaction_id).await?;
    } else if payload.status.to_lowercase() == "failed" || payload.status.to_lowercase() == "cancelled" {
        // Mark transaction as FAILED
        repo.mark_as_failed(&transaction.transaction_id, &format!("Transfer failed: {}", payload.status)).await?;
    }
    
    Ok(HttpResponse::Ok().json(serde_json::json!({
        "status": "success",
        "message": "Transfer webhook processed successfully"
    })))
}

/// Configure webhook routes
pub fn configure(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope("/webhooks")
            .route("/upi-callback", web::post().to(upi_webhook))
            .route("/wise-callback", web::post().to(wise_webhook)),
    );
} 