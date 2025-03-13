from typing import Dict, Any, Optional
from decimal import Decimal
import httpx
import logging
import uuid
import json
from functools import lru_cache

from config.settings import get_settings

# Set up logging
logger = logging.getLogger(__name__)


class UPIService:
    """
    Service for integrating with UPI payment system in India
    
    This service handles:
    - Generating payment links for UPI payments
    - Verifying payment status
    - Processing payment callbacks
    """
    
    def __init__(self):
        """Initialize the UPI service with configuration"""
        self.settings = get_settings()
        self.api_url = self.settings.UPI_API_URL
        self.api_key = self.settings.UPI_API_KEY
        self.merchant_id = self.settings.UPI_MERCHANT_ID
        
        # Configure HTTP client
        self.client = httpx.AsyncClient(
            base_url=self.api_url,
            timeout=self.settings.DEFAULT_TIMEOUT_SECONDS,
            headers={
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json",
                "X-Merchant-ID": self.merchant_id
            }
        )
    
    async def __aenter__(self):
        """Async context manager entry"""
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit with client cleanup"""
        await self.client.aclose()
    
    async def generate_payment_link(
        self, 
        transaction_id: str, 
        amount: Decimal, 
        upi_id: str
    ) -> str:
        """
        Generate a UPI payment link for a transaction
        
        Args:
            transaction_id: The remittance transaction ID
            amount: The amount to pay in INR
            upi_id: The sender's UPI ID
            
        Returns:
            UPI payment link that the user can use to make the payment
        """
        try:
            # In a real implementation, this would call the UPI provider's API
            # For this demo, we'll simulate the API call
            
            # MOCK IMPLEMENTATION
            logger.info(f"Generating UPI payment link for transaction {transaction_id}")
            
            # For demo purposes, generate a dummy payment link
            upi_link = f"upi://pay?pa={self.merchant_id}@ybl&pn=RemitService&tr={transaction_id}&am={amount}&cu=INR"
            
            return upi_link
            
        except Exception as e:
            logger.error(f"Error generating UPI payment link: {str(e)}")
            raise
    
    async def verify_payment(self, upi_reference: str) -> Dict[str, Any]:
        """
        Verify a UPI payment using its reference
        
        Args:
            upi_reference: The UPI payment reference
            
        Returns:
            Payment details including status
        """
        try:
            # In a real implementation, this would call the UPI provider's API
            # For this demo, we'll simulate the API call
            
            # MOCK IMPLEMENTATION
            logger.info(f"Verifying UPI payment with reference {upi_reference}")
            
            # For demo purposes, always return success
            return {
                "reference": upi_reference,
                "status": "SUCCESS",
                "timestamp": "2023-01-01T12:00:00Z"
            }
            
        except Exception as e:
            logger.error(f"Error verifying UPI payment: {str(e)}")
            raise


@lru_cache()
def get_upi_service() -> UPIService:
    """Get or create a UPIService instance"""
    return UPIService() 