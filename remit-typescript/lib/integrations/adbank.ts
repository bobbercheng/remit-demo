import axios from 'axios';
import crypto from 'crypto';
import config from '@/config';
import { Currency, ExchangeRateResponse } from '@/types';
import { rateRepository } from '@/lib/db/repositories/rate-repository';

/**
 * AD Bank Integration
 * 
 * This module handles integration with the AD Bank for currency conversion.
 * As an Authorized Dealer bank, AD Bank handles the foreign exchange aspect of the remittance.
 */

// AD Bank API client
const adBankClient = axios.create({
  baseURL: config.adBank.apiEndpoint,
  headers: {
    'Content-Type': 'application/json',
    'x-api-key': config.adBank.apiKey,
  },
});

/**
 * Generate authentication signature for AD Bank API
 * 
 * @param timestamp Timestamp of the request
 * @param path API path
 * @param method HTTP method
 */
const generateSignature = (
  timestamp: string,
  path: string,
  method: string
): string => {
  const signatureString = `${timestamp}${path}${method}`;
  return crypto
    .createHmac('sha256', config.adBank.apiSecret)
    .update(signatureString)
    .digest('hex');
};

/**
 * Add authentication headers to requests
 * 
 * @param config Axios request config
 */
adBankClient.interceptors.request.use((config) => {
  const timestamp = new Date().toISOString();
  const path = config.url || '';
  const method = config.method?.toUpperCase() || 'GET';
  
  const signature = generateSignature(timestamp, path, method);
  
  config.headers = {
    ...config.headers,
    'x-timestamp': timestamp,
    'x-signature': signature,
  };
  
  return config;
});

/**
 * Interface for currency conversion request
 */
interface CurrencyConversionRequest {
  sourceCurrency: Currency;
  destinationCurrency: Currency;
  sourceAmount: number;
}

/**
 * Interface for currency conversion response
 */
interface CurrencyConversionResponse {
  sourceCurrency: Currency;
  destinationCurrency: Currency;
  sourceAmount: number;
  destinationAmount: number;
  exchangeRate: number;
  fees: number;
  referenceId: string;
  timestamp: string;
}

/**
 * Get the current exchange rate from AD Bank
 * 
 * @param sourceCurrency Source currency (INR)
 * @param destinationCurrency Destination currency (CAD)
 */
export const getExchangeRate = async (
  sourceCurrency: Currency.INR = Currency.INR,
  destinationCurrency: Currency.CAD = Currency.CAD
): Promise<ExchangeRateResponse> => {
  try {
    const response = await adBankClient.get('/exchange-rates', {
      params: {
        sourceCurrency,
        destinationCurrency,
      },
    });
    
    const data = response.data;
    
    // Format the response to match our ExchangeRateResponse type
    const rateResponse: ExchangeRateResponse = {
      sourceCurrency: data.from,
      destinationCurrency: data.to,
      rate: data.rate,
      timestamp: data.timestamp || new Date().toISOString(),
      provider: 'AD_BANK',
    };
    
    // Store the rate in our database for historical tracking
    await rateRepository.storeExchangeRate(rateResponse);
    
    return rateResponse;
  } catch (error) {
    console.error('Error fetching exchange rate from AD Bank:', error);
    throw error;
  }
};

/**
 * Convert currency using AD Bank
 * 
 * @param sourceAmount Amount in source currency (INR)
 */
export const convertCurrency = async (
  sourceAmount: number
): Promise<CurrencyConversionResponse> => {
  try {
    const payload: CurrencyConversionRequest = {
      sourceCurrency: Currency.INR,
      destinationCurrency: Currency.CAD,
      sourceAmount,
    };
    
    const response = await adBankClient.post('/convert', payload);
    return response.data;
  } catch (error) {
    console.error('Error converting currency with AD Bank:', error);
    throw error;
  }
};

/**
 * Calculate estimated destination amount
 * 
 * @param sourceAmount Amount in source currency (INR)
 */
export const calculateEstimatedAmount = async (
  sourceAmount: number
): Promise<{
  destinationAmount: number;
  exchangeRate: number;
  fees: number;
}> => {
  try {
    // Get current exchange rate
    const rateResponse = await getExchangeRate();
    
    // Calculate estimated amount (apply a small markup as buffer)
    const rate = rateResponse.rate * 0.995; // 0.5% markup for estimation buffer
    const estimatedDestinationAmount = sourceAmount * rate;
    
    // Calculate fees (this could come from config or be calculated based on amount)
    const fees = config.fees.fixedFeeInr + (sourceAmount * config.fees.percentageFee / 100);
    
    return {
      destinationAmount: Number(estimatedDestinationAmount.toFixed(2)),
      exchangeRate: Number(rate.toFixed(6)),
      fees,
    };
  } catch (error) {
    console.error('Error calculating estimated amount:', error);
    throw error;
  }
};

export default {
  getExchangeRate,
  convertCurrency,
  calculateEstimatedAmount,
}; 