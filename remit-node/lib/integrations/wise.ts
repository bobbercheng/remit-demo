import axios from 'axios';
import config from '@/config';
import { Currency, WiseTransferRequest, WiseTransferResponse, RecipientInfo } from '@/types';

/**
 * Wise Integration
 * 
 * This module handles integration with the Wise API for transferring funds to Canada.
 * Wise is used as the cross-border aggregator to deliver funds to Canadian bank accounts.
 */

// Wise API client
const wiseClient = axios.create({
  baseURL: config.wise.apiEndpoint,
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${config.wise.apiKey}`,
  },
});

/**
 * Interface for creating a recipient in Wise
 */
interface WiseRecipientRequest {
  currency: string;
  type: string;
  profile: string;
  accountHolderName: string;
  details: {
    accountNumber: string;
    bankCode: string;
    address?: string;
  };
}

/**
 * Interface for Wise recipient response
 */
interface WiseRecipientResponse {
  id: string;
  currency: string;
  type: string;
  accountHolderName: string;
  details: Record<string, unknown>;
  active: boolean;
}

/**
 * Create a recipient in Wise
 * 
 * @param recipientInfo Recipient information
 */
export const createRecipient = async (
  recipientInfo: RecipientInfo
): Promise<WiseRecipientResponse> => {
  try {
    const payload: WiseRecipientRequest = {
      currency: Currency.CAD,
      type: 'canadian_bank_account',
      profile: config.wise.profileId,
      accountHolderName: recipientInfo.fullName,
      details: {
        accountNumber: recipientInfo.accountNumber,
        bankCode: recipientInfo.bankCode,
        address: recipientInfo.address,
      },
    };
    
    const response = await wiseClient.post('/v1/accounts', payload);
    return response.data;
  } catch (error) {
    console.error('Error creating recipient in Wise:', error);
    throw error;
  }
};

/**
 * Create a quote for transfer
 * 
 * @param sourceAmount Amount in source currency (INR)
 */
export const createQuote = async (
  sourceAmount: number
): Promise<{
  quoteId: string;
  targetAmount: number;
  rate: number;
  fee: number;
  estimatedDelivery: string;
}> => {
  try {
    const payload = {
      profileId: config.wise.profileId,
      sourceCurrency: Currency.INR,
      targetCurrency: Currency.CAD,
      sourceAmount,
    };
    
    const response = await wiseClient.post('/v3/quotes', payload);
    const data = response.data;
    
    return {
      quoteId: data.id,
      targetAmount: data.targetAmount,
      rate: data.rate,
      fee: data.fee,
      estimatedDelivery: data.estimatedDelivery,
    };
  } catch (error) {
    console.error('Error creating quote in Wise:', error);
    throw error;
  }
};

/**
 * Create a transfer to a Canadian account
 * 
 * @param wiseTransferRequest Transfer request details
 */
export const createTransfer = async (
  wiseTransferRequest: WiseTransferRequest
): Promise<WiseTransferResponse> => {
  try {
    // First create a quote
    const quoteResponse = await createQuote(wiseTransferRequest.sourceAmount || 0);
    
    // Then create a recipient account if needed
    const recipientResponse = await createRecipient(wiseTransferRequest.targetAccount);
    
    // Create the transfer using the quote and recipient
    const transferPayload = {
      targetAccount: recipientResponse.id,
      quoteId: quoteResponse.quoteId,
      customerTransactionId: wiseTransferRequest.reference,
      details: {
        reference: wiseTransferRequest.reference,
        sourceOfFunds: 'business',
        transferPurpose: 'family_support',
      },
    };
    
    const response = await wiseClient.post('/v1/transfers', transferPayload);
    const data = response.data;
    
    // Format the response
    const transferResponse: WiseTransferResponse = {
      transferId: data.id,
      status: data.status,
      estimatedDeliveryTime: quoteResponse.estimatedDelivery,
      trackingUrl: data.trackingUrl,
    };
    
    return transferResponse;
  } catch (error) {
    console.error('Error creating transfer in Wise:', error);
    throw error;
  }
};

/**
 * Check transfer status
 * 
 * @param transferId The Wise transfer ID
 */
export const checkTransferStatus = async (
  transferId: string
): Promise<{
  status: string;
  trackingUrl?: string;
}> => {
  try {
    const response = await wiseClient.get(`/v1/transfers/${transferId}`);
    const data = response.data;
    
    return {
      status: data.status,
      trackingUrl: data.trackingUrl,
    };
  } catch (error) {
    console.error('Error checking transfer status in Wise:', error);
    throw error;
  }
};

/**
 * Map Wise status to our application status
 * 
 * @param wiseStatus Status from Wise API
 */
export const mapWiseStatus = (wiseStatus: string): string => {
  const statusMap: Record<string, string> = {
    'incoming_payment_waiting': 'TRANSFER_INITIATED',
    'processing': 'TRANSFER_INITIATED',
    'funds_converted': 'TRANSFER_INITIATED',
    'outgoing_payment_sent': 'TRANSFER_INITIATED',
    'completed': 'COMPLETED',
    'cancelled': 'FAILED',
    'failed': 'FAILED',
  };
  
  return statusMap[wiseStatus.toLowerCase()] || 'TRANSFER_INITIATED';
};

export default {
  createRecipient,
  createQuote,
  createTransfer,
  checkTransferStatus,
  mapWiseStatus,
}; 