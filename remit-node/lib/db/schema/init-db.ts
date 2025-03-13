import { CreateTableCommand, DeleteTableCommand, DescribeTableCommand } from '@aws-sdk/client-dynamodb';
import { dynamoDocClient } from '../dynamodb';
import config from '@/config';

/**
 * Script to initialize the DynamoDB tables
 * 
 * This file contains the schema definitions and scripts to create the DynamoDB tables
 * It can be used to initialize the local DynamoDB instance for development and testing
 */

// Schema for RemittanceTransactions table
const remittanceTransactionsTableSchema = {
  TableName: config.dynamodb.tableNames.remittanceTransactions,
  KeySchema: [
    { AttributeName: 'transactionId', KeyType: 'HASH' }, // Partition key
  ],
  AttributeDefinitions: [
    { AttributeName: 'transactionId', AttributeType: 'S' },
    { AttributeName: 'userId', AttributeType: 'S' },
    { AttributeName: 'status', AttributeType: 'S' },
  ],
  GlobalSecondaryIndexes: [
    {
      IndexName: 'UserIdIndex',
      KeySchema: [
        { AttributeName: 'userId', KeyType: 'HASH' },
      ],
      Projection: {
        ProjectionType: 'ALL',
      },
      ProvisionedThroughput: {
        ReadCapacityUnits: 5,
        WriteCapacityUnits: 5,
      },
    },
    {
      IndexName: 'StatusIndex',
      KeySchema: [
        { AttributeName: 'status', KeyType: 'HASH' },
      ],
      Projection: {
        ProjectionType: 'ALL',
      },
      ProvisionedThroughput: {
        ReadCapacityUnits: 5,
        WriteCapacityUnits: 5,
      },
    },
  ],
  BillingMode: 'PROVISIONED',
  ProvisionedThroughput: {
    ReadCapacityUnits: 5,
    WriteCapacityUnits: 5,
  },
};

// Schema for RateHistory table
const rateHistoryTableSchema = {
  TableName: config.dynamodb.tableNames.rateHistory,
  KeySchema: [
    { AttributeName: 'timestamp', KeyType: 'HASH' }, // Partition key
  ],
  AttributeDefinitions: [
    { AttributeName: 'timestamp', AttributeType: 'S' },
    { AttributeName: 'sourceCurrency', AttributeType: 'S' },
    { AttributeName: 'destinationCurrency', AttributeType: 'S' },
  ],
  GlobalSecondaryIndexes: [
    {
      IndexName: 'CurrencyPairIndex',
      KeySchema: [
        { AttributeName: 'sourceCurrency', KeyType: 'HASH' },
        { AttributeName: 'destinationCurrency', KeyType: 'RANGE' },
      ],
      Projection: {
        ProjectionType: 'ALL',
      },
      ProvisionedThroughput: {
        ReadCapacityUnits: 5,
        WriteCapacityUnits: 5,
      },
    },
  ],
  BillingMode: 'PROVISIONED',
  ProvisionedThroughput: {
    ReadCapacityUnits: 5,
    WriteCapacityUnits: 5,
  },
};

/**
 * Check if a table already exists
 */
const tableExists = async (tableName: string): Promise<boolean> => {
  try {
    await dynamoDocClient.send(new DescribeTableCommand({ TableName: tableName }));
    return true;
  } catch (error) {
    return false;
  }
};

/**
 * Delete a table if it exists
 */
const deleteTableIfExists = async (tableName: string): Promise<void> => {
  if (await tableExists(tableName)) {
    console.log(`Deleting existing table: ${tableName}`);
    await dynamoDocClient.send(new DeleteTableCommand({ TableName: tableName }));
    console.log(`Deleted table: ${tableName}`);
  }
};

/**
 * Create a table using the specified schema
 */
const createTable = async (schema: any): Promise<void> => {
  await dynamoDocClient.send(new CreateTableCommand(schema));
  console.log(`Created table: ${schema.TableName}`);
};

/**
 * Initialize all database tables
 */
export const initializeDatabase = async (forceRecreate = false): Promise<void> => {
  try {
    // Handle RemittanceTransactions table
    if (forceRecreate) {
      await deleteTableIfExists(config.dynamodb.tableNames.remittanceTransactions);
    }
    
    if (!await tableExists(config.dynamodb.tableNames.remittanceTransactions)) {
      await createTable(remittanceTransactionsTableSchema);
    } else {
      console.log(`Table already exists: ${config.dynamodb.tableNames.remittanceTransactions}`);
    }

    // Handle RateHistory table
    if (forceRecreate) {
      await deleteTableIfExists(config.dynamodb.tableNames.rateHistory);
    }
    
    if (!await tableExists(config.dynamodb.tableNames.rateHistory)) {
      await createTable(rateHistoryTableSchema);
    } else {
      console.log(`Table already exists: ${config.dynamodb.tableNames.rateHistory}`);
    }

    console.log('Database initialization completed successfully');
  } catch (error) {
    console.error('Error initializing database:', error);
    throw error;
  }
};

// Run this function to initialize the database if this file is executed directly
if (require.main === module) {
  initializeDatabase()
    .then(() => console.log('Database initialization completed'))
    .catch((error) => console.error('Database initialization failed:', error));
} 