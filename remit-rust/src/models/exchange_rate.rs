use aws_sdk_dynamodb::model::AttributeValue;
use chrono::{DateTime, Utc};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Exchange rate model
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExchangeRate {
    pub date: String,
    pub timestamp: DateTime<Utc>,
    pub source_currency: String,
    pub destination_currency: String,
    pub rate: Decimal,
    pub provider: String,
}

impl ExchangeRate {
    /// Create a new exchange rate entry
    pub fn new(
        source_currency: String,
        destination_currency: String,
        rate: Decimal,
        provider: String,
    ) -> Self {
        let now = Utc::now();
        let date = now.format("%Y-%m-%d").to_string();
        
        ExchangeRate {
            date,
            timestamp: now,
            source_currency,
            destination_currency,
            rate,
            provider,
        }
    }
    
    /// Convert to DynamoDB item
    pub fn to_dynamodb_item(&self) -> HashMap<String, AttributeValue> {
        let mut item = HashMap::new();
        
        item.insert("date".to_string(), AttributeValue::S(self.date.clone()));
        item.insert("timestamp".to_string(), AttributeValue::N(self.timestamp.timestamp().to_string()));
        item.insert("source_currency".to_string(), AttributeValue::S(self.source_currency.clone()));
        item.insert("destination_currency".to_string(), AttributeValue::S(self.destination_currency.clone()));
        item.insert("rate".to_string(), AttributeValue::N(self.rate.to_string()));
        item.insert("provider".to_string(), AttributeValue::S(self.provider.clone()));
        
        item
    }
    
    /// Convert from DynamoDB item
    pub fn from_dynamodb_item(item: HashMap<String, AttributeValue>) -> Option<Self> {
        let date = item.get("date")?.as_s().ok()?;
        let timestamp_str = item.get("timestamp")?.as_n().ok()?;
        let source_currency = item.get("source_currency")?.as_s().ok()?;
        let destination_currency = item.get("destination_currency")?.as_s().ok()?;
        let rate_str = item.get("rate")?.as_n().ok()?;
        let provider = item.get("provider")?.as_s().ok()?;
        
        // Parse timestamp
        let timestamp_ts = timestamp_str.parse::<i64>().ok()?;
        let timestamp = DateTime::from_timestamp(timestamp_ts, 0)?;
        
        // Parse rate
        let rate = rate_str.parse::<Decimal>().ok()?;
        
        Some(ExchangeRate {
            date: date.to_string(),
            timestamp,
            source_currency: source_currency.to_string(),
            destination_currency: destination_currency.to_string(),
            rate,
            provider: provider.to_string(),
        })
    }
} 