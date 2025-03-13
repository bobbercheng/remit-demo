from typing import Dict, List, Any, Optional
from fastapi import APIRouter, HTTPException, Depends, Query, Path, Body
from decimal import Decimal
from pydantic import parse_obj_as

from app.services.remittance_service import get_remittance_service, RemittanceService
from app.models.remittance import (
    RemittanceRequest,
    RemittanceResponse,
    RemittanceConfirmation,
    RemittanceCalculation,
    TransactionStatusResponse
)

# Create router
router = APIRouter()


@router.post("/", response_model=RemittanceResponse)
async def create_remittance(
    remittance_request: RemittanceRequest,
    remittance_service: RemittanceService = Depends(get_remittance_service)
) -> RemittanceResponse:
    """
    Create a new remittance transaction
    
    This endpoint initiates a new remittance from India to Canada.
    It performs the following:
    - Validates the request
    - Calculates exchange rates and fees
    - Creates the transaction record
    - Returns initial transaction details
    
    The transaction will be in INITIATED status until payment is confirmed.
    """
    try:
        return await remittance_service.create_remittance(remittance_request)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error creating remittance: {str(e)}")


@router.post("/{transaction_id}/confirm", response_model=RemittanceResponse)
async def confirm_remittance(
    transaction_id: str = Path(..., description="The transaction ID to confirm"),
    confirmation: RemittanceConfirmation = Body(...),
    remittance_service: RemittanceService = Depends(get_remittance_service)
) -> RemittanceResponse:
    """
    Confirm a remittance with payment details
    
    This endpoint confirms a remittance transaction with payment details.
    It performs the following:
    - Validates the transaction exists and is in INITIATED status
    - Updates the transaction with payment details
    - Generates a UPI payment link
    - Updates the transaction status to PAYMENT_PENDING
    
    The actual payment confirmation happens via webhook from the UPI provider.
    """
    try:
        return await remittance_service.confirm_remittance(transaction_id, confirmation)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error confirming remittance: {str(e)}")


@router.get("/{transaction_id}", response_model=TransactionStatusResponse)
async def get_remittance_status(
    transaction_id: str = Path(..., description="The transaction ID to check"),
    remittance_service: RemittanceService = Depends(get_remittance_service)
) -> TransactionStatusResponse:
    """
    Get the status of a remittance transaction
    
    This endpoint returns the current status and history of a remittance transaction.
    """
    try:
        status_data = await remittance_service.get_transaction_status(transaction_id)
        return TransactionStatusResponse(**status_data)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error getting remittance status: {str(e)}")


@router.get("/", response_model=List[RemittanceResponse])
async def list_remittances(
    user_id: str = Query(..., description="User ID to list remittances for"),
    limit: int = Query(20, description="Maximum number of results to return"),
    offset: int = Query(0, description="Number of results to skip"),
    remittance_service: RemittanceService = Depends(get_remittance_service)
) -> List[RemittanceResponse]:
    """
    List remittance transactions for a user
    
    This endpoint returns a list of remittance transactions
    for a specific user, with pagination support.
    """
    # This would typically call a service method to get user transactions
    # For demo purposes, just return an empty list
    return []


@router.post("/calculate", response_model=RemittanceCalculation)
async def calculate_remittance(
    amount_inr: Decimal = Body(..., embed=True),
    remittance_service: RemittanceService = Depends(get_remittance_service)
) -> RemittanceCalculation:
    """
    Calculate remittance details without creating a transaction
    
    This endpoint calculates the conversion amount, fees, and total
    for a potential remittance transaction without creating one.
    
    This is useful for displaying estimated amounts to the user
    before they commit to a transaction.
    """
    try:
        return await remittance_service.calculate_remittance(amount_inr)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error calculating remittance: {str(e)}") 