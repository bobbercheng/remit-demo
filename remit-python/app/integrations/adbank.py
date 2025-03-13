from typing import Dict, Any, Optional
from decimal import Decimal
import httpx
import logging
import uuid
import json
from functools import lru_cache
import random

from config.settings import get_settings

# Set up logging
logger = logging.getLogger(__name__)


class ADBankService:
    """
    Service for integrating with AD Bank for forex operations
    
    This service handles:
    - Getting exchange rates
    - Executing currency conversions
    - Processing conversion callbacks
    """
    
    def __init__(self):
        """Initialize the AD Bank service with configuration"""
        self.settings = get_settings()
        self.api_url = self.settings.ADBANK_API_URL
        self.api_key = self.settings.ADBANK_API_KEY
        self.client_id = self.settings.ADBANK_CLIENT_ID
        
        # Configure HTTP client
        self.client = httpx.AsyncClient(
            base_url=self.api_url,
            timeout=self.settings.DEFAULT_TIMEOUT_SECONDS,
            headers={
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json",
                "X-Client-ID": self.client_id
            }
        )
    
    async def __aenter__(self):
        """Async context manager entry"""
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit with client cleanup"""
        await self.client.aclose()
    
    async def get_exchange_rate(self, currency_pair: str) -> Decimal:
        """
        Get the current exchange rate for a currency pair
        
        Args:
            currency_pair: The currency pair (e.g., "INR_CAD")
            
        Returns:
            Current exchange rate as a Decimal
        """
        try:
            # In a real implementation, this would call the AD Bank API
            # For this demo, we'll simulate the API call
            
            # MOCK IMPLEMENTATION
            logger.info(f"Getting exchange rate for {currency_pair}")
            
            # For INR to CAD, use a realistic exchange rate
            # As of my knowledge, 1 INR is approximately 0.016-0.018 CAD
            if currency_pair == "INR_CAD":
                # Add a small random variation to simulate live rates
                base_rate = Decimal("0.017")
                variation = Decimal(str(random.uniform(-0.0005, 0.0005)))
                rate = base_rate + variation
                return rate.quantize(Decimal("0.000001"))
            else:
                raise ValueError(f"Unsupported currency pair: {currency_pair}")
            
        except Exception as e:
            logger.error(f"Error getting exchange rate: {str(e)}")
            raise
    
    async def convert_currency(
        self,
        transaction_id: str,
        source_currency: str,
        target_currency: str,
        amount: Decimal,
        exchange_rate: Optional[Decimal] = None
    ) -> str:
        """
        Initiate a currency conversion
        
        Args:
            transaction_id: The remittance transaction ID
            source_currency: Source currency code (e.g., "INR")
            target_currency: Target currency code (e.g., "CAD")
            amount: Amount in source currency
            exchange_rate: Optional fixed exchange rate
            
        Returns:
            Reference ID for the conversion
        """
        try:
            # In a real implementation, this would call the AD Bank API
            # For this demo, we'll simulate the API call
            
            # MOCK IMPLEMENTATION
            logger.info(f"Converting {amount} {source_currency} to {target_currency}")
            
            # Generate a reference ID for the conversion
            reference = f"ADBANK-{uuid.uuid4()}"
            
            return reference
            
        except Exception as e:
            logger.error(f"Error converting currency: {str(e)}")
            raise
    
    async def check_conversion_status(self, reference: str) -> Dict[str, Any]:
        """
        Check the status of a currency conversion
        
        Args:
            reference: The conversion reference ID
            
        Returns:
            Status details of the conversion
        """
        try:
            # In a real implementation, this would call the AD Bank API
            # For this demo, we'll simulate the API call
            
            # MOCK IMPLEMENTATION
            logger.info(f"Checking conversion status for {reference}")
            
            # For demo purposes, always return success
            return {
                "reference": reference,
                "status": "SUCCESS",
                "timestamp": "2023-01-01T12:00:00Z"
            }
            
        except Exception as e:
            logger.error(f"Error checking conversion status: {str(e)}")
            raise


@lru_cache()
def get_adbank_service() -> ADBankService:
    """Get or create an ADBankService instance"""
    return ADBankService() 