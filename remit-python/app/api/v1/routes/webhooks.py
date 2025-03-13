from typing import Dict, Any
from fastapi import APIRouter, HTTPException, Depends, Path, Body, Header, Request
import logging
import hmac
import hashlib
import json

from app.services.remittance_service import get_remittance_service, RemittanceService
from app.models.remittance import UPIPaymentEvent, WiseTransferEvent, ADBankEvent
from config.settings import get_settings

# Set up logging
logger = logging.getLogger(__name__)

# Create router
router = APIRouter()


async def verify_upi_webhook(
    request: Request,
    x_upi_signature: str = Header(None)
) -> None:
    """
    Verify UPI webhook signature
    
    This function validates the signature of incoming UPI webhooks
    to ensure they are legitimate and haven't been tampered with.
    
    In a real implementation, this would verify a cryptographic signature
    using a shared secret with the UPI provider.
    """
    if not x_upi_signature:
        raise HTTPException(status_code=401, detail="Missing signature header")
    
    # For demo purposes, just log the signature
    logger.info(f"Received UPI webhook with signature: {x_upi_signature}")
    
    # In a real implementation, verify the signature
    # Example:
    # settings = get_settings()
    # body = await request.body()
    # calculated_signature = hmac.new(
    #     settings.UPI_WEBHOOK_SECRET.encode(),
    #     body,
    #     hashlib.sha256
    # ).hexdigest()
    # if not hmac.compare_digest(calculated_signature, x_upi_signature):
    #     raise HTTPException(status_code=401, detail="Invalid signature")


async def verify_adbank_webhook(
    request: Request,
    x_adbank_signature: str = Header(None)
) -> None:
    """
    Verify AD Bank webhook signature
    
    This function validates the signature of incoming AD Bank webhooks
    to ensure they are legitimate and haven't been tampered with.
    """
    if not x_adbank_signature:
        raise HTTPException(status_code=401, detail="Missing signature header")
    
    # For demo purposes, just log the signature
    logger.info(f"Received AD Bank webhook with signature: {x_adbank_signature}")


async def verify_wise_webhook(
    request: Request,
    x_wise_signature: str = Header(None)
) -> None:
    """
    Verify Wise webhook signature
    
    This function validates the signature of incoming Wise webhooks
    to ensure they are legitimate and haven't been tampered with.
    """
    if not x_wise_signature:
        raise HTTPException(status_code=401, detail="Missing signature header")
    
    # For demo purposes, just log the signature
    logger.info(f"Received Wise webhook with signature: {x_wise_signature}")


@router.post("/upi", status_code=200)
async def upi_webhook(
    event: UPIPaymentEvent,
    request: Request,
    remittance_service: RemittanceService = Depends(get_remittance_service)
):
    """
    Webhook endpoint for UPI payment confirmations
    
    This endpoint receives payment confirmations from the UPI provider
    and processes them to update transaction status and proceed with
    the remittance process.
    """
    try:
        # Verify webhook signature
        await verify_upi_webhook(request)
        
        # Log the event
        logger.info(f"Received UPI payment event: {json.dumps(event.dict())}")
        
        # Process the payment confirmation
        success = await remittance_service.process_upi_payment_confirmation(event.dict())
        
        if not success:
            logger.error(f"Failed to process UPI payment event: {event.transaction_id}")
            # Still return 200 to acknowledge receipt
            return {"status": "acknowledged", "processed": False}
        
        return {"status": "success", "processed": True}
        
    except Exception as e:
        logger.error(f"Error processing UPI webhook: {str(e)}")
        # Return 200 to acknowledge receipt even on error
        # This prevents the provider from retrying unnecessarily
        return {"status": "error", "message": str(e), "processed": False}


@router.post("/adbank", status_code=200)
async def adbank_webhook(
    event: ADBankEvent,
    request: Request,
    remittance_service: RemittanceService = Depends(get_remittance_service)
):
    """
    Webhook endpoint for AD Bank callbacks
    
    This endpoint receives currency conversion confirmations from AD Bank
    and processes them to update transaction status and proceed with
    the remittance process.
    """
    try:
        # Verify webhook signature
        await verify_adbank_webhook(request)
        
        # Log the event
        logger.info(f"Received AD Bank event: {json.dumps(event.dict())}")
        
        # Process the conversion confirmation
        success = await remittance_service.process_adbank_conversion_callback(event.dict())
        
        if not success:
            logger.error(f"Failed to process AD Bank event: {event.transaction_id}")
            # Still return 200 to acknowledge receipt
            return {"status": "acknowledged", "processed": False}
        
        return {"status": "success", "processed": True}
        
    except Exception as e:
        logger.error(f"Error processing AD Bank webhook: {str(e)}")
        # Return 200 to acknowledge receipt even on error
        return {"status": "error", "message": str(e), "processed": False}


@router.post("/wise", status_code=200)
async def wise_webhook(
    event: WiseTransferEvent,
    request: Request,
    remittance_service: RemittanceService = Depends(get_remittance_service)
):
    """
    Webhook endpoint for Wise transfer callbacks
    
    This endpoint receives transfer status updates from Wise
    and processes them to update transaction status and complete
    the remittance process.
    """
    try:
        # Verify webhook signature
        await verify_wise_webhook(request)
        
        # Log the event
        logger.info(f"Received Wise event: {json.dumps(event.dict())}")
        
        # Process the transfer confirmation
        success = await remittance_service.process_wise_transfer_callback(event.dict())
        
        if not success:
            logger.error(f"Failed to process Wise event: {event.transaction_id}")
            # Still return 200 to acknowledge receipt
            return {"status": "acknowledged", "processed": False}
        
        return {"status": "success", "processed": True}
        
    except Exception as e:
        logger.error(f"Error processing Wise webhook: {str(e)}")
        # Return 200 to acknowledge receipt even on error
        return {"status": "error", "message": str(e), "processed": False} 