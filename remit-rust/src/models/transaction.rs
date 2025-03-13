use aws_sdk_dynamodb::model::AttributeValue;
use chrono::{DateTime, Utc};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use uuid::Uuid;
use validator::Validate;

/// Represents the state of a remittance transaction
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "UPPERCASE")]
pub enum TransactionStatus {
    Pending,
    Funded,
    Converted,
    Transferred,
    Completed,
    Failed,
}

impl ToString for TransactionStatus {
    fn to_string(&self) -> String {
        match self {
            TransactionStatus::Pending => "PENDING".to_string(),
            TransactionStatus::Funded => "FUNDED".to_string(),
            TransactionStatus::Converted => "CONVERTED".to_string(),
            TransactionStatus::Transferred => "TRANSFERRED".to_string(),
            TransactionStatus::Completed => "COMPLETED".to_string(),
            TransactionStatus::Failed => "FAILED".to_string(),
        }
    }
}

impl Default for TransactionStatus {
    fn default() -> Self {
        TransactionStatus::Pending
    }
}

/// Bank account details for recipient
#[derive(Debug, Clone, Serialize, Deserialize, Validate)]
pub struct BankAccountDetails {
    #[validate(length(min = 1, max = 50))]
    pub bank_name: String,
    
    #[validate(length(min = 1, max = 50))]
    pub account_number: String,
    
    #[validate(length(min = 1, max = 50))]
    pub account_holder_name: String,
    
    #[validate(length(min = 1, max = 50))]
    pub ifsc_or_swift_code: String,
}

/// UPI payment details
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct PaymentDetails {
    pub payment_id: Option<String>,
    pub payment_link: Option<String>,
    pub payment_time: Option<DateTime<Utc>>,
    pub reference_id: Option<String>,
}

/// Currency conversion details
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ConversionDetails {
    pub conversion_id: Option<String>,
    pub conversion_time: Option<DateTime<Utc>>,
    pub actual_exchange_rate: Option<Decimal>,
    pub reference_id: Option<String>,
}

/// Wise transfer details
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct TransferDetails {
    pub transfer_id: Option<String>,
    pub transfer_time: Option<DateTime<Utc>>,
    pub tracking_url: Option<String>,
    pub estimated_delivery: Option<DateTime<Utc>>,
    pub reference_id: Option<String>,
}

/// Main transaction model
#[derive(Debug, Clone, Serialize, Deserialize, Validate)]
pub struct Transaction {
    pub transaction_id: String,
    
    #[validate(length(min = 1, max = 50))]
    pub user_id: String,
    
    pub status: TransactionStatus,
    
    pub created_at: DateTime<Utc>,
    
    pub updated_at: DateTime<Utc>,
    
    #[validate(range(min = 1000, max = 1_000_000))]
    pub source_amount: Decimal,
    
    pub source_currency: String,
    
    pub destination_amount: Option<Decimal>,
    
    pub destination_currency: String,
    
    pub exchange_rate: Option<Decimal>,
    
    pub fees: Decimal,
    
    #[validate(length(min = 1, max = 50))]
    pub recipient_id: String,
    
    #[validate]
    pub recipient_account_details: BankAccountDetails,
    
    pub payment_details: PaymentDetails,
    
    pub conversion_details: ConversionDetails,
    
    pub transfer_details: TransferDetails,
    
    pub failure_reason: Option<String>,
    
    #[validate(length(min = 0, max = 500))]
    pub notes: Option<String>,
}

impl Transaction {
    /// Create a new transaction
    pub fn new(
        user_id: String,
        source_amount: Decimal,
        recipient_id: String,
        recipient_account_details: BankAccountDetails,
        notes: Option<String>,
        fees: Decimal,
    ) -> Self {
        let now = Utc::now();
        
        Transaction {
            transaction_id: Uuid::new_v4().to_string(),
            user_id,
            status: TransactionStatus::Pending,
            created_at: now,
            updated_at: now,
            source_amount,
            source_currency: "INR".to_string(),
            destination_amount: None,
            destination_currency: "CAD".to_string(),
            exchange_rate: None,
            fees,
            recipient_id,
            recipient_account_details,
            payment_details: PaymentDetails::default(),
            conversion_details: ConversionDetails::default(),
            transfer_details: TransferDetails::default(),
            failure_reason: None,
            notes,
        }
    }
    
    /// Convert Transaction to DynamoDB item
    pub fn to_dynamodb_item(&self) -> HashMap<String, AttributeValue> {
        let mut item = HashMap::new();
        
        item.insert("transaction_id".to_string(), AttributeValue::S(self.transaction_id.clone()));
        item.insert("user_id".to_string(), AttributeValue::S(self.user_id.clone()));
        item.insert("status".to_string(), AttributeValue::S(self.status.to_string()));
        item.insert("created_at".to_string(), AttributeValue::N(self.created_at.timestamp().to_string()));
        item.insert("updated_at".to_string(), AttributeValue::N(self.updated_at.timestamp().to_string()));
        item.insert("source_amount".to_string(), AttributeValue::N(self.source_amount.to_string()));
        item.insert("source_currency".to_string(), AttributeValue::S(self.source_currency.clone()));
        item.insert("destination_currency".to_string(), AttributeValue::S(self.destination_currency.clone()));
        item.insert("fees".to_string(), AttributeValue::N(self.fees.to_string()));
        item.insert("recipient_id".to_string(), AttributeValue::S(self.recipient_id.clone()));
        
        // Convert complex types to JSON and store as a string
        if let Ok(json) = serde_json::to_string(&self.recipient_account_details) {
            item.insert("recipient_account_details".to_string(), AttributeValue::S(json));
        }
        
        if let Ok(json) = serde_json::to_string(&self.payment_details) {
            item.insert("payment_details".to_string(), AttributeValue::S(json));
        }
        
        if let Ok(json) = serde_json::to_string(&self.conversion_details) {
            item.insert("conversion_details".to_string(), AttributeValue::S(json));
        }
        
        if let Ok(json) = serde_json::to_string(&self.transfer_details) {
            item.insert("transfer_details".to_string(), AttributeValue::S(json));
        }
        
        if let Some(ref destination_amount) = self.destination_amount {
            item.insert("destination_amount".to_string(), AttributeValue::N(destination_amount.to_string()));
        }
        
        if let Some(ref exchange_rate) = self.exchange_rate {
            item.insert("exchange_rate".to_string(), AttributeValue::N(exchange_rate.to_string()));
        }
        
        if let Some(ref failure_reason) = self.failure_reason {
            item.insert("failure_reason".to_string(), AttributeValue::S(failure_reason.clone()));
        }
        
        if let Some(ref notes) = self.notes {
            item.insert("notes".to_string(), AttributeValue::S(notes.clone()));
        }
        
        item
    }
    
    /// Convert DynamoDB item to Transaction
    pub fn from_dynamodb_item(item: HashMap<String, AttributeValue>) -> Option<Self> {
        let transaction_id = item.get("transaction_id")?.as_s().ok()?;
        let user_id = item.get("user_id")?.as_s().ok()?;
        let status_str = item.get("status")?.as_s().ok()?;
        let created_at_str = item.get("created_at")?.as_n().ok()?;
        let updated_at_str = item.get("updated_at")?.as_n().ok()?;
        let source_amount_str = item.get("source_amount")?.as_n().ok()?;
        let source_currency = item.get("source_currency")?.as_s().ok()?;
        let destination_currency = item.get("destination_currency")?.as_s().ok()?;
        let fees_str = item.get("fees")?.as_n().ok()?;
        let recipient_id = item.get("recipient_id")?.as_s().ok()?;
        
        // Parse timestamps
        let created_at_ts = created_at_str.parse::<i64>().ok()?;
        let updated_at_ts = updated_at_str.parse::<i64>().ok()?;
        
        let created_at = DateTime::from_timestamp(created_at_ts, 0)?;
        let updated_at = DateTime::from_timestamp(updated_at_ts, 0)?;
        
        // Parse decimal values
        let source_amount = source_amount_str.parse::<Decimal>().ok()?;
        let fees = fees_str.parse::<Decimal>().ok()?;
        
        // Parse status enum
        let status = match status_str.as_str() {
            "PENDING" => TransactionStatus::Pending,
            "FUNDED" => TransactionStatus::Funded,
            "CONVERTED" => TransactionStatus::Converted,
            "TRANSFERRED" => TransactionStatus::Transferred,
            "COMPLETED" => TransactionStatus::Completed,
            "FAILED" => TransactionStatus::Failed,
            _ => return None,
        };
        
        // Parse optional decimal values
        let destination_amount = item.get("destination_amount")
            .and_then(|av| av.as_n().ok())
            .and_then(|s| s.parse::<Decimal>().ok());
        
        let exchange_rate = item.get("exchange_rate")
            .and_then(|av| av.as_n().ok())
            .and_then(|s| s.parse::<Decimal>().ok());
        
        // Parse optional string values
        let failure_reason = item.get("failure_reason")
            .and_then(|av| av.as_s().ok())
            .map(|s| s.to_string());
            
        let notes = item.get("notes")
            .and_then(|av| av.as_s().ok())
            .map(|s| s.to_string());
        
        // Parse complex JSON types
        let recipient_account_details = item.get("recipient_account_details")
            .and_then(|av| av.as_s().ok())
            .and_then(|s| serde_json::from_str::<BankAccountDetails>(s).ok())
            .unwrap_or_else(|| BankAccountDetails {
                bank_name: "Unknown".to_string(),
                account_number: "Unknown".to_string(),
                account_holder_name: "Unknown".to_string(),
                ifsc_or_swift_code: "Unknown".to_string(),
            });
        
        let payment_details = item.get("payment_details")
            .and_then(|av| av.as_s().ok())
            .and_then(|s| serde_json::from_str::<PaymentDetails>(s).ok())
            .unwrap_or_default();
        
        let conversion_details = item.get("conversion_details")
            .and_then(|av| av.as_s().ok())
            .and_then(|s| serde_json::from_str::<ConversionDetails>(s).ok())
            .unwrap_or_default();
        
        let transfer_details = item.get("transfer_details")
            .and_then(|av| av.as_s().ok())
            .and_then(|s| serde_json::from_str::<TransferDetails>(s).ok())
            .unwrap_or_default();
        
        Some(Transaction {
            transaction_id: transaction_id.to_string(),
            user_id: user_id.to_string(),
            status,
            created_at,
            updated_at,
            source_amount,
            source_currency: source_currency.to_string(),
            destination_amount,
            destination_currency: destination_currency.to_string(),
            exchange_rate,
            fees,
            recipient_id: recipient_id.to_string(),
            recipient_account_details,
            payment_details,
            conversion_details,
            transfer_details,
            failure_reason,
            notes,
        })
    }
    
    /// Update transaction status and set updated_at to current time
    pub fn update_status(&mut self, status: TransactionStatus) {
        self.status = status;
        self.updated_at = Utc::now();
    }
    
    /// Mark transaction as failed with a reason
    pub fn mark_as_failed(&mut self, reason: String) {
        self.status = TransactionStatus::Failed;
        self.failure_reason = Some(reason);
        self.updated_at = Utc::now();
    }
} 