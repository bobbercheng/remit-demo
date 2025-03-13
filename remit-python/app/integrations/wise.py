from typing import Dict, Any, Optional, List
from decimal import Decimal
import httpx
import logging
import uuid
import json
from functools import lru_cache

from config.settings import get_settings

# Set up logging
logger = logging.getLogger(__name__)


class WiseService:
    """
    Service for integrating with Wise for international transfers
    
    This service handles:
    - Creating transfers to Canadian bank accounts
    - Checking transfer status
    - Processing transfer callbacks
    """
    
    def __init__(self):
        """Initialize the Wise service with configuration"""
        self.settings = get_settings()
        self.api_url = self.settings.WISE_API_URL
        self.api_key = self.settings.WISE_API_KEY
        self.profile_id = self.settings.WISE_PROFILE_ID
        
        # Configure HTTP client
        self.client = httpx.AsyncClient(
            base_url=self.api_url,
            timeout=self.settings.DEFAULT_TIMEOUT_SECONDS,
            headers={
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json"
            }
        )
    
    async def __aenter__(self):
        """Async context manager entry"""
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit with client cleanup"""
        await self.client.aclose()
    
    async def create_transfer(
        self,
        transaction_id: str,
        source_currency: str,
        target_currency: str,
        amount: Decimal,
        recipient: Dict[str, Any]
    ) -> str:
        """
        Create a transfer to a Canadian bank account
        
        Args:
            transaction_id: The remittance transaction ID
            source_currency: Source currency code (e.g., "CAD")
            target_currency: Target currency code (e.g., "CAD")
            amount: Amount in source currency
            recipient: Dictionary of recipient details
            
        Returns:
            Transfer ID for tracking
        """
        try:
            # In a real implementation, this would call the Wise API
            # For this demo, we'll simulate the API call
            
            # MOCK IMPLEMENTATION
            logger.info(f"Creating Wise transfer for {amount} {source_currency} to {target_currency}")
            
            # Generate a transfer ID
            transfer_id = f"WISE-{uuid.uuid4()}"
            
            return transfer_id
            
        except Exception as e:
            logger.error(f"Error creating Wise transfer: {str(e)}")
            raise
    
    async def get_transfer_status(self, transfer_id: str) -> Dict[str, Any]:
        """
        Get the status of a transfer
        
        Args:
            transfer_id: The Wise transfer ID
            
        Returns:
            Status details of the transfer
        """
        try:
            # In a real implementation, this would call the Wise API
            # For this demo, we'll simulate the API call
            
            # MOCK IMPLEMENTATION
            logger.info(f"Checking Wise transfer status for {transfer_id}")
            
            # For demo purposes, always return success
            return {
                "id": transfer_id,
                "status": "SUCCESS",
                "source_amount": "1000.00",
                "source_currency": "CAD",
                "target_amount": "1000.00",
                "target_currency": "CAD",
                "timestamp": "2023-01-01T12:00:00Z"
            }
            
        except Exception as e:
            logger.error(f"Error getting Wise transfer status: {str(e)}")
            raise
    
    async def cancel_transfer(self, transfer_id: str) -> bool:
        """
        Cancel a transfer if possible
        
        Args:
            transfer_id: The Wise transfer ID
            
        Returns:
            True if cancelled successfully, False otherwise
        """
        try:
            # In a real implementation, this would call the Wise API
            # For this demo, we'll simulate the API call
            
            # MOCK IMPLEMENTATION
            logger.info(f"Cancelling Wise transfer {transfer_id}")
            
            # For demo purposes, always return success
            return True
            
        except Exception as e:
            logger.error(f"Error cancelling Wise transfer: {str(e)}")
            raise


@lru_cache()
def get_wise_service() -> WiseService:
    """Get or create a WiseService instance"""
    return WiseService() 