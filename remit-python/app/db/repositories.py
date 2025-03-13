from typing import List, Optional, Dict, Any
from boto3.dynamodb.conditions import Key
from functools import lru_cache
from datetime import datetime, timedelta
from decimal import Decimal

from app.db.dynamodb import DynamoDBRepository
from app.db.models import Transaction, TransactionEvent, ExchangeRate, TransactionStatus


class TransactionRepository(DynamoDBRepository[Transaction]):
    """Repository for remittance transactions"""
    
    def __init__(self):
        super().__init__("Transactions", Transaction)
    
    def get_by_id(self, transaction_id: str) -> Optional[Transaction]:
        """Get a transaction by its ID"""
        return self.get({"transaction_id": transaction_id})
    
    def get_by_user(self, user_id: str) -> List[Transaction]:
        """Get all transactions for a user"""
        # This query requires a GSI on user_id
        return self.query(
            key_condition_expression=Key("user_id").eq(user_id),
            expression_values={}
        )
    
    def update_status(self, transaction_id: str, 
                      status: TransactionStatus, 
                      additional_updates: Optional[Dict[str, Any]] = None) -> Optional[Transaction]:
        """Update a transaction's status and optionally other fields"""
        update_expression = "SET #status = :status, updated_at = :updated_at"
        expression_values = {
            ":status": status.value,
            ":updated_at": datetime.utcnow().isoformat()
        }
        
        # Add additional updates if provided
        if additional_updates:
            for i, (key, value) in enumerate(additional_updates.items()):
                update_expression += f", #{i} = :{i}"
                expression_values[f":{i}"] = value
                # Need to define ExpressionAttributeNames for each attribute
                if not hasattr(self, "_expression_attribute_names"):
                    self._expression_attribute_names = {}
                self._expression_attribute_names[f"#{i}"] = key
        
        return self.update(
            key={"transaction_id": transaction_id},
            update_expression=update_expression,
            expression_values=expression_values
        )
    
    def get_recent_transactions(self, limit: int = 50) -> List[Transaction]:
        """Get recent transactions, limited to a specific count"""
        # This would require a scan or a GSI on created_at
        # For simplicity, we'll just return an empty list for now
        # In a real implementation, this should use a GSI or other efficient query
        return []


class TransactionEventRepository(DynamoDBRepository[TransactionEvent]):
    """Repository for transaction event history"""
    
    def __init__(self):
        super().__init__("TransactionEvents", TransactionEvent)
    
    def get_events_for_transaction(self, transaction_id: str) -> List[TransactionEvent]:
        """Get all events for a transaction"""
        return self.query(
            key_condition_expression=Key("transaction_id").eq(transaction_id),
            expression_values={}
        )
    
    def add_event(self, transaction_id: str, event_type, event_data: Dict[str, Any], 
                 actor: str) -> TransactionEvent:
        """Add a new event for a transaction"""
        event = TransactionEvent(
            transaction_id=transaction_id,
            event_type=event_type,
            event_data=event_data,
            actor=actor
        )
        return self.create(event)


class ExchangeRateRepository(DynamoDBRepository[ExchangeRate]):
    """Repository for exchange rate history"""
    
    def __init__(self):
        super().__init__("ExchangeRates", ExchangeRate)
    
    def get_latest_rate(self, currency_pair: str) -> Optional[ExchangeRate]:
        """Get the latest exchange rate for a currency pair"""
        # In a real implementation, we'd query with a sort order
        # For simplicity, we'll just use the first item returned
        results = self.query(
            key_condition_expression=Key("currency_pair").eq(currency_pair),
            expression_values={}
        )
        if results:
            # Return the most recent rate by timestamp
            return max(results, key=lambda rate: rate.timestamp)
        return None
    
    def add_rate(self, currency_pair: str, rate: Decimal, source: str) -> ExchangeRate:
        """Add a new exchange rate"""
        exchange_rate = ExchangeRate(
            currency_pair=currency_pair,
            rate=rate,
            source=source
        )
        return self.create(exchange_rate)
    
    def get_historical_rates(self, currency_pair: str, days: int = 7) -> List[ExchangeRate]:
        """Get historical rates for the past number of days"""
        # This would normally use a query with a date range
        # For simplicity, we'll return an empty list
        return []


@lru_cache()
def get_transaction_repository() -> TransactionRepository:
    """Get or create a TransactionRepository instance"""
    return TransactionRepository()


@lru_cache()
def get_transaction_event_repository() -> TransactionEventRepository:
    """Get or create a TransactionEventRepository instance"""
    return TransactionEventRepository()


@lru_cache()
def get_exchange_rate_repository() -> ExchangeRateRepository:
    """Get or create an ExchangeRateRepository instance"""
    return ExchangeRateRepository() 