import { 
  PutCommand, 
  GetCommand, 
  QueryCommand, 
  UpdateCommand,
  ScanCommand 
} from '@aws-sdk/lib-dynamodb';
import { dynamoDocClient } from '../dynamodb';
import config from '@/config';
import { RemittanceTransaction, RemittanceStatus } from '@/types';

/**
 * Remittance Repository
 * 
 * Handles all DynamoDB operations for remittance transactions
 */
export class RemittanceRepository {
  private tableName: string;

  constructor() {
    this.tableName = config.dynamodb.tableNames.remittanceTransactions;
  }

  /**
   * Create a new remittance transaction
   */
  async createTransaction(transaction: RemittanceTransaction): Promise<RemittanceTransaction> {
    const params = {
      TableName: this.tableName,
      Item: transaction,
    };

    await dynamoDocClient.send(new PutCommand(params));
    return transaction;
  }

  /**
   * Get a transaction by ID
   */
  async getTransactionById(transactionId: string): Promise<RemittanceTransaction | null> {
    const params = {
      TableName: this.tableName,
      Key: { transactionId },
    };

    const result = await dynamoDocClient.send(new GetCommand(params));
    return result.Item as RemittanceTransaction || null;
  }

  /**
   * Get all transactions for a user
   */
  async getTransactionsByUserId(userId: string): Promise<RemittanceTransaction[]> {
    const params = {
      TableName: this.tableName,
      IndexName: 'UserIdIndex',
      KeyConditionExpression: 'userId = :userId',
      ExpressionAttributeValues: {
        ':userId': userId,
      },
    };

    const result = await dynamoDocClient.send(new QueryCommand(params));
    return result.Items as RemittanceTransaction[] || [];
  }

  /**
   * Get transactions by status
   */
  async getTransactionsByStatus(status: RemittanceStatus): Promise<RemittanceTransaction[]> {
    const params = {
      TableName: this.tableName,
      IndexName: 'StatusIndex',
      KeyConditionExpression: '#status = :status',
      ExpressionAttributeNames: {
        '#status': 'status',
      },
      ExpressionAttributeValues: {
        ':status': status,
      },
    };

    const result = await dynamoDocClient.send(new QueryCommand(params));
    return result.Items as RemittanceTransaction[] || [];
  }

  /**
   * Update a transaction's status
   */
  async updateTransactionStatus(
    transactionId: string, 
    status: RemittanceStatus, 
    additionalFields: Partial<RemittanceTransaction> = {}
  ): Promise<RemittanceTransaction | null> {
    // Start with basic update expression for status and updatedAt
    let updateExpression = 'SET #status = :status, updatedAt = :updatedAt';
    const expressionAttributeNames: Record<string, string> = {
      '#status': 'status',
    };
    const expressionAttributeValues: Record<string, any> = {
      ':status': status,
      ':updatedAt': new Date().toISOString(),
    };

    // Add additional fields to the update expression
    Object.entries(additionalFields).forEach(([key, value], index) => {
      // Skip status and updatedAt as they're already included
      if (key !== 'status' && key !== 'updatedAt' && key !== 'transactionId') {
        const fieldName = `#field${index}`;
        const fieldValue = `:value${index}`;

        updateExpression += `, ${fieldName} = ${fieldValue}`;
        expressionAttributeNames[fieldName] = key;
        expressionAttributeValues[fieldValue] = value;
      }
    });

    // Special handling for completed and failed statuses
    if (status === RemittanceStatus.COMPLETED) {
      updateExpression += ', completedAt = :completedAt';
      expressionAttributeValues[':completedAt'] = new Date().toISOString();
    }

    const params = {
      TableName: this.tableName,
      Key: { transactionId },
      UpdateExpression: updateExpression,
      ExpressionAttributeNames: expressionAttributeNames,
      ExpressionAttributeValues: expressionAttributeValues,
      ReturnValues: 'ALL_NEW',
    };

    const result = await dynamoDocClient.send(new UpdateCommand(params));
    return result.Attributes as RemittanceTransaction || null;
  }

  /**
   * Get recent transactions (useful for dashboards)
   */
  async getRecentTransactions(limit: number = 10): Promise<RemittanceTransaction[]> {
    const params = {
      TableName: this.tableName,
      Limit: limit,
      ScanIndexForward: false, // descending order, most recent first
    };

    const result = await dynamoDocClient.send(new ScanCommand(params));
    return result.Items as RemittanceTransaction[] || [];
  }
}

// Export a singleton instance
export const remittanceRepository = new RemittanceRepository();
export default remittanceRepository; 