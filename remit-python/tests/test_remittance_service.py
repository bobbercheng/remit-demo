import pytest
from decimal import Decimal
from datetime import datetime
import uuid
from unittest.mock import AsyncMock, patch, MagicMock

from app.services.remittance_service import RemittanceService
from app.db.models import Transaction, TransactionStatus, EventType
from app.models.remittance import RemittanceRequest, CanadianRecipient, RemittanceResponse


# Sample test data
@pytest.fixture
def sample_recipient():
    return CanadianRecipient(
        full_name="John Doe",
        bank_name="Royal Bank of Canada",
        account_number="12345678",
        transit_number="12345",
        institution_number="123",
        phone="+16135551234",
        email="john.doe@example.com"
    )


@pytest.fixture
def sample_remittance_request(sample_recipient):
    return RemittanceRequest(
        amount_inr=Decimal("10000"),
        sender_id="user123",
        recipient=sample_recipient
    )


@pytest.fixture
def mock_transaction():
    return Transaction(
        transaction_id="test-transaction-id",
        user_id="user123",
        amount_inr=Decimal("10000"),
        amount_cad=Decimal("170"),
        exchange_rate=Decimal("0.017"),
        fees=Decimal("50"),
        recipient_details={
            "full_name": "John Doe",
            "bank_name": "Royal Bank of Canada",
            "account_number": "12345678",
            "transit_number": "12345",
            "institution_number": "123",
            "phone": "+16135551234",
            "email": "john.doe@example.com"
        }
    )


# Test creating a remittance
@pytest.mark.asyncio
async def test_create_remittance(sample_remittance_request, mock_transaction):
    # Create mocks
    mock_transaction_repo = MagicMock()
    mock_event_repo = MagicMock()
    mock_exchange_rate_repo = MagicMock()
    mock_upi_service = MagicMock()
    mock_adbank_service = AsyncMock()
    mock_wise_service = MagicMock()
    
    # Configure mocks
    mock_transaction_repo.create.return_value = mock_transaction
    mock_adbank_service.get_exchange_rate.return_value = Decimal("0.017")
    
    # Create service with mocks
    service = RemittanceService(
        transaction_repo=mock_transaction_repo,
        event_repo=mock_event_repo,
        exchange_rate_repo=mock_exchange_rate_repo,
        upi_service=mock_upi_service,
        adbank_service=mock_adbank_service,
        wise_service=mock_wise_service
    )
    
    # Call the method
    result = await service.create_remittance(sample_remittance_request)
    
    # Assertions
    assert isinstance(result, RemittanceResponse)
    assert result.transaction_id == mock_transaction.transaction_id
    assert result.amount_inr == mock_transaction.amount_inr
    assert result.amount_cad == mock_transaction.amount_cad
    assert result.status == TransactionStatus.INITIATED.value
    
    # Verify interactions
    mock_adbank_service.get_exchange_rate.assert_called_once_with("INR_CAD")
    mock_exchange_rate_repo.add_rate.assert_called_once()
    mock_transaction_repo.create.assert_called_once()
    mock_event_repo.add_event.assert_called_once()


# Test calculating remittance
@pytest.mark.asyncio
async def test_calculate_remittance():
    # Create mocks
    mock_adbank_service = AsyncMock()
    
    # Configure mocks
    mock_adbank_service.get_exchange_rate.return_value = Decimal("0.017")
    
    # Create service with mocks
    service = RemittanceService(
        adbank_service=mock_adbank_service
    )
    
    # Call the method
    result = await service.calculate_remittance(Decimal("10000"))
    
    # Assertions
    assert result.amount_inr == Decimal("10000")
    assert result.exchange_rate == Decimal("0.017")
    assert result.amount_cad == Decimal("10000") * Decimal("0.017")
    assert result.fee_percent == Decimal("0.5")
    
    # Verify interactions
    mock_adbank_service.get_exchange_rate.assert_called_once_with("INR_CAD")


# Test processing UPI payment confirmation - success case
@pytest.mark.asyncio
async def test_process_upi_payment_confirmation_success(mock_transaction):
    # Create mocks
    mock_transaction_repo = MagicMock()
    mock_event_repo = MagicMock()
    mock_adbank_service = AsyncMock()
    
    # Configure mocks
    mock_transaction_repo.get_by_id.return_value = mock_transaction
    mock_transaction_repo.update_status.return_value = mock_transaction
    mock_adbank_service.convert_currency.return_value = "ADBANK-123456"
    
    # Create service with mocks
    service = RemittanceService(
        transaction_repo=mock_transaction_repo,
        event_repo=mock_event_repo,
        adbank_service=mock_adbank_service
    )
    
    # Event data
    event_data = {
        "transaction_id": "test-transaction-id",
        "status": "SUCCESS",
        "upi_reference": "UPI12345"
    }
    
    # Call the method
    result = await service.process_upi_payment_confirmation(event_data)
    
    # Assertions
    assert result is True
    
    # Verify interactions
    mock_transaction_repo.get_by_id.assert_called_once_with("test-transaction-id")
    assert mock_transaction_repo.update_status.call_count == 2
    assert mock_event_repo.add_event.call_count == 2
    mock_adbank_service.convert_currency.assert_called_once() 