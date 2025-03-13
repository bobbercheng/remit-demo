from typing import Dict, List, Optional, Any, Literal
from pydantic import BaseModel, Field, validator, root_validator
from decimal import Decimal
from datetime import datetime
from enum import Enum
import uuid

from app.db.models import TransactionStatus, EventType


class CanadianRecipient(BaseModel):
    """Details of the recipient in Canada"""
    full_name: str = Field(..., min_length=2, max_length=100)
    bank_name: str = Field(..., min_length=2, max_length=100)
    account_number: str = Field(..., min_length=5, max_length=20)
    transit_number: str = Field(..., min_length=5, max_length=5)
    institution_number: str = Field(..., min_length=3, max_length=3)
    address: Optional[str] = Field(None, max_length=200)
    phone: Optional[str] = Field(None, regex=r"^\+?[0-9]{10,15}$")
    email: Optional[str] = Field(None, regex=r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$")
    
    class Config:
        """Pydantic config"""
        json_encoders = {
            Decimal: float
        }


class UPIDetails(BaseModel):
    """UPI payment details for the sender"""
    upi_id: str = Field(..., regex=r"^[a-zA-Z0-9\._-]+@[a-zA-Z][a-zA-Z]{2,}$")
    
    class Config:
        """Pydantic config"""
        json_encoders = {
            Decimal: float
        }


class RemittanceRequest(BaseModel):
    """Request model for creating a remittance"""
    amount_inr: Decimal = Field(..., gt=0)
    sender_id: str = Field(...)
    recipient: CanadianRecipient
    
    @validator('amount_inr')
    def validate_amount(cls, v):
        """Validate amount is within limits"""
        # These should come from config in a real implementation
        if v < Decimal('1000'):
            raise ValueError('Amount must be at least 1000 INR')
        if v > Decimal('100000'):
            raise ValueError('Amount cannot exceed 100,000 INR')
        return v
    
    class Config:
        """Pydantic config"""
        json_encoders = {
            Decimal: float
        }


class RemittanceResponse(BaseModel):
    """Response model for a remittance request"""
    transaction_id: str
    status: str
    amount_inr: Decimal
    amount_cad: Optional[Decimal] = None
    exchange_rate: Optional[Decimal] = None
    fees: Optional[Decimal] = None
    recipient: Dict[str, Any]
    created_at: datetime
    
    class Config:
        """Pydantic config"""
        json_encoders = {
            Decimal: float
        }


class RemittanceConfirmation(BaseModel):
    """Request model for confirming a remittance with payment"""
    upi_details: UPIDetails
    
    class Config:
        """Pydantic config"""
        json_encoders = {
            Decimal: float
        }


class ExchangeRateResponse(BaseModel):
    """Response model for exchange rate"""
    currency_pair: str
    rate: Decimal
    timestamp: datetime
    
    class Config:
        """Pydantic config"""
        json_encoders = {
            Decimal: float
        }


class RemittanceCalculation(BaseModel):
    """Model for remittance calculation"""
    amount_inr: Decimal
    exchange_rate: Decimal
    amount_cad: Decimal
    fee_percent: Decimal
    fee_amount: Decimal
    total_amount_inr: Decimal
    
    class Config:
        """Pydantic config"""
        json_encoders = {
            Decimal: float
        }


class WebhookEvent(BaseModel):
    """Base model for webhook events"""
    event_type: str
    event_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        """Pydantic config"""
        json_encoders = {
            Decimal: float
        }


class UPIPaymentEvent(WebhookEvent):
    """Webhook event model for UPI payment confirmations"""
    upi_reference: str
    transaction_id: str
    amount: Decimal
    status: str
    
    class Config:
        """Pydantic config"""
        json_encoders = {
            Decimal: float
        }


class WiseTransferEvent(WebhookEvent):
    """Webhook event model for Wise transfer updates"""
    transfer_id: str
    transaction_id: str
    status: str
    error_code: Optional[str] = None
    error_message: Optional[str] = None
    
    class Config:
        """Pydantic config"""
        json_encoders = {
            Decimal: float
        }


class ADBankEvent(WebhookEvent):
    """Webhook event model for AD Bank callbacks"""
    reference: str
    transaction_id: str
    status: str
    currency_pair: str
    source_amount: Decimal
    target_amount: Decimal
    error_code: Optional[str] = None
    
    class Config:
        """Pydantic config"""
        json_encoders = {
            Decimal: float
        }


class TransactionStatusResponse(BaseModel):
    """Response model for transaction status"""
    transaction_id: str
    status: str
    last_updated: datetime
    history: List[Dict[str, Any]]
    
    class Config:
        """Pydantic config"""
        json_encoders = {
            Decimal: float
        } 