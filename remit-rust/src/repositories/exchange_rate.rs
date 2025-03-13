use aws_sdk_dynamodb::{types::AttributeValue, Client as DynamoDbClient};
use chrono::Utc;

use crate::config::get_config;
use crate::errors::{AppError, AppResult};
use crate::models::ExchangeRate;

/// Repository for exchange rate operations in DynamoDB
pub struct ExchangeRateRepository {
    client: DynamoDbClient,
    table_name: String,
}

impl ExchangeRateRepository {
    /// Create a new exchange rate repository
    pub fn new(client: DynamoDbClient) -> Self {
        let config = get_config();
        
        ExchangeRateRepository {
            client,
            table_name: config.database.exchange_rates_table.clone(),
        }
    }
    
    /// Save an exchange rate to DynamoDB
    pub async fn save(&self, exchange_rate: &ExchangeRate) -> AppResult<()> {
        let item = exchange_rate.to_dynamodb_item();
        
        self.client.put_item()
            .table_name(&self.table_name)
            .set_item(Some(item))
            .send()
            .await
            .map_err(|e| AppError::database_error(format!("Failed to save exchange rate: {}", e)))?;
        
        Ok(())
    }
    
    /// Get the latest exchange rate for a currency pair
    pub async fn get_latest(&self, source_currency: &str, destination_currency: &str) -> AppResult<Option<ExchangeRate>> {
        let result = self.client.query()
            .table_name(&self.table_name)
            .index_name("CurrencyPairIndex")
            .key_condition_expression("source_currency = :source_currency AND destination_currency = :destination_currency")
            .expression_attribute_values(":source_currency", AttributeValue::S(source_currency.to_string()))
            .expression_attribute_values(":destination_currency", AttributeValue::S(destination_currency.to_string()))
            .limit(1)
            .scan_index_forward(false)  // Sort newest first
            .send()
            .await
            .map_err(|e| AppError::database_error(format!("Failed to query exchange rates: {}", e)))?;
            
        let items = result.items.unwrap_or_default();
        
        if items.is_empty() {
            return Ok(None);
        }
        
        let exchange_rate = ExchangeRate::from_dynamodb_item(items[0].clone())
            .ok_or_else(|| AppError::database_error("Failed to parse exchange rate from DynamoDB item".to_string()))?;
            
        // Check if the exchange rate is still valid (within cache time)
        let config = get_config();
        let cache_seconds = config.business_rules.exchange_rate_cache_seconds;
        let now = Utc::now();
        let diff = now.timestamp() - exchange_rate.timestamp.timestamp();
        
        if diff > cache_seconds as i64 {
            return Ok(None);
        }
        
        Ok(Some(exchange_rate))
    }
    
    /// Get exchange rate history for a currency pair
    pub async fn get_history(
        &self, 
        source_currency: &str, 
        destination_currency: &str,
        limit: Option<i32>
    ) -> AppResult<Vec<ExchangeRate>> {
        let limit = limit.unwrap_or(10).min(50);
        
        let result = self.client.query()
            .table_name(&self.table_name)
            .index_name("CurrencyPairIndex")
            .key_condition_expression("source_currency = :source_currency AND destination_currency = :destination_currency")
            .expression_attribute_values(":source_currency", AttributeValue::S(source_currency.to_string()))
            .expression_attribute_values(":destination_currency", AttributeValue::S(destination_currency.to_string()))
            .limit(limit)
            .scan_index_forward(false)  // Sort newest first
            .send()
            .await
            .map_err(|e| AppError::database_error(format!("Failed to query exchange rates: {}", e)))?;
            
        let items = result.items.unwrap_or_default();
        
        let exchange_rates = items.into_iter()
            .filter_map(ExchangeRate::from_dynamodb_item)
            .collect();
            
        Ok(exchange_rates)
    }
} 