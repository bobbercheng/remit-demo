/**
 * Remittance Transaction Status
 * 
 * Represents all possible states of a remittance transaction
 */
export enum RemittanceStatus {
  INITIATED = 'INITIATED',
  PAYMENT_RECEIVED = 'PAYMENT_RECEIVED',
  CURRENCY_CONVERTED = 'CURRENCY_CONVERTED',
  TRANSFER_INITIATED = 'TRANSFER_INITIATED',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED',
  CANCELLED = 'CANCELLED',
}

/**
 * Supported Currencies
 */
export enum Currency {
  INR = 'INR',
  CAD = 'CAD',
}

/**
 * Recipient Information for remittance
 */
export interface RecipientInfo {
  fullName: string;
  accountNumber: string;
  bankName: string;
  bankCode: string; // Transit + Institution number
  address?: string;
  email?: string;
  phone?: string;
}

/**
 * Basic remittance request from client
 */
export interface RemittanceRequest {
  userId: string;
  sourceAmount: number;
  sourceCurrency: Currency.INR;
  destinationCurrency: Currency.CAD;
  recipient: RecipientInfo;
  purpose?: string;
}

/**
 * Remittance Transaction model
 * 
 * Complete representation of a remittance transaction
 */
export interface RemittanceTransaction {
  transactionId: string;
  userId: string;
  status: RemittanceStatus;
  sourceAmount: number;
  sourceCurrency: Currency.INR;
  destinationAmount?: number;
  destinationCurrency: Currency.CAD;
  exchangeRate?: number;
  fees: {
    fixedFee: number;
    percentageFee: number;
    totalFee: number;
  };
  recipient: RecipientInfo;
  paymentMethod: 'UPI';
  upiReferenceId?: string;
  adBankReferenceId?: string;
  wiseReferenceId?: string;
  purpose?: string;
  createdAt: string;
  updatedAt: string;
  completedAt?: string;
  failureReason?: string;
}

/**
 * Response for a new remittance request
 */
export interface RemittanceResponse {
  transactionId: string;
  status: RemittanceStatus;
  sourceAmount: number;
  sourceCurrency: Currency.INR;
  estimatedDestinationAmount?: number;
  destinationCurrency: Currency.CAD;
  estimatedExchangeRate?: number;
  fees: {
    fixedFee: number;
    percentageFee: number;
    totalFee: number;
  };
  paymentInstructions: {
    upiId: string;
    paymentReference: string;
    amountToPay: number;
  };
  createdAt: string;
}

/**
 * UPI Payment Webhook Payload
 */
export interface UpiWebhookPayload {
  paymentReference: string;
  transactionId: string;
  status: 'SUCCESS' | 'FAILURE';
  amount: number;
  currency: Currency.INR;
  upiReferenceId: string;
  timestamp: string;
  metadata?: Record<string, unknown>;
  failureReason?: string;
}

/**
 * Exchange Rate Response from AD Bank
 */
export interface ExchangeRateResponse {
  sourceCurrency: Currency.INR;
  destinationCurrency: Currency.CAD;
  rate: number;
  timestamp: string;
  provider: 'AD_BANK';
}

/**
 * Wise Transfer Request
 */
export interface WiseTransferRequest {
  sourceAmount?: number;
  targetAmount?: number;
  sourceCurrency: Currency.INR;
  targetCurrency: Currency.CAD;
  targetAccount: {
    accountHolderName: string;
    accountNumber: string;
    bankCode: string;
    address?: string;
  };
  reference: string;
}

/**
 * Wise Transfer Response
 */
export interface WiseTransferResponse {
  transferId: string;
  status: string;
  estimatedDeliveryTime: string;
  trackingUrl?: string;
}

/**
 * API Error Response
 */
export interface ApiErrorResponse {
  error: {
    code: string;
    message: string;
    details?: unknown;
  };
} 