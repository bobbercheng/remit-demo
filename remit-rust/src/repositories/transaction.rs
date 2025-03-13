use aws_sdk_dynamodb::{types::AttributeValue, Client as DynamoDbClient};
use chrono::Utc;
use std::collections::HashMap;

use crate::config::get_config;
use crate::errors::{AppError, AppResult};
use crate::models::{Transaction, TransactionStatus};

/// Repository for transaction operations in DynamoDB
pub struct TransactionRepository {
    client: DynamoDbClient,
    table_name: String,
}

impl TransactionRepository {
    /// Create a new transaction repository
    pub fn new(client: DynamoDbClient) -> Self {
        let config = get_config();
        
        TransactionRepository {
            client,
            table_name: config.database.transactions_table.clone(),
        }
    }
    
    /// Save a transaction to DynamoDB
    pub async fn save(&self, transaction: &Transaction) -> AppResult<()> {
        let item = transaction.to_dynamodb_item();
        
        self.client.put_item()
            .table_name(&self.table_name)
            .set_item(Some(item))
            .send()
            .await
            .map_err(|e| AppError::database_error(format!("Failed to save transaction: {}", e)))?;
        
        Ok(())
    }
    
    /// Get a transaction by ID
    pub async fn get_by_id(&self, transaction_id: &str) -> AppResult<Transaction> {
        let result = self.client.get_item()
            .table_name(&self.table_name)
            .key("transaction_id", AttributeValue::S(transaction_id.to_string()))
            .send()
            .await
            .map_err(|e| AppError::database_error(format!("Failed to get transaction: {}", e)))?;
        
        if let Some(item) = result.item {
            Transaction::from_dynamodb_item(item)
                .ok_or_else(|| AppError::database_error("Failed to parse transaction from DynamoDB item".to_string()))
        } else {
            Err(AppError::not_found(format!("Transaction not found: {}", transaction_id)))
        }
    }
    
    /// Get transactions by user ID
    pub async fn get_by_user_id(&self, user_id: &str, limit: Option<i32>) -> AppResult<Vec<Transaction>> {
        let limit = limit.unwrap_or(50).min(100);
        
        let result = self.client.query()
            .table_name(&self.table_name)
            .index_name("UserIdIndex")
            .key_condition_expression("user_id = :user_id")
            .expression_attribute_values(":user_id", AttributeValue::S(user_id.to_string()))
            .limit(limit)
            .scan_index_forward(false)  // Sort newest first
            .send()
            .await
            .map_err(|e| AppError::database_error(format!("Failed to query transactions: {}", e)))?;
            
        let items = result.items.unwrap_or_default();
        
        let transactions = items.into_iter()
            .filter_map(Transaction::from_dynamodb_item)
            .collect();
            
        Ok(transactions)
    }
    
    /// Get transactions by status
    pub async fn get_by_status(&self, status: TransactionStatus, limit: Option<i32>) -> AppResult<Vec<Transaction>> {
        let limit = limit.unwrap_or(50).min(100);
        
        let result = self.client.query()
            .table_name(&self.table_name)
            .index_name("StatusCreatedAtIndex")
            .key_condition_expression("status = :status")
            .expression_attribute_values(":status", AttributeValue::S(status.to_string()))
            .limit(limit)
            .send()
            .await
            .map_err(|e| AppError::database_error(format!("Failed to query transactions: {}", e)))?;
            
        let items = result.items.unwrap_or_default();
        
        let transactions = items.into_iter()
            .filter_map(Transaction::from_dynamodb_item)
            .collect();
            
        Ok(transactions)
    }
    
    /// Update transaction status
    pub async fn update_status(&self, transaction_id: &str, status: TransactionStatus) -> AppResult<Transaction> {
        let now = Utc::now().timestamp().to_string();
        
        let result = self.client.update_item()
            .table_name(&self.table_name)
            .key("transaction_id", AttributeValue::S(transaction_id.to_string()))
            .update_expression("SET #status = :status, updated_at = :updated_at")
            .expression_attribute_names("#status", "status")
            .expression_attribute_values(":status", AttributeValue::S(status.to_string()))
            .expression_attribute_values(":updated_at", AttributeValue::N(now))
            .return_values("ALL_NEW")
            .send()
            .await
            .map_err(|e| AppError::database_error(format!("Failed to update transaction status: {}", e)))?;
            
        if let Some(attributes) = result.attributes {
            Transaction::from_dynamodb_item(attributes)
                .ok_or_else(|| AppError::database_error("Failed to parse transaction from DynamoDB item".to_string()))
        } else {
            Err(AppError::not_found(format!("Transaction not found: {}", transaction_id)))
        }
    }
    
    /// Update payment details
    pub async fn update_payment_details(&self, transaction_id: &str, payment_details_json: &str) -> AppResult<Transaction> {
        let now = Utc::now().timestamp().to_string();
        
        let result = self.client.update_item()
            .table_name(&self.table_name)
            .key("transaction_id", AttributeValue::S(transaction_id.to_string()))
            .update_expression("SET payment_details = :payment_details, updated_at = :updated_at")
            .expression_attribute_values(":payment_details", AttributeValue::S(payment_details_json.to_string()))
            .expression_attribute_values(":updated_at", AttributeValue::N(now))
            .return_values("ALL_NEW")
            .send()
            .await
            .map_err(|e| AppError::database_error(format!("Failed to update payment details: {}", e)))?;
            
        if let Some(attributes) = result.attributes {
            Transaction::from_dynamodb_item(attributes)
                .ok_or_else(|| AppError::database_error("Failed to parse transaction from DynamoDB item".to_string()))
        } else {
            Err(AppError::not_found(format!("Transaction not found: {}", transaction_id)))
        }
    }
    
    /// Update conversion details and exchange rate
    pub async fn update_conversion_details(
        &self, 
        transaction_id: &str, 
        conversion_details_json: &str,
        exchange_rate: &str,
        destination_amount: &str,
    ) -> AppResult<Transaction> {
        let now = Utc::now().timestamp().to_string();
        
        let result = self.client.update_item()
            .table_name(&self.table_name)
            .key("transaction_id", AttributeValue::S(transaction_id.to_string()))
            .update_expression("SET conversion_details = :conversion_details, exchange_rate = :exchange_rate, destination_amount = :destination_amount, updated_at = :updated_at")
            .expression_attribute_values(":conversion_details", AttributeValue::S(conversion_details_json.to_string()))
            .expression_attribute_values(":exchange_rate", AttributeValue::N(exchange_rate.to_string()))
            .expression_attribute_values(":destination_amount", AttributeValue::N(destination_amount.to_string()))
            .expression_attribute_values(":updated_at", AttributeValue::N(now))
            .return_values("ALL_NEW")
            .send()
            .await
            .map_err(|e| AppError::database_error(format!("Failed to update conversion details: {}", e)))?;
            
        if let Some(attributes) = result.attributes {
            Transaction::from_dynamodb_item(attributes)
                .ok_or_else(|| AppError::database_error("Failed to parse transaction from DynamoDB item".to_string()))
        } else {
            Err(AppError::not_found(format!("Transaction not found: {}", transaction_id)))
        }
    }
    
    /// Update transfer details
    pub async fn update_transfer_details(&self, transaction_id: &str, transfer_details_json: &str) -> AppResult<Transaction> {
        let now = Utc::now().timestamp().to_string();
        
        let result = self.client.update_item()
            .table_name(&self.table_name)
            .key("transaction_id", AttributeValue::S(transaction_id.to_string()))
            .update_expression("SET transfer_details = :transfer_details, updated_at = :updated_at")
            .expression_attribute_values(":transfer_details", AttributeValue::S(transfer_details_json.to_string()))
            .expression_attribute_values(":updated_at", AttributeValue::N(now))
            .return_values("ALL_NEW")
            .send()
            .await
            .map_err(|e| AppError::database_error(format!("Failed to update transfer details: {}", e)))?;
            
        if let Some(attributes) = result.attributes {
            Transaction::from_dynamodb_item(attributes)
                .ok_or_else(|| AppError::database_error("Failed to parse transaction from DynamoDB item".to_string()))
        } else {
            Err(AppError::not_found(format!("Transaction not found: {}", transaction_id)))
        }
    }
    
    /// Mark transaction as failed
    pub async fn mark_as_failed(&self, transaction_id: &str, failure_reason: &str) -> AppResult<Transaction> {
        let now = Utc::now().timestamp().to_string();
        
        let result = self.client.update_item()
            .table_name(&self.table_name)
            .key("transaction_id", AttributeValue::S(transaction_id.to_string()))
            .update_expression("SET #status = :status, failure_reason = :failure_reason, updated_at = :updated_at")
            .expression_attribute_names("#status", "status")
            .expression_attribute_values(":status", AttributeValue::S(TransactionStatus::Failed.to_string()))
            .expression_attribute_values(":failure_reason", AttributeValue::S(failure_reason.to_string()))
            .expression_attribute_values(":updated_at", AttributeValue::N(now))
            .return_values("ALL_NEW")
            .send()
            .await
            .map_err(|e| AppError::database_error(format!("Failed to mark transaction as failed: {}", e)))?;
            
        if let Some(attributes) = result.attributes {
            Transaction::from_dynamodb_item(attributes)
                .ok_or_else(|| AppError::database_error("Failed to parse transaction from DynamoDB item".to_string()))
        } else {
            Err(AppError::not_found(format!("Transaction not found: {}", transaction_id)))
        }
    }
} 