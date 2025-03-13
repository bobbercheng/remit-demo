import { 
  PutCommand, 
  QueryCommand 
} from '@aws-sdk/lib-dynamodb';
import { dynamoDocClient } from '../dynamodb';
import config from '@/config';
import { Currency, ExchangeRateResponse } from '@/types';

/**
 * Rate Repository
 * 
 * Handles all DynamoDB operations for exchange rate history
 */
export class RateRepository {
  private tableName: string;

  constructor() {
    this.tableName = config.dynamodb.tableNames.rateHistory;
  }

  /**
   * Store a new exchange rate
   */
  async storeExchangeRate(rateData: ExchangeRateResponse): Promise<ExchangeRateResponse> {
    const params = {
      TableName: this.tableName,
      Item: rateData,
    };

    await dynamoDocClient.send(new PutCommand(params));
    return rateData;
  }

  /**
   * Get the latest exchange rate for a currency pair
   */
  async getLatestExchangeRate(
    sourceCurrency: Currency.INR, 
    destinationCurrency: Currency.CAD
  ): Promise<ExchangeRateResponse | null> {
    const params = {
      TableName: this.tableName,
      IndexName: 'CurrencyPairIndex',
      KeyConditionExpression: 'sourceCurrency = :sourceCurrency AND destinationCurrency = :destinationCurrency',
      ExpressionAttributeValues: {
        ':sourceCurrency': sourceCurrency,
        ':destinationCurrency': destinationCurrency,
      },
      ScanIndexForward: false, // descending order by timestamp
      Limit: 1, // Get only the most recent
    };

    const result = await dynamoDocClient.send(new QueryCommand(params));
    
    if (result.Items && result.Items.length > 0) {
      return result.Items[0] as ExchangeRateResponse;
    }
    
    return null;
  }

  /**
   * Get exchange rate history for a currency pair
   */
  async getExchangeRateHistory(
    sourceCurrency: Currency.INR, 
    destinationCurrency: Currency.CAD,
    limit: number = 30
  ): Promise<ExchangeRateResponse[]> {
    const params = {
      TableName: this.tableName,
      IndexName: 'CurrencyPairIndex',
      KeyConditionExpression: 'sourceCurrency = :sourceCurrency AND destinationCurrency = :destinationCurrency',
      ExpressionAttributeValues: {
        ':sourceCurrency': sourceCurrency,
        ':destinationCurrency': destinationCurrency,
      },
      ScanIndexForward: false, // descending order by timestamp
      Limit: limit,
    };

    const result = await dynamoDocClient.send(new QueryCommand(params));
    return (result.Items as ExchangeRateResponse[]) || [];
  }
}

// Export a singleton instance
export const rateRepository = new RateRepository();
export default rateRepository; 