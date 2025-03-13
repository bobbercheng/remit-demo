import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb';
import config from '@/config';

/**
 * DynamoDB Client configuration
 * 
 * Creates a DynamoDB client using the configuration provided in config.ts
 * For local development, it connects to the DynamoDB local instance
 * In production, it connects to AWS DynamoDB service
 */

// Initialize the base DynamoDB client
const client = new DynamoDBClient({
  region: config.dynamodb.region,
  endpoint: config.dynamodb.endpoint,
  credentials: {
    accessKeyId: config.dynamodb.credentials.accessKeyId,
    secretAccessKey: config.dynamodb.credentials.secretAccessKey,
  },
});

// Create a document client for easier interaction with DynamoDB
export const dynamoDocClient = DynamoDBDocumentClient.from(client, {
  marshallOptions: {
    // Whether to automatically convert empty strings, blobs, and sets to `null`
    convertEmptyValues: true,
    // Whether to remove undefined values while marshalling
    removeUndefinedValues: true,
    // Whether to convert typeof object to map attribute
    convertClassInstanceToMap: true,
  },
  unmarshallOptions: {
    // Whether to return numbers as strings instead of converting them to native JavaScript numbers
    wrapNumbers: false,
  },
});

export default dynamoDocClient; 