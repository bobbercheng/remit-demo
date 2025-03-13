import axios from 'axios';
import crypto from 'crypto';
import config from '@/config';
import { UpiWebhookPayload } from '@/types';

/**
 * UPI Payment Integration
 * 
 * This module handles integration with the UPI payment system in India.
 * It provides methods to generate payment requests and verify webhooks.
 */

// UPI Integration client
const upiClient = axios.create({
  baseURL: config.upi.apiEndpoint,
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${config.upi.apiKey}`,
  },
});

/**
 * Interface for UPI payment request
 */
interface UpiPaymentRequest {
  amount: number;
  currency: string;
  referenceId: string;
  description: string;
}

/**
 * Interface for UPI payment response
 */
interface UpiPaymentResponse {
  paymentId: string;
  upiId: string;
  paymentReference: string;
  qrCodeUrl?: string;
  deepLink?: string;
  status: 'PENDING' | 'COMPLETED' | 'FAILED';
  expiresAt: string;
}

/**
 * Generate a UPI payment request
 * 
 * @param amount Amount to be paid in INR
 * @param referenceId Reference ID (transaction ID)
 * @param description Payment description
 */
export const generateUpiPaymentRequest = async (
  amount: number,
  referenceId: string,
  description: string
): Promise<UpiPaymentResponse> => {
  try {
    const payload: UpiPaymentRequest = {
      amount,
      currency: 'INR',
      referenceId,
      description,
    };

    const response = await upiClient.post('/payment-requests', payload);
    return response.data;
  } catch (error) {
    console.error('Error generating UPI payment request:', error);
    throw error;
  }
};

/**
 * Verify UPI webhook signature
 * 
 * @param payload The webhook payload
 * @param signature The signature from the request headers
 */
export const verifyUpiWebhookSignature = (
  payload: UpiWebhookPayload,
  signature: string
): boolean => {
  // Convert payload to string
  const payloadString = JSON.stringify(payload);
  
  // Compute HMAC using the webhook secret
  const computedSignature = crypto
    .createHmac('sha256', config.upi.webhookSecret)
    .update(payloadString)
    .digest('hex');
  
  // Compare signatures
  return crypto.timingSafeEqual(
    Buffer.from(computedSignature),
    Buffer.from(signature)
  );
};

/**
 * Validate UPI webhook payload
 * 
 * @param payload The webhook payload to validate
 */
export const validateUpiWebhookPayload = (payload: UpiWebhookPayload): boolean => {
  // Basic validation
  if (!payload.paymentReference || !payload.transactionId || !payload.status) {
    return false;
  }
  
  // Status validation
  if (!['SUCCESS', 'FAILURE'].includes(payload.status)) {
    return false;
  }
  
  // Amount validation
  if (typeof payload.amount !== 'number' || payload.amount <= 0) {
    return false;
  }
  
  return true;
};

export default {
  generateUpiPaymentRequest,
  verifyUpiWebhookSignature,
  validateUpiWebhookPayload,
}; 