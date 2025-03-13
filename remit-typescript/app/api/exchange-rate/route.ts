import { NextRequest, NextResponse } from 'next/server';
import adBankIntegration from '@/lib/integrations/adbank';
import { rateRepository } from '@/lib/db/repositories/rate-repository';
import { Currency } from '@/types';

/**
 * GET /api/exchange-rate
 * 
 * Get the current exchange rate for INR to CAD
 */
export async function GET(req: NextRequest) {
  try {
    // Get source and destination currencies from query parameters, with defaults
    const sourceCurrency = (req.nextUrl.searchParams.get('sourceCurrency') as Currency) || Currency.INR;
    const destinationCurrency = (req.nextUrl.searchParams.get('destinationCurrency') as Currency) || Currency.CAD;
    
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
    
    // Get the latest rate
    const mode = req.nextUrl.searchParams.get('mode') || 'live';
    
    let rateResponse;
    
    if (mode === 'cached') {
      // Try to get the rate from cache/database first
      rateResponse = await rateRepository.getLatestExchangeRate(
        sourceCurrency, 
        destinationCurrency
      );
      
      // If no cached rate, fall back to live rate
      if (!rateResponse) {
        rateResponse = await adBankIntegration.getExchangeRate(
          sourceCurrency, 
          destinationCurrency
        );
      }
    } else {
      // Get a fresh rate from the AD Bank
      rateResponse = await adBankIntegration.getExchangeRate(
        sourceCurrency, 
        destinationCurrency
      );
    }
    
    // Return the exchange rate
    return NextResponse.json({
      sourceCurrency: rateResponse.sourceCurrency,
      destinationCurrency: rateResponse.destinationCurrency,
      rate: rateResponse.rate,
      timestamp: rateResponse.timestamp,
    });
  } catch (error) {
    console.error('Error fetching exchange rate:', error);
    
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

/**
 * GET /api/exchange-rate/history
 * 
 * Get historical exchange rates
 * Implemented as a separate route handler in the same file
 */
export async function GET_history(req: NextRequest) {
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