use rust_decimal::Decimal;
use serde_json::to_string;
use validator::Validate;

use crate::config::get_config;
use crate::errors::{AppError, AppResult};
use crate::integrations::{
    UserServiceClient, UpiClient, PaymentStatus,
    AdBankClient, WiseClient, TransferStatus,
};
use crate::models::{
    Transaction, TransactionStatus, BankAccountDetails,
    PaymentDetails, ConversionDetails, TransferDetails,
};
use crate::repositories::{TransactionRepository, ExchangeRateRepository};

/// Service for handling the remittance flow
pub struct RemittanceService {
    transaction_repo: TransactionRepository,
    exchange_rate_repo: ExchangeRateRepository,
    user_service: UserServiceClient,
    upi_client: UpiClient,
    ad_bank_client: AdBankClient,
    wise_client: WiseClient,
}

impl RemittanceService {
    /// Create a new remittance service
    pub fn new(
        transaction_repo: TransactionRepository,
        exchange_rate_repo: ExchangeRateRepository,
    ) -> Self {
        RemittanceService {
            transaction_repo,
            exchange_rate_repo,
            user_service: UserServiceClient::new(),
            upi_client: UpiClient::new(),
            ad_bank_client: AdBankClient::new(),
            wise_client: WiseClient::new(),
        }
    }
    
    /// Calculate fee for a remittance transaction
    fn calculate_fee(&self, amount: Decimal) -> Decimal {
        let config = get_config();
        let fee_percentage = Decimal::from_f64(config.business_rules.fee_percentage).unwrap_or(Decimal::new(5, 1)); // Default 0.5%
        let min_fee = Decimal::from_u64(config.business_rules.min_fee_inr).unwrap_or(Decimal::new(100, 0)); // Default 100 INR
        
        let calculated_fee = amount * fee_percentage / Decimal::new(100, 0);
        if calculated_fee < min_fee {
            min_fee
        } else {
            calculated_fee
        }
    }
    
    /// Create a new remittance transaction
    pub async fn create_transaction(
        &self,
        user_id: String,
        source_amount: Decimal,
        recipient_id: String,
        notes: Option<String>,
    ) -> AppResult<Transaction> {
        // Validate amount
        let config = get_config();
        let min_amount = Decimal::from_u64(config.business_rules.min_transaction_amount_inr).unwrap_or(Decimal::new(1000, 0));
        let max_amount = Decimal::from_u64(config.business_rules.max_transaction_amount_inr).unwrap_or(Decimal::new(1000000, 0));
        
        if source_amount < min_amount {
            return Err(AppError::validation_error(format!(
                "Transaction amount must be at least {} INR", min_amount
            )));
        }
        
        if source_amount > max_amount {
            return Err(AppError::validation_error(format!(
                "Transaction amount cannot exceed {} INR", max_amount
            )));
        }
        
        // Verify user eligibility
        self.user_service.verify_eligibility(&user_id).await?;
        
        // Get recipient details
        let recipient = self.user_service.get_recipient(&user_id, &recipient_id).await?;
        
        // Create bank account details from recipient
        let bank_account_details = BankAccountDetails {
            bank_name: recipient.bank_name,
            account_number: recipient.account_number,
            account_holder_name: recipient.account_holder_name,
            ifsc_or_swift_code: recipient.ifsc_or_swift_code,
        };
        
        // Calculate fee
        let fee = self.calculate_fee(source_amount);
        
        // Create transaction
        let transaction = Transaction::new(
            user_id,
            source_amount,
            recipient_id,
            bank_account_details,
            notes,
            fee,
        );
        
        // Validate transaction
        transaction.validate()
            .map_err(|e| AppError::validation_error(format!("Invalid transaction: {}", e)))?;
        
        // Save transaction
        self.transaction_repo.save(&transaction).await?;
        
        Ok(transaction)
    }
    
    /// Get transaction by ID
    pub async fn get_transaction(&self, transaction_id: &str) -> AppResult<Transaction> {
        self.transaction_repo.get_by_id(transaction_id).await
    }
    
    /// Get transactions for a user
    pub async fn get_user_transactions(&self, user_id: &str, limit: Option<i32>) -> AppResult<Vec<Transaction>> {
        self.transaction_repo.get_by_user_id(user_id, limit).await
    }
    
    /// Initiate payment for a transaction
    pub async fn initiate_payment(&self, transaction_id: &str) -> AppResult<String> {
        // Get transaction
        let transaction = self.transaction_repo.get_by_id(transaction_id).await?;
        
        // Verify transaction status
        if transaction.status != TransactionStatus::Pending {
            return Err(AppError::invalid_state(
                transaction.status.to_string(),
                TransactionStatus::Pending.to_string(),
            ));
        }
        
        // Calculate total amount (including fee)
        let total_amount = transaction.source_amount + transaction.fees;
        
        // Create payment description
        let description = format!(
            "Remittance to {} ({})",
            transaction.recipient_account_details.account_holder_name,
            transaction.transaction_id
        );
        
        // Initiate UPI payment
        let payment_details = self.upi_client.create_payment(
            total_amount.to_string(),
            description,
        ).await?;
        
        // Update transaction with payment details
        let payment_details_json = to_string(&payment_details)
            .map_err(|e| AppError::internal_error(format!("Failed to serialize payment details: {}", e)))?;
            
        self.transaction_repo.update_payment_details(transaction_id, &payment_details_json).await?;
        
        // Return payment link for user to complete payment
        payment_details.payment_link.ok_or_else(|| AppError::internal_error("Payment link not available".to_string()))
    }
    
    /// Process payment completion
    pub async fn process_payment(&self, transaction_id: &str, payment_details: PaymentDetails) -> AppResult<Transaction> {
        // Get transaction
        let transaction = self.transaction_repo.get_by_id(transaction_id).await?;
        
        // Verify transaction status
        if transaction.status != TransactionStatus::Pending {
            return Err(AppError::invalid_state(
                transaction.status.to_string(),
                TransactionStatus::Pending.to_string(),
            ));
        }
        
        // Update transaction with payment details
        let payment_details_json = to_string(&payment_details)
            .map_err(|e| AppError::internal_error(format!("Failed to serialize payment details: {}", e)))?;
            
        let transaction = self.transaction_repo.update_payment_details(transaction_id, &payment_details_json).await?;
        
        // Update transaction status to FUNDED
        let transaction = self.transaction_repo.update_status(transaction_id, TransactionStatus::Funded).await?;
        
        // Trigger currency conversion (can be done asynchronously)
        // For now, we'll do it synchronously
        self.process_currency_conversion(transaction_id).await?;
        
        // Return updated transaction
        self.transaction_repo.get_by_id(transaction_id).await
    }
    
    /// Process currency conversion
    pub async fn process_currency_conversion(&self, transaction_id: &str) -> AppResult<Transaction> {
        // Get transaction
        let transaction = self.transaction_repo.get_by_id(transaction_id).await?;
        
        // Verify transaction status
        if transaction.status != TransactionStatus::Funded {
            return Err(AppError::invalid_state(
                transaction.status.to_string(),
                TransactionStatus::Funded.to_string(),
            ));
        }
        
        // Perform currency conversion via AD Bank
        let source_amount = transaction.source_amount;
        let (conversion_details, exchange_rate, destination_amount) = self.ad_bank_client
            .convert_currency(&transaction.source_currency, &transaction.destination_currency, source_amount)
            .await?;
            
        // Update transaction with conversion details
        let conversion_details_json = to_string(&conversion_details)
            .map_err(|e| AppError::internal_error(format!("Failed to serialize conversion details: {}", e)))?;
            
        let transaction = self.transaction_repo.update_conversion_details(
            transaction_id,
            &conversion_details_json,
            &exchange_rate.to_string(),
            &destination_amount.to_string(),
        ).await?;
        
        // Update transaction status to CONVERTED
        let transaction = self.transaction_repo.update_status(transaction_id, TransactionStatus::Converted).await?;
        
        // Trigger transfer (can be done asynchronously)
        // For now, we'll do it synchronously
        self.process_transfer(transaction_id).await?;
        
        // Return updated transaction
        self.transaction_repo.get_by_id(transaction_id).await
    }
    
    /// Process transfer to Canada
    pub async fn process_transfer(&self, transaction_id: &str) -> AppResult<Transaction> {
        // Get transaction
        let transaction = self.transaction_repo.get_by_id(transaction_id).await?;
        
        // Verify transaction status
        if transaction.status != TransactionStatus::Converted {
            return Err(AppError::invalid_state(
                transaction.status.to_string(),
                TransactionStatus::Converted.to_string(),
            ));
        }
        
        // Create description
        let description = if let Some(ref notes) = transaction.notes {
            format!("Remittance: {}", notes)
        } else {
            "Remittance".to_string()
        };
        
        // Initiate transfer via Wise
        let transfer_details = self.wise_client.transfer_funds(
            &transaction.source_currency,
            &transaction.destination_amount.unwrap_or_default().to_string(),
            &transaction.recipient_account_details,
            &description,
        ).await?;
        
        // Update transaction with transfer details
        let transfer_details_json = to_string(&transfer_details)
            .map_err(|e| AppError::internal_error(format!("Failed to serialize transfer details: {}", e)))?;
            
        self.transaction_repo.update_transfer_details(transaction_id, &transfer_details_json).await?;
        
        // Update transaction status to TRANSFERRED
        let transaction = self.transaction_repo.update_status(transaction_id, TransactionStatus::Transferred).await?;
        
        // Return updated transaction
        Ok(transaction)
    }
    
    /// Complete a transaction (called when funds are confirmed in recipient account)
    pub async fn complete_transaction(&self, transaction_id: &str) -> AppResult<Transaction> {
        // Get transaction
        let transaction = self.transaction_repo.get_by_id(transaction_id).await?;
        
        // Verify transaction status
        if transaction.status != TransactionStatus::Transferred {
            return Err(AppError::invalid_state(
                transaction.status.to_string(),
                TransactionStatus::Transferred.to_string(),
            ));
        }
        
        // Update transaction status to COMPLETED
        let transaction = self.transaction_repo.update_status(transaction_id, TransactionStatus::Completed).await?;
        
        // Return updated transaction
        Ok(transaction)
    }
    
    /// Check payment status manually
    pub async fn check_payment_status(&self, transaction_id: &str) -> AppResult<TransactionStatus> {
        // Get transaction
        let transaction = self.transaction_repo.get_by_id(transaction_id).await?;
        
        // If already past PENDING, nothing to do
        if transaction.status != TransactionStatus::Pending {
            return Ok(transaction.status);
        }
        
        // Get payment ID
        let payment_id = transaction.payment_details.payment_id
            .clone()
            .ok_or_else(|| AppError::internal_error("Payment ID not found".to_string()))?;
            
        // Check payment status
        let payment_status = self.upi_client.check_status(&payment_id).await?;
        
        match payment_status {
            PaymentStatus::Completed => {
                // Update transaction status to FUNDED
                self.transaction_repo.update_status(transaction_id, TransactionStatus::Funded).await?;
                
                // Trigger currency conversion (can be done asynchronously)
                // For now, we'll do it synchronously
                self.process_currency_conversion(transaction_id).await?;
                
                Ok(TransactionStatus::Funded)
            },
            PaymentStatus::Failed => {
                // Mark transaction as failed
                self.transaction_repo.mark_as_failed(transaction_id, "Payment failed").await?;
                Ok(TransactionStatus::Failed)
            },
            PaymentStatus::Expired => {
                // Mark transaction as failed
                self.transaction_repo.mark_as_failed(transaction_id, "Payment expired").await?;
                Ok(TransactionStatus::Failed)
            },
            _ => Ok(TransactionStatus::Pending),
        }
    }
    
    /// Check transfer status manually
    pub async fn check_transfer_status(&self, transaction_id: &str) -> AppResult<TransactionStatus> {
        // Get transaction
        let transaction = self.transaction_repo.get_by_id(transaction_id).await?;
        
        // If not in TRANSFERRED status, nothing to do
        if transaction.status != TransactionStatus::Transferred {
            return Ok(transaction.status);
        }
        
        // Get transfer ID
        let transfer_id = transaction.transfer_details.transfer_id
            .clone()
            .ok_or_else(|| AppError::internal_error("Transfer ID not found".to_string()))?;
            
        // Check transfer status
        let transfer_status = self.wise_client.check_status(&transfer_id).await?;
        
        match transfer_status {
            TransferStatus::Completed => {
                // Update transaction status to COMPLETED
                self.transaction_repo.update_status(transaction_id, TransactionStatus::Completed).await?;
                Ok(TransactionStatus::Completed)
            },
            TransferStatus::Failed => {
                // Mark transaction as failed
                self.transaction_repo.mark_as_failed(transaction_id, "Transfer failed").await?;
                Ok(TransactionStatus::Failed)
            },
            TransferStatus::Cancelled => {
                // Mark transaction as failed
                self.transaction_repo.mark_as_failed(transaction_id, "Transfer cancelled").await?;
                Ok(TransactionStatus::Failed)
            },
            _ => Ok(TransactionStatus::Transferred),
        }
    }
    
    /// Get current exchange rate
    pub async fn get_exchange_rate(&self, source_currency: &str, destination_currency: &str) -> AppResult<Decimal> {
        // First check if we have a cached rate
        if let Ok(Some(rate)) = self.exchange_rate_repo.get_latest(source_currency, destination_currency).await {
            return Ok(rate.rate);
        }
        
        // If not, fetch fresh rate from AD Bank
        let exchange_rate = self.ad_bank_client.get_exchange_rate(source_currency, destination_currency).await?;
        
        // Save to repository
        self.exchange_rate_repo.save(&exchange_rate).await?;
        
        Ok(exchange_rate.rate)
    }
    
    /// Calculate destination amount based on source amount and exchange rate
    pub async fn calculate_destination_amount(&self, source_amount: Decimal) -> AppResult<(Decimal, Decimal)> {
        let source_currency = "INR";
        let destination_currency = "CAD";
        
        // Get exchange rate
        let exchange_rate = self.get_exchange_rate(source_currency, destination_currency).await?;
        
        // Calculate fee
        let fee = self.calculate_fee(source_amount);
        
        // Calculate net amount after fee
        let net_amount = source_amount - fee;
        
        // Calculate destination amount
        let destination_amount = net_amount * exchange_rate;
        
        Ok((destination_amount, exchange_rate))
    }
} 