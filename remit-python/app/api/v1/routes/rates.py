from typing import Dict, List, Any
from fastapi import APIRouter, HTTPException, Depends, Query
from datetime import datetime, timedelta

from app.services.remittance_service import get_remittance_service, RemittanceService
from app.integrations.adbank import get_adbank_service, ADBankService
from app.models.remittance import ExchangeRateResponse
from app.db.repositories import get_exchange_rate_repository

# Create router
router = APIRouter()


@router.get("/current", response_model=ExchangeRateResponse)
async def get_current_rate(
    currency_pair: str = Query("INR_CAD", description="The currency pair to get the rate for"),
    adbank_service: ADBankService = Depends(get_adbank_service)
) -> ExchangeRateResponse:
    """
    Get the current exchange rate for a currency pair
    
    This endpoint returns the current exchange rate for a currency pair.
    By default, it returns the rate for INR to CAD.
    """
    try:
        rate = await adbank_service.get_exchange_rate(currency_pair)
        
        return ExchangeRateResponse(
            currency_pair=currency_pair,
            rate=rate,
            timestamp=datetime.utcnow()
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error getting exchange rate: {str(e)}")


@router.get("/historical", response_model=List[ExchangeRateResponse])
async def get_historical_rates(
    currency_pair: str = Query("INR_CAD", description="The currency pair to get rates for"),
    days: int = Query(7, description="Number of days of historical data to retrieve", ge=1, le=30)
) -> List[ExchangeRateResponse]:
    """
    Get historical exchange rates for a currency pair
    
    This endpoint returns historical exchange rates for a currency pair
    over a specified number of days.
    """
    try:
        # Get exchange rate repository
        repo = get_exchange_rate_repository()
        
        # Get historical rates
        rates = repo.get_historical_rates(currency_pair, days)
        
        # Convert to response model
        result = []
        for rate in rates:
            result.append(ExchangeRateResponse(
                currency_pair=rate.currency_pair,
                rate=rate.rate,
                timestamp=rate.timestamp
            ))
        
        # If no historical data, generate mock data
        if not result:
            # Generate mock historical data
            # In a real implementation, this would be from actual stored data
            base_date = datetime.utcnow()
            for i in range(days):
                date = base_date - timedelta(days=i)
                
                # Slight variation in rate to simulate market fluctuations
                # Around 0.017 CAD per INR with small random variations
                import random
                base_rate = 0.017
                variation = random.uniform(-0.0005, 0.0005)
                rate = base_rate + variation
                
                result.append(ExchangeRateResponse(
                    currency_pair=currency_pair,
                    rate=rate,
                    timestamp=date
                ))
        
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error getting historical rates: {str(e)}") 