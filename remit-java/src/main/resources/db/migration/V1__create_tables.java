package db.migration;

import com.amazonaws.services.dynamodbv2.AmazonDynamoDB;
import com.amazonaws.services.dynamodbv2.AmazonDynamoDBClientBuilder;
import com.amazonaws.services.dynamodbv2.model.*;
import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;
import org.springframework.beans.factory.annotation.Value;

import java.util.ArrayList;
import java.util.List;

/**
 * Flyway migration to create DynamoDB tables for the remittance service.
 */
public class V1__create_tables extends BaseJavaMigration {

    @Value("${aws.dynamodb.endpoint}")
    private String dynamoDbEndpoint;

    @Value("${aws.dynamodb.region}")
    private String region;

    @Value("${aws.dynamodb.accessKey}")
    private String accessKey;

    @Value("${aws.dynamodb.secretKey}")
    private String secretKey;

    @Value("${dynamodb.table.transaction}")
    private String transactionTableName;

    @Value("${dynamodb.table.payment}")
    private String paymentTableName;

    @Value("${dynamodb.table.exchangeRate}")
    private String exchangeRateTableName;

    @Value("${dynamodb.table.disbursement}")
    private String disbursementTableName;

    @Override
    public void migrate(Context context) throws Exception {
        AmazonDynamoDB dynamoDB = AmazonDynamoDBClientBuilder.standard().build();

        // Create Transaction table
        createTransactionTable(dynamoDB);

        // Create Payment table
        createPaymentTable(dynamoDB);

        // Create ExchangeRate table
        createExchangeRateTable(dynamoDB);

        // Create Disbursement table
        createDisbursementTable(dynamoDB);
    }

    private void createTransactionTable(AmazonDynamoDB dynamoDB) {
        List<AttributeDefinition> attributeDefinitions = new ArrayList<>();
        attributeDefinitions.add(new AttributeDefinition()
                .withAttributeName("transactionId")
                .withAttributeType(ScalarAttributeType.S));
        attributeDefinitions.add(new AttributeDefinition()
                .withAttributeName("userId")
                .withAttributeType(ScalarAttributeType.S));
        attributeDefinitions.add(new AttributeDefinition()
                .withAttributeName("status")
                .withAttributeType(ScalarAttributeType.S));

        List<KeySchemaElement> keySchema = new ArrayList<>();
        keySchema.add(new KeySchemaElement()
                .withAttributeName("transactionId")
                .withKeyType(KeyType.HASH));

        List<GlobalSecondaryIndex> globalSecondaryIndexes = new ArrayList<>();
        
        // GSI for querying by userId
        globalSecondaryIndexes.add(new GlobalSecondaryIndex()
                .withIndexName("UserIdIndex")
                .withKeySchema(
                        new KeySchemaElement().withAttributeName("userId").withKeyType(KeyType.HASH),
                        new KeySchemaElement().withAttributeName("status").withKeyType(KeyType.RANGE))
                .withProjection(new Projection().withProjectionType(ProjectionType.ALL))
                .withProvisionedThroughput(new ProvisionedThroughput()
                        .withReadCapacityUnits(5L)
                        .withWriteCapacityUnits(5L)));

        // GSI for querying by status
        globalSecondaryIndexes.add(new GlobalSecondaryIndex()
                .withIndexName("StatusIndex")
                .withKeySchema(
                        new KeySchemaElement().withAttributeName("status").withKeyType(KeyType.HASH))
                .withProjection(new Projection().withProjectionType(ProjectionType.ALL))
                .withProvisionedThroughput(new ProvisionedThroughput()
                        .withReadCapacityUnits(5L)
                        .withWriteCapacityUnits(5L)));

        CreateTableRequest request = new CreateTableRequest()
                .withTableName(transactionTableName)
                .withKeySchema(keySchema)
                .withAttributeDefinitions(attributeDefinitions)
                .withGlobalSecondaryIndexes(globalSecondaryIndexes)
                .withProvisionedThroughput(new ProvisionedThroughput()
                        .withReadCapacityUnits(5L)
                        .withWriteCapacityUnits(5L));

        try {
            dynamoDB.createTable(request);
        } catch (ResourceInUseException e) {
            // Table already exists, ignore
        }
    }

    private void createPaymentTable(AmazonDynamoDB dynamoDB) {
        List<AttributeDefinition> attributeDefinitions = new ArrayList<>();
        attributeDefinitions.add(new AttributeDefinition()
                .withAttributeName("paymentId")
                .withAttributeType(ScalarAttributeType.S));
        attributeDefinitions.add(new AttributeDefinition()
                .withAttributeName("transactionId")
                .withAttributeType(ScalarAttributeType.S));
        attributeDefinitions.add(new AttributeDefinition()
                .withAttributeName("paymentReference")
                .withAttributeType(ScalarAttributeType.S));

        List<KeySchemaElement> keySchema = new ArrayList<>();
        keySchema.add(new KeySchemaElement()
                .withAttributeName("paymentId")
                .withKeyType(KeyType.HASH));

        List<GlobalSecondaryIndex> globalSecondaryIndexes = new ArrayList<>();
        
        // GSI for querying by transactionId
        globalSecondaryIndexes.add(new GlobalSecondaryIndex()
                .withIndexName("TransactionIdIndex")
                .withKeySchema(
                        new KeySchemaElement().withAttributeName("transactionId").withKeyType(KeyType.HASH))
                .withProjection(new Projection().withProjectionType(ProjectionType.ALL))
                .withProvisionedThroughput(new ProvisionedThroughput()
                        .withReadCapacityUnits(5L)
                        .withWriteCapacityUnits(5L)));

        // GSI for querying by paymentReference
        globalSecondaryIndexes.add(new GlobalSecondaryIndex()
                .withIndexName("PaymentReferenceIndex")
                .withKeySchema(
                        new KeySchemaElement().withAttributeName("paymentReference").withKeyType(KeyType.HASH))
                .withProjection(new Projection().withProjectionType(ProjectionType.ALL))
                .withProvisionedThroughput(new ProvisionedThroughput()
                        .withReadCapacityUnits(5L)
                        .withWriteCapacityUnits(5L)));

        CreateTableRequest request = new CreateTableRequest()
                .withTableName(paymentTableName)
                .withKeySchema(keySchema)
                .withAttributeDefinitions(attributeDefinitions)
                .withGlobalSecondaryIndexes(globalSecondaryIndexes)
                .withProvisionedThroughput(new ProvisionedThroughput()
                        .withReadCapacityUnits(5L)
                        .withWriteCapacityUnits(5L));

        try {
            dynamoDB.createTable(request);
        } catch (ResourceInUseException e) {
            // Table already exists, ignore
        }
    }

    private void createExchangeRateTable(AmazonDynamoDB dynamoDB) {
        List<AttributeDefinition> attributeDefinitions = new ArrayList<>();
        attributeDefinitions.add(new AttributeDefinition()
                .withAttributeName("pairId")
                .withAttributeType(ScalarAttributeType.S));
        attributeDefinitions.add(new AttributeDefinition()
                .withAttributeName("timestamp")
                .withAttributeType(ScalarAttributeType.S));

        List<KeySchemaElement> keySchema = new ArrayList<>();
        keySchema.add(new KeySchemaElement()
                .withAttributeName("pairId")
                .withKeyType(KeyType.HASH));
        keySchema.add(new KeySchemaElement()
                .withAttributeName("timestamp")
                .withKeyType(KeyType.RANGE));

        CreateTableRequest request = new CreateTableRequest()
                .withTableName(exchangeRateTableName)
                .withKeySchema(keySchema)
                .withAttributeDefinitions(attributeDefinitions)
                .withProvisionedThroughput(new ProvisionedThroughput()
                        .withReadCapacityUnits(5L)
                        .withWriteCapacityUnits(5L));

        try {
            dynamoDB.createTable(request);
        } catch (ResourceInUseException e) {
            // Table already exists, ignore
        }
    }

    private void createDisbursementTable(AmazonDynamoDB dynamoDB) {
        List<AttributeDefinition> attributeDefinitions = new ArrayList<>();
        attributeDefinitions.add(new AttributeDefinition()
                .withAttributeName("disbursementId")
                .withAttributeType(ScalarAttributeType.S));
        attributeDefinitions.add(new AttributeDefinition()
                .withAttributeName("transactionId")
                .withAttributeType(ScalarAttributeType.S));

        List<KeySchemaElement> keySchema = new ArrayList<>();
        keySchema.add(new KeySchemaElement()
                .withAttributeName("disbursementId")
                .withKeyType(KeyType.HASH));

        List<GlobalSecondaryIndex> globalSecondaryIndexes = new ArrayList<>();
        
        // GSI for querying by transactionId
        globalSecondaryIndexes.add(new GlobalSecondaryIndex()
                .withIndexName("TransactionIdIndex")
                .withKeySchema(
                        new KeySchemaElement().withAttributeName("transactionId").withKeyType(KeyType.HASH))
                .withProjection(new Projection().withProjectionType(ProjectionType.ALL))
                .withProvisionedThroughput(new ProvisionedThroughput()
                        .withReadCapacityUnits(5L)
                        .withWriteCapacityUnits(5L)));

        CreateTableRequest request = new CreateTableRequest()
                .withTableName(disbursementTableName)
                .withKeySchema(keySchema)
                .withAttributeDefinitions(attributeDefinitions)
                .withGlobalSecondaryIndexes(globalSecondaryIndexes)
                .withProvisionedThroughput(new ProvisionedThroughput()
                        .withReadCapacityUnits(5L)
                        .withWriteCapacityUnits(5L));

        try {
            dynamoDB.createTable(request);
        } catch (ResourceInUseException e) {
            // Table already exists, ignore
        }
    }
} 