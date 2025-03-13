import { NextRequest, NextResponse } from 'next/server';
import { rateRepository } from '@/lib/db/repositories/rate-repository';
import { Currency } from '@/types';

/**
 * GET /api/exchange-rate/history
 * 
 * Get historical exchange rates
 */
export async function GET(req: NextRequest) {
  try {
    // Get source and destination currencies from query parameters, with defaults
    const sourceCurrency = (req.nextUrl.searchParams.get('sourceCurrency') as Currency) || Currency.INR;
    const destinationCurrency = (req.nextUrl.searchParams.get('destinationCurrency') as Currency) || Currency.CAD;
    
    // Get limit from query parameter, with default
    const limit = parseInt(req.nextUrl.searchParams.get('limit') || '30', 10);
    
    // Validate currencies
    if (sourceCurrency !== Currency.INR || destinationCurrency !== Currency.CAD) {
      return NextResponse.json(
        { 
          error: {
            code: 'INVALID_PARAMETER',
            message: 'Only INR to CAD exchange rates are supported',
          }
        }, 
        { status: 400 }
      );
    }
    
    // Get historical rates
    const rateHistory = await rateRepository.getExchangeRateHistory(
      sourceCurrency, 
      destinationCurrency,
      limit
    );
    
    // Return the rate history
    return NextResponse.json({
      sourceCurrency,
      destinationCurrency,
      rates: rateHistory.map(rate => ({
        rate: rate.rate,
        timestamp: rate.timestamp,
      })),
    });
  } catch (error) {
    console.error('Error fetching exchange rate history:', error);
    
    // Handle errors
    return NextResponse.json(
      { 
        error: {
          code: 'INTERNAL_SERVER_ERROR',
          message: error instanceof Error ? error.message : 'An unexpected error occurred',
        }
      }, 
      { status: 500 }
    );
  }
} 