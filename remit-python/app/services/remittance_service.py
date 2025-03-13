from typing import Dict, List, Optional, Any, Tuple
from decimal import Decimal
from datetime import datetime
import logging
import uuid
from functools import lru_cache

from app.db.models import Transaction, TransactionStatus, EventType, TransactionEvent
from app.db.repositories import (
    get_transaction_repository, 
    get_transaction_event_repository,
    get_exchange_rate_repository
)
from app.models.remittance import (
    RemittanceRequest, 
    RemittanceResponse, 
    RemittanceConfirmation,
    RemittanceCalculation
)
from app.integrations.upi import UPIService, get_upi_service
from app.integrations.adbank import ADBankService, get_adbank_service
from app.integrations.wise import WiseService, get_wise_service
from config.settings import get_settings

# Set up logging
logger = logging.getLogger(__name__)


class RemittanceService:
    """
    Service for handling remittance business logic
    
    This service orchestrates the remittance process from initiation
    to completion, including payment processing, currency conversion,
    and fund transmission.
    """
    
    def __init__(
        self,
        transaction_repo=None,
        event_repo=None,
        exchange_rate_repo=None,
        upi_service=None,
        adbank_service=None,
        wise_service=None
    ):
        """Initialize service with repositories and integration services"""
        self.settings = get_settings()
        self.transaction_repo = transaction_repo or get_transaction_repository()
        self.event_repo = event_repo or get_transaction_event_repository()
        self.exchange_rate_repo = exchange_rate_repo or get_exchange_rate_repository()
        self.upi_service = upi_service or get_upi_service()
        self.adbank_service = adbank_service or get_adbank_service()
        self.wise_service = wise_service or get_wise_service()
    
    async def create_remittance(self, remittance_request: RemittanceRequest) -> RemittanceResponse:
        """
        Create a new remittance transaction
        
        This handles the initial creation of a remittance request, including:
        - Validating the request
        - Calculating exchange rates and fees
        - Creating the transaction record
        - Returning initial payment information
        
        The transaction remains in INITIATED status until the payment is
        confirmed in the next step.
        """
        # Calculate exchange rate and fees
        exchange_rate = await self.adbank_service.get_exchange_rate("INR_CAD")
        
        # Store the current exchange rate
        self.exchange_rate_repo.add_rate(
            currency_pair="INR_CAD",
            rate=exchange_rate,
            source="AD_BANK"
        )
        
        # Calculate converted amount
        amount_cad = remittance_request.amount_inr * exchange_rate
        
        # Calculate fee
        fee_percent = Decimal(str(self.settings.DEFAULT_SERVICE_FEE_PERCENT / 100))
        fees = remittance_request.amount_inr * fee_percent
        
        # Create transaction
        transaction = Transaction(
            user_id=remittance_request.sender_id,
            amount_inr=remittance_request.amount_inr,
            amount_cad=amount_cad,
            exchange_rate=exchange_rate,
            fees=fees,
            recipient_details=remittance_request.recipient.dict()
        )
        
        # Save transaction to database
        created_transaction = self.transaction_repo.create(transaction)
        
        # Log transaction creation event
        self.event_repo.add_event(
            transaction_id=created_transaction.transaction_id,
            event_type=EventType.TRANSACTION_CREATED,
            event_data={
                "amount_inr": str(created_transaction.amount_inr),
                "amount_cad": str(created_transaction.amount_cad),
                "exchange_rate": str(created_transaction.exchange_rate),
                "fees": str(created_transaction.fees)
            },
            actor=remittance_request.sender_id
        )
        
        # Return response
        return RemittanceResponse(
            transaction_id=created_transaction.transaction_id,
            status=created_transaction.status.value,
            amount_inr=created_transaction.amount_inr,
            amount_cad=created_transaction.amount_cad,
            exchange_rate=created_transaction.exchange_rate,
            fees=created_transaction.fees,
            recipient=created_transaction.recipient_details,
            created_at=created_transaction.created_at
        )
    
    async def confirm_remittance(
        self, 
        transaction_id: str, 
        confirmation: RemittanceConfirmation
    ) -> RemittanceResponse:
        """
        Confirm a remittance with payment information
        
        This handles the payment initiation step, including:
        - Updating the transaction with payment details
        - Initiating the UPI payment collection
        - Updating transaction status to PAYMENT_PENDING
        
        The actual payment confirmation will happen via webhook
        from the UPI provider.
        """
        # Get the transaction
        transaction = self.transaction_repo.get_by_id(transaction_id)
        if not transaction:
            raise ValueError(f"Transaction {transaction_id} not found")
        
        # Check if the transaction is in a valid state
        if transaction.status != TransactionStatus.INITIATED:
            raise ValueError(f"Transaction {transaction_id} is not in INITIATED state")
        
        # Generate UPI payment link
        upi_link = await self.upi_service.generate_payment_link(
            transaction_id=transaction_id,
            amount=transaction.amount_inr + transaction.fees,
            upi_id=confirmation.upi_details.upi_id
        )
        
        # Update transaction with payment details and status
        updated_transaction = self.transaction_repo.update_status(
            transaction_id=transaction_id,
            status=TransactionStatus.PAYMENT_PENDING,
            additional_updates={
                "payment_details": {
                    "upi_id": confirmation.upi_details.upi_id,
                    "upi_link": upi_link
                }
            }
        )
        
        # Log payment initiation event
        self.event_repo.add_event(
            transaction_id=transaction_id,
            event_type=EventType.PAYMENT_INITIATED,
            event_data={
                "upi_id": confirmation.upi_details.upi_id,
                "amount": str(transaction.amount_inr + transaction.fees)
            },
            actor="system"
        )
        
        # Return updated response
        return RemittanceResponse(
            transaction_id=updated_transaction.transaction_id,
            status=updated_transaction.status.value,
            amount_inr=updated_transaction.amount_inr,
            amount_cad=updated_transaction.amount_cad,
            exchange_rate=updated_transaction.exchange_rate,
            fees=updated_transaction.fees,
            recipient=updated_transaction.recipient_details,
            created_at=updated_transaction.created_at
        )
    
    async def process_upi_payment_confirmation(self, event_data: Dict[str, Any]) -> bool:
        """
        Process UPI payment confirmation webhook
        
        This handles the payment confirmation from UPI, including:
        - Verifying the payment details
        - Updating the transaction status
        - Initiating the currency conversion with AD Bank
        
        The transaction moves from PAYMENT_PENDING to CONVERSION_IN_PROGRESS.
        """
        transaction_id = event_data.get("transaction_id")
        status = event_data.get("status")
        
        # Get the transaction
        transaction = self.transaction_repo.get_by_id(transaction_id)
        if not transaction:
            logger.error(f"Transaction {transaction_id} not found for UPI confirmation")
            return False
        
        # Check if payment was successful
        if status != "SUCCESS":
            # Update transaction status to FAILED
            self.transaction_repo.update_status(
                transaction_id=transaction_id,
                status=TransactionStatus.FAILED,
                additional_updates={
                    "failure_reason": f"UPI payment failed: {event_data.get('error_message', 'Unknown error')}"
                }
            )
            
            # Log payment failure event
            self.event_repo.add_event(
                transaction_id=transaction_id,
                event_type=EventType.TRANSACTION_FAILED,
                event_data=event_data,
                actor="system"
            )
            
            return False
        
        # Update transaction status and add UPI reference
        updated_transaction = self.transaction_repo.update_status(
            transaction_id=transaction_id,
            status=TransactionStatus.PAYMENT_RECEIVED,
            additional_updates={
                "payment_details": {
                    **transaction.payment_details,
                    "upi_reference": event_data.get("upi_reference")
                }
            }
        )
        
        # Log payment received event
        self.event_repo.add_event(
            transaction_id=transaction_id,
            event_type=EventType.PAYMENT_RECEIVED,
            event_data=event_data,
            actor="system"
        )
        
        # Initiate currency conversion with AD Bank
        try:
            conversion_reference = await self.adbank_service.convert_currency(
                transaction_id=transaction_id,
                source_currency="INR",
                target_currency="CAD",
                amount=transaction.amount_inr,
                exchange_rate=transaction.exchange_rate
            )
            
            # Update transaction with AD Bank reference
            self.transaction_repo.update_status(
                transaction_id=transaction_id,
                status=TransactionStatus.CONVERSION_IN_PROGRESS,
                additional_updates={
                    "ad_bank_reference": conversion_reference
                }
            )
            
            # Log conversion initiation event
            self.event_repo.add_event(
                transaction_id=transaction_id,
                event_type=EventType.CONVERSION_INITIATED,
                event_data={
                    "ad_bank_reference": conversion_reference,
                    "amount_inr": str(transaction.amount_inr),
                    "amount_cad": str(transaction.amount_cad),
                    "exchange_rate": str(transaction.exchange_rate)
                },
                actor="system"
            )
            
            return True
            
        except Exception as e:
            logger.error(f"Error initiating currency conversion: {str(e)}")
            # Update transaction status to FAILED
            self.transaction_repo.update_status(
                transaction_id=transaction_id,
                status=TransactionStatus.FAILED,
                additional_updates={
                    "failure_reason": f"Currency conversion failed: {str(e)}"
                }
            )
            
            # Log conversion failure event
            self.event_repo.add_event(
                transaction_id=transaction_id,
                event_type=EventType.TRANSACTION_FAILED,
                event_data={"error": str(e)},
                actor="system"
            )
            
            return False
    
    async def process_adbank_conversion_callback(self, event_data: Dict[str, Any]) -> bool:
        """
        Process AD Bank currency conversion callback
        
        This handles the currency conversion confirmation, including:
        - Verifying the conversion details
        - Updating the transaction status
        - Initiating the transfer to Canada via Wise
        
        The transaction moves from CONVERSION_IN_PROGRESS to FUNDS_SENT.
        """
        transaction_id = event_data.get("transaction_id")
        status = event_data.get("status")
        
        # Get the transaction
        transaction = self.transaction_repo.get_by_id(transaction_id)
        if not transaction:
            logger.error(f"Transaction {transaction_id} not found for AD Bank callback")
            return False
        
        # Check if conversion was successful
        if status != "SUCCESS":
            # Update transaction status to FAILED
            self.transaction_repo.update_status(
                transaction_id=transaction_id,
                status=TransactionStatus.FAILED,
                additional_updates={
                    "failure_reason": f"Currency conversion failed: {event_data.get('error_message', 'Unknown error')}"
                }
            )
            
            # Log conversion failure event
            self.event_repo.add_event(
                transaction_id=transaction_id,
                event_type=EventType.TRANSACTION_FAILED,
                event_data=event_data,
                actor="system"
            )
            
            return False
        
        # Update transaction status
        self.transaction_repo.update_status(
            transaction_id=transaction_id,
            status=TransactionStatus.CONVERSION_COMPLETE
        )
        
        # Log conversion completion event
        self.event_repo.add_event(
            transaction_id=transaction_id,
            event_type=EventType.CONVERSION_COMPLETED,
            event_data=event_data,
            actor="system"
        )
        
        # Initiate transfer to Canada via Wise
        try:
            # Extract recipient details
            recipient_details = transaction.recipient_details
            
            # Create transfer via Wise
            transfer_id = await self.wise_service.create_transfer(
                transaction_id=transaction_id,
                source_currency="CAD",
                target_currency="CAD",  # Same currency as it's within Canada
                amount=transaction.amount_cad,
                recipient={
                    "full_name": recipient_details.get("full_name"),
                    "bank_name": recipient_details.get("bank_name"),
                    "account_number": recipient_details.get("account_number"),
                    "transit_number": recipient_details.get("transit_number"),
                    "institution_number": recipient_details.get("institution_number")
                }
            )
            
            # Update transaction with Wise transfer ID
            self.transaction_repo.update_status(
                transaction_id=transaction_id,
                status=TransactionStatus.FUNDS_SENT,
                additional_updates={
                    "wise_transfer_id": transfer_id
                }
            )
            
            # Log transfer initiation event
            self.event_repo.add_event(
                transaction_id=transaction_id,
                event_type=EventType.TRANSFER_INITIATED,
                event_data={
                    "wise_transfer_id": transfer_id,
                    "amount_cad": str(transaction.amount_cad)
                },
                actor="system"
            )
            
            return True
            
        except Exception as e:
            logger.error(f"Error initiating transfer to Canada: {str(e)}")
            # Update transaction status to FAILED
            self.transaction_repo.update_status(
                transaction_id=transaction_id,
                status=TransactionStatus.FAILED,
                additional_updates={
                    "failure_reason": f"Transfer to Canada failed: {str(e)}"
                }
            )
            
            # Log transfer failure event
            self.event_repo.add_event(
                transaction_id=transaction_id,
                event_type=EventType.TRANSACTION_FAILED,
                event_data={"error": str(e)},
                actor="system"
            )
            
            return False
    
    async def process_wise_transfer_callback(self, event_data: Dict[str, Any]) -> bool:
        """
        Process Wise transfer callback
        
        This handles the transfer completion notification, including:
        - Verifying the transfer details
        - Updating the transaction status to COMPLETED
        
        This is the final step in the remittance process.
        """
        transaction_id = event_data.get("transaction_id")
        status = event_data.get("status")
        
        # Get the transaction
        transaction = self.transaction_repo.get_by_id(transaction_id)
        if not transaction:
            logger.error(f"Transaction {transaction_id} not found for Wise callback")
            return False
        
        # Check if transfer was successful
        if status != "SUCCESS":
            # Update transaction status to FAILED
            self.transaction_repo.update_status(
                transaction_id=transaction_id,
                status=TransactionStatus.FAILED,
                additional_updates={
                    "failure_reason": f"Transfer to Canada failed: {event_data.get('error_message', 'Unknown error')}"
                }
            )
            
            # Log transfer failure event
            self.event_repo.add_event(
                transaction_id=transaction_id,
                event_type=EventType.TRANSACTION_FAILED,
                event_data=event_data,
                actor="system"
            )
            
            return False
        
        # Update transaction status to COMPLETED
        self.transaction_repo.update_status(
            transaction_id=transaction_id,
            status=TransactionStatus.COMPLETED
        )
        
        # Log transfer completion event
        self.event_repo.add_event(
            transaction_id=transaction_id,
            event_type=EventType.TRANSFER_COMPLETED,
            event_data=event_data,
            actor="system"
        )
        
        # Log transaction completion event
        self.event_repo.add_event(
            transaction_id=transaction_id,
            event_type=EventType.TRANSACTION_COMPLETED,
            event_data={
                "completed_at": datetime.utcnow().isoformat()
            },
            actor="system"
        )
        
        return True
    
    async def get_transaction_status(self, transaction_id: str) -> Dict[str, Any]:
        """
        Get the current status of a transaction
        
        Returns:
            Dict with transaction status details and history
        """
        # Get the transaction
        transaction = self.transaction_repo.get_by_id(transaction_id)
        if not transaction:
            raise ValueError(f"Transaction {transaction_id} not found")
        
        # Get transaction events
        events = self.event_repo.get_events_for_transaction(transaction_id)
        
        # Format events for response
        history = [
            {
                "event_type": event.event_type.value,
                "timestamp": event.event_timestamp.isoformat(),
                "data": event.event_data
            }
            for event in sorted(events, key=lambda x: x.event_timestamp)
        ]
        
        return {
            "transaction_id": transaction.transaction_id,
            "status": transaction.status.value,
            "last_updated": transaction.updated_at,
            "history": history
        }
    
    async def calculate_remittance(self, amount_inr: Decimal) -> RemittanceCalculation:
        """
        Calculate remittance details without creating a transaction
        
        This is useful for displaying estimated amounts to the user
        before they commit to a transaction.
        
        Args:
            amount_inr: Amount in INR to convert
            
        Returns:
            RemittanceCalculation with conversion details
        """
        # Get exchange rate
        exchange_rate = await self.adbank_service.get_exchange_rate("INR_CAD")
        
        # Calculate converted amount
        amount_cad = amount_inr * exchange_rate
        
        # Calculate fee
        fee_percent = Decimal(str(self.settings.DEFAULT_SERVICE_FEE_PERCENT / 100))
        fee_amount = amount_inr * fee_percent
        
        # Calculate total amount including fees
        total_amount_inr = amount_inr + fee_amount
        
        return RemittanceCalculation(
            amount_inr=amount_inr,
            exchange_rate=exchange_rate,
            amount_cad=amount_cad,
            fee_percent=fee_percent * Decimal("100"),  # Convert back to percentage
            fee_amount=fee_amount,
            total_amount_inr=total_amount_inr
        )


@lru_cache()
def get_remittance_service() -> RemittanceService:
    """Get or create a RemittanceService instance"""
    return RemittanceService() 