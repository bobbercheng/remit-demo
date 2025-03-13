import 'dotenv/config';

/**
 * Configuration management for the remittance service
 * Loads configuration from environment variables with sensible defaults.
 */
export const config = {
  // App Configuration
  app: {
    env: process.env.NODE_ENV || 'development',
    port: parseInt(process.env.PORT || '3000', 10),
    isProduction: process.env.NODE_ENV === 'production',
  },

  // DynamoDB Configuration
  dynamodb: {
    endpoint: process.env.DYNAMODB_ENDPOINT || 'http://localhost:8000',
    region: process.env.DYNAMODB_REGION || 'us-east-1',
    credentials: {
      accessKeyId: process.env.DYNAMODB_ACCESS_KEY || 'localkey',
      secretAccessKey: process.env.DYNAMODB_SECRET_KEY || 'localsecret',
    },
    tableNames: {
      remittanceTransactions: 'RemittanceTransactions',
      rateHistory: 'RateHistory',
    },
  },

  // UPI Payment Integration
  upi: {
    apiEndpoint: process.env.UPI_API_ENDPOINT || '',
    apiKey: process.env.UPI_API_KEY || '',
    webhookSecret: process.env.UPI_WEBHOOK_SECRET || '',
  },

  // AD Bank Integration (Currency Conversion)
  adBank: {
    apiEndpoint: process.env.ADBANK_API_ENDPOINT || '',
    apiKey: process.env.ADBANK_API_KEY || '',
    apiSecret: process.env.ADBANK_API_SECRET || '',
  },

  // Wise Integration
  wise: {
    apiEndpoint: process.env.WISE_API_ENDPOINT || 'https://api.sandbox.wise.com',
    apiKey: process.env.WISE_API_KEY || '',
    profileId: process.env.WISE_PROFILE_ID || '',
  },

  // Transaction Limits
  transactionLimits: {
    minAmountInr: parseInt(process.env.MIN_TRANSACTION_AMOUNT_INR || '500', 10),
    maxAmountInr: parseInt(process.env.MAX_TRANSACTION_AMOUNT_INR || '100000', 10),
    minAmountCad: parseInt(process.env.MIN_TRANSACTION_AMOUNT_CAD || '10', 10),
    maxAmountCad: parseInt(process.env.MAX_TRANSACTION_AMOUNT_CAD || '1500', 10),
  },

  // Fee Configuration
  fees: {
    fixedFeeInr: parseInt(process.env.FIXED_FEE_INR || '50', 10),
    percentageFee: parseFloat(process.env.PERCENTAGE_FEE || '0.5'),
  },

  // API Retry Configuration
  retryPolicy: {
    maxRetries: 3,
    initialDelayMs: 1000,
    maxDelayMs: 5000,
  },

  // Logging
  logging: {
    level: process.env.LOG_LEVEL || 'info',
  },
};

/**
 * Validate critical configuration parameters
 * If any are missing, log errors or throw exceptions based on severity
 */
export const validateConfig = (): string[] => {
  const errors: string[] = [];

  // Validate API keys in production
  if (config.app.isProduction) {
    if (!config.upi.apiKey) errors.push('UPI API key is required in production');
    if (!config.adBank.apiKey) errors.push('AD Bank API key is required in production');
    if (!config.wise.apiKey) errors.push('Wise API key is required in production');
  }

  return errors;
};

/**
 * Export config as default
 */
export default config; 