package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/remit-demo/remit-go/internal/domain"
)

type DynamoDBRepository struct {
	client        *dynamodb.Client
	txTableName   string
	payTableName  string
}

// NewDynamoDBRepository creates a new DynamoDB repository instance
func NewDynamoDBRepository(client *dynamodb.Client, txTableName, payTableName string) *DynamoDBRepository {
	return &DynamoDBRepository{
		client:        client,
		txTableName:   txTableName,
		payTableName:  payTableName,
	}
}

// CreateTransaction creates a new transaction in DynamoDB
func (r *DynamoDBRepository) CreateTransaction(ctx context.Context, tx *domain.Transaction) error {
	item, err := attributevalue.MarshalMap(tx)
	if err != nil {
		return fmt.Errorf("failed to marshal transaction: %w", err)
	}

	_, err = r.client.PutItem(ctx, &dynamodb.PutItemInput{
		TableName: aws.String(r.txTableName),
		Item:      item,
		ConditionExpression: aws.String("attribute_not_exists(transaction_id)"),
	})

	if err != nil {
		var ccfe *types.ConditionalCheckFailedException
		if _, ok := err.(*types.ConditionalCheckFailedException); ok {
			return ErrAlreadyExists
		}
		return fmt.Errorf("failed to create transaction: %w", err)
	}

	return nil
}

// GetTransaction retrieves a transaction by ID
func (r *DynamoDBRepository) GetTransaction(ctx context.Context, id string) (*domain.Transaction, error) {
	result, err := r.client.GetItem(ctx, &dynamodb.GetItemInput{
		TableName: aws.String(r.txTableName),
		Key: map[string]types.AttributeValue{
			"transaction_id": &types.AttributeValueMemberS{Value: id},
		},
	})

	if err != nil {
		return nil, fmt.Errorf("failed to get transaction: %w", err)
	}

	if result.Item == nil {
		return nil, ErrNotFound
	}

	var tx domain.Transaction
	if err := attributevalue.UnmarshalMap(result.Item, &tx); err != nil {
		return nil, fmt.Errorf("failed to unmarshal transaction: %w", err)
	}

	return &tx, nil
}

// UpdateTransaction updates an existing transaction
func (r *DynamoDBRepository) UpdateTransaction(ctx context.Context, tx *domain.Transaction) error {
	tx.UpdatedAt = time.Now()
	
	item, err := attributevalue.MarshalMap(tx)
	if err != nil {
		return fmt.Errorf("failed to marshal transaction: %w", err)
	}

	_, err = r.client.PutItem(ctx, &dynamodb.PutItemInput{
		TableName: aws.String(r.txTableName),
		Item:      item,
		ConditionExpression: aws.String("attribute_exists(transaction_id)"),
	})

	if err != nil {
		var ccfe *types.ConditionalCheckFailedException
		if _, ok := err.(*types.ConditionalCheckFailedException); ok {
			return ErrNotFound
		}
		return fmt.Errorf("failed to update transaction: %w", err)
	}

	return nil
}

// ListTransactionsByUser retrieves transactions for a specific user
func (r *DynamoDBRepository) ListTransactionsByUser(ctx context.Context, userID string, limit int, lastKey string) ([]*domain.Transaction, string, error) {
	input := &dynamodb.QueryInput{
		TableName:              aws.String(r.txTableName),
		IndexName:             aws.String("user_id-created_at-index"),
		KeyConditionExpression: aws.String("user_id = :uid"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":uid": &types.AttributeValueMemberS{Value: userID},
		},
		Limit:            aws.Int32(int32(limit)),
		ScanIndexForward: aws.Bool(false), // Latest first
	}

	if lastKey != "" {
		// Parse and set ExclusiveStartKey based on lastKey
		// Implementation depends on how you encode/decode the last evaluated key
	}

	result, err := r.client.Query(ctx, input)
	if err != nil {
		return nil, "", fmt.Errorf("failed to query transactions: %w", err)
	}

	var transactions []*domain.Transaction
	err = attributevalue.UnmarshalListOfMaps(result.Items, &transactions)
	if err != nil {
		return nil, "", fmt.Errorf("failed to unmarshal transactions: %w", err)
	}

	var nextKey string
	if result.LastEvaluatedKey != nil {
		// Encode LastEvaluatedKey into a string
		// Implementation depends on how you want to encode the pagination token
	}

	return transactions, nextKey, nil
}

// CreatePayment creates a new payment record
func (r *DynamoDBRepository) CreatePayment(ctx context.Context, txID string, payment *domain.PaymentDetails) error {
	item, err := attributevalue.MarshalMap(payment)
	if err != nil {
		return fmt.Errorf("failed to marshal payment: %w", err)
	}

	item["transaction_id"] = &types.AttributeValueMemberS{Value: txID}

	_, err = r.client.PutItem(ctx, &dynamodb.PutItemInput{
		TableName: aws.String(r.payTableName),
		Item:      item,
		ConditionExpression: aws.String("attribute_not_exists(payment_id)"),
	})

	if err != nil {
		var ccfe *types.ConditionalCheckFailedException
		if _, ok := err.(*types.ConditionalCheckFailedException); ok {
			return ErrAlreadyExists
		}
		return fmt.Errorf("failed to create payment: %w", err)
	}

	return nil
}

// UpdatePayment updates an existing payment record
func (r *DynamoDBRepository) UpdatePayment(ctx context.Context, txID string, payment *domain.PaymentDetails) error {
	item, err := attributevalue.MarshalMap(payment)
	if err != nil {
		return fmt.Errorf("failed to marshal payment: %w", err)
	}

	item["transaction_id"] = &types.AttributeValueMemberS{Value: txID}

	_, err = r.client.PutItem(ctx, &dynamodb.PutItemInput{
		TableName: aws.String(r.payTableName),
		Item:      item,
		ConditionExpression: aws.String("attribute_exists(payment_id)"),
	})

	if err != nil {
		var ccfe *types.ConditionalCheckFailedException
		if _, ok := err.(*types.ConditionalCheckFailedException); ok {
			return ErrNotFound
		}
		return fmt.Errorf("failed to update payment: %w", err)
	}

	return nil
}

// GetPayment retrieves a payment by ID
func (r *DynamoDBRepository) GetPayment(ctx context.Context, paymentID string) (*domain.PaymentDetails, error) {
	result, err := r.client.GetItem(ctx, &dynamodb.GetItemInput{
		TableName: aws.String(r.payTableName),
		Key: map[string]types.AttributeValue{
			"payment_id": &types.AttributeValueMemberS{Value: paymentID},
		},
	})

	if err != nil {
		return nil, fmt.Errorf("failed to get payment: %w", err)
	}

	if result.Item == nil {
		return nil, ErrNotFound
	}

	var payment domain.PaymentDetails
	if err := attributevalue.UnmarshalMap(result.Item, &payment); err != nil {
		return nil, fmt.Errorf("failed to unmarshal payment: %w", err)
	}

	return &payment, nil
} 