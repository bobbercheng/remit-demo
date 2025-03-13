from typing import Dict, List, Optional, Any, Literal
from enum import Enum
from decimal import Decimal
from datetime import datetime
import uuid


class TransactionStatus(str, Enum):
    """Enumeration of possible transaction statuses"""
    INITIATED = "INITIATED"
    PAYMENT_PENDING = "PAYMENT_PENDING"
    PAYMENT_RECEIVED = "PAYMENT_RECEIVED"
    CONVERSION_IN_PROGRESS = "CONVERSION_IN_PROGRESS"
    CONVERSION_COMPLETE = "CONVERSION_COMPLETE"
    FUNDS_SENT = "FUNDS_SENT"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"
    REFUNDED = "REFUNDED"


class EventType(str, Enum):
    """Enumeration of possible transaction event types"""
    TRANSACTION_CREATED = "TRANSACTION_CREATED"
    PAYMENT_INITIATED = "PAYMENT_INITIATED"
    PAYMENT_RECEIVED = "PAYMENT_RECEIVED"
    CONVERSION_INITIATED = "CONVERSION_INITIATED"
    CONVERSION_COMPLETED = "CONVERSION_COMPLETED"
    TRANSFER_INITIATED = "TRANSFER_INITIATED"
    TRANSFER_COMPLETED = "TRANSFER_COMPLETED"
    TRANSACTION_COMPLETED = "TRANSACTION_COMPLETED"
    TRANSACTION_FAILED = "TRANSACTION_FAILED"
    REFUND_INITIATED = "REFUND_INITIATED"
    REFUND_COMPLETED = "REFUND_COMPLETED"


class Transaction:
    """
    DynamoDB model for a remittance transaction
    
    This is the main data structure for tracking remittance transactions
    from initiation to completion.
    """
    def __init__(
        self,
        user_id: str,
        amount_inr: Decimal,
        recipient_details: Dict[str, Any],
        transaction_id: Optional[str] = None,
        status: TransactionStatus = TransactionStatus.INITIATED,
        amount_cad: Optional[Decimal] = None,
        exchange_rate: Optional[Decimal] = None,
        fees: Optional[Decimal] = None,
        payment_details: Optional[Dict[str, Any]] = None,
        wise_transfer_id: Optional[str] = None,
        ad_bank_reference: Optional[str] = None,
        failure_reason: Optional[str] = None,
        created_at: Optional[datetime] = None,
        updated_at: Optional[datetime] = None
    ):
        self.transaction_id = transaction_id or str(uuid.uuid4())
        self.user_id = user_id
        self.status = status
        self.amount_inr = amount_inr
        self.amount_cad = amount_cad
        self.exchange_rate = exchange_rate
        self.fees = fees
        self.recipient_details = recipient_details
        self.payment_details = payment_details or {}
        self.wise_transfer_id = wise_transfer_id
        self.ad_bank_reference = ad_bank_reference
        self.failure_reason = failure_reason
        self.created_at = created_at or datetime.utcnow()
        self.updated_at = updated_at or datetime.utcnow()
    
    def to_dynamodb_item(self) -> Dict[str, Any]:
        """Convert transaction to DynamoDB item format"""
        return {
            "transaction_id": self.transaction_id,
            "user_id": self.user_id,
            "status": self.status.value,
            "amount_inr": self.amount_inr,
            "amount_cad": self.amount_cad,
            "exchange_rate": self.exchange_rate,
            "fees": self.fees,
            "recipient_details": self.recipient_details,
            "payment_details": self.payment_details,
            "wise_transfer_id": self.wise_transfer_id,
            "ad_bank_reference": self.ad_bank_reference,
            "failure_reason": self.failure_reason,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat()
        }
    
    @classmethod
    def from_dynamodb_item(cls, item: Dict[str, Any]) -> "Transaction":
        """Create a Transaction instance from a DynamoDB item"""
        return cls(
            transaction_id=item.get("transaction_id"),
            user_id=item.get("user_id"),
            status=TransactionStatus(item.get("status")),
            amount_inr=item.get("amount_inr"),
            amount_cad=item.get("amount_cad"),
            exchange_rate=item.get("exchange_rate"),
            fees=item.get("fees"),
            recipient_details=item.get("recipient_details", {}),
            payment_details=item.get("payment_details", {}),
            wise_transfer_id=item.get("wise_transfer_id"),
            ad_bank_reference=item.get("ad_bank_reference"),
            failure_reason=item.get("failure_reason"),
            created_at=datetime.fromisoformat(item.get("created_at")),
            updated_at=datetime.fromisoformat(item.get("updated_at"))
        )


class TransactionEvent:
    """
    DynamoDB model for transaction event history
    
    This model tracks all events related to a transaction for
    audit and tracking purposes.
    """
    def __init__(
        self,
        transaction_id: str,
        event_type: EventType,
        event_data: Dict[str, Any],
        actor: str,
        event_id: Optional[str] = None,
        event_timestamp: Optional[datetime] = None
    ):
        self.transaction_id = transaction_id
        self.event_id = event_id or str(uuid.uuid4())
        self.event_timestamp = event_timestamp or datetime.utcnow()
        self.event_type = event_type
        self.event_data = event_data
        self.actor = actor  # User ID or system component that triggered the event
    
    def to_dynamodb_item(self) -> Dict[str, Any]:
        """Convert event to DynamoDB item format"""
        return {
            "transaction_id": self.transaction_id,
            "event_id": self.event_id,
            "event_timestamp": self.event_timestamp.isoformat(),
            "event_type": self.event_type.value,
            "event_data": self.event_data,
            "actor": self.actor
        }
    
    @classmethod
    def from_dynamodb_item(cls, item: Dict[str, Any]) -> "TransactionEvent":
        """Create a TransactionEvent instance from a DynamoDB item"""
        return cls(
            transaction_id=item.get("transaction_id"),
            event_id=item.get("event_id"),
            event_timestamp=datetime.fromisoformat(item.get("event_timestamp")),
            event_type=EventType(item.get("event_type")),
            event_data=item.get("event_data", {}),
            actor=item.get("actor")
        )


class ExchangeRate:
    """
    DynamoDB model for storing exchange rate history
    
    This model tracks historical exchange rates for different
    currency pairs.
    """
    def __init__(
        self,
        currency_pair: str,
        rate: Decimal,
        source: str,
        timestamp: Optional[datetime] = None
    ):
        self.currency_pair = currency_pair
        self.timestamp = timestamp or datetime.utcnow()
        self.rate = rate
        self.source = source
    
    def to_dynamodb_item(self) -> Dict[str, Any]:
        """Convert exchange rate to DynamoDB item format"""
        return {
            "currency_pair": self.currency_pair,
            "timestamp": self.timestamp.isoformat(),
            "rate": self.rate,
            "source": self.source
        }
    
    @classmethod
    def from_dynamodb_item(cls, item: Dict[str, Any]) -> "ExchangeRate":
        """Create an ExchangeRate instance from a DynamoDB item"""
        return cls(
            currency_pair=item.get("currency_pair"),
            timestamp=datetime.fromisoformat(item.get("timestamp")),
            rate=item.get("rate"),
            source=item.get("source")
        ) 