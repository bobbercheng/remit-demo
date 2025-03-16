package service

import (
	"context"

	"github.com/remit-demo/remit-go/internal/domain"
)

// Service defines the interface for remittance business operations
type Service interface {
	// Transaction operations
	InitiateTransaction(ctx context.Context, userID string, amount float64, recipient *domain.RecipientDetails) (*domain.Transaction, error)
	GetTransaction(ctx context.Context, id string) (*domain.Transaction, error)
	ListUserTransactions(ctx context.Context, userID string, limit int, lastKey string) ([]*domain.Transaction, string, error)

	// Payment operations
	GeneratePaymentLink(ctx context.Context, txID string) (*domain.PaymentDetails, error)
	HandlePaymentCallback(ctx context.Context, paymentID string, status string) error

	// Exchange rate operations
	GetExchangeRate(ctx context.Context) (float64, error)

	// Cross-border transfer operations
	InitiateTransfer(ctx context.Context, txID string) error
	HandleTransferCallback(ctx context.Context, txID string, status string) error
}

// Error types for service operations
type Error string

const (
	ErrInvalidAmount      Error = "invalid_amount"
	ErrInvalidCurrency    Error = "invalid_currency"
	ErrInvalidRecipient   Error = "invalid_recipient"
	ErrTransactionFailed  Error = "transaction_failed"
	ErrPaymentFailed      Error = "payment_failed"
	ErrTransferFailed     Error = "transfer_failed"
	ErrInvalidStatus      Error = "invalid_status"
	ErrDailyLimitExceeded Error = "daily_limit_exceeded"
)

func (e Error) Error() string {
	return string(e)
}
