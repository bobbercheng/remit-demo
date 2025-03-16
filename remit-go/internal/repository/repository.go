package repository

import (
	"context"
	"github.com/remit-demo/remit-go/internal/domain"
)

// Repository defines the interface for transaction persistence
type Repository interface {
	// Transaction operations
	CreateTransaction(ctx context.Context, tx *domain.Transaction) error
	GetTransaction(ctx context.Context, id string) (*domain.Transaction, error)
	UpdateTransaction(ctx context.Context, tx *domain.Transaction) error
	ListTransactionsByUser(ctx context.Context, userID string, limit int, lastKey string) ([]*domain.Transaction, string, error)
	
	// Payment operations
	CreatePayment(ctx context.Context, txID string, payment *domain.PaymentDetails) error
	UpdatePayment(ctx context.Context, txID string, payment *domain.PaymentDetails) error
	GetPayment(ctx context.Context, paymentID string) (*domain.PaymentDetails, error)
}

// Error types for repository operations
type Error string

const (
	ErrNotFound      Error = "not_found"
	ErrAlreadyExists Error = "already_exists"
	ErrInvalidInput  Error = "invalid_input"
)

func (e Error) Error() string {
	return string(e)
} 