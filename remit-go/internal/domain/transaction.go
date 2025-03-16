package domain

import (
	"time"
)

// TransactionStatus represents the current state of a remittance transaction
type TransactionStatus string

const (
	StatusInitiated       TransactionStatus = "INITIATED"
	StatusPaymentPending  TransactionStatus = "PAYMENT_PENDING"
	StatusPaymentReceived TransactionStatus = "PAYMENT_RECEIVED"
	StatusProcessing      TransactionStatus = "PROCESSING"
	StatusCompleted       TransactionStatus = "COMPLETED"
	StatusFailed          TransactionStatus = "FAILED"
)

// Transaction represents a remittance transaction
type Transaction struct {
	ID               string            `json:"id" dynamodbav:"transaction_id"`
	UserID           string            `json:"user_id" dynamodbav:"user_id"`
	SourceAmount     float64           `json:"source_amount" dynamodbav:"source_amount"`
	SourceCurrency   string            `json:"source_currency" dynamodbav:"source_currency"`
	TargetAmount     float64           `json:"target_amount" dynamodbav:"target_amount"`
	TargetCurrency   string            `json:"target_currency" dynamodbav:"target_currency"`
	ExchangeRate     float64           `json:"exchange_rate" dynamodbav:"exchange_rate"`
	Fees             *Fees             `json:"fees" dynamodbav:"fees"`
	Status           TransactionStatus `json:"status" dynamodbav:"status"`
	PaymentDetails   *PaymentDetails   `json:"payment_details" dynamodbav:"payment_details"`
	RecipientDetails *RecipientDetails `json:"recipient_details" dynamodbav:"recipient_details"`
	TransferID       string            `json:"transfer_id,omitempty" dynamodbav:"transfer_id,omitempty"`
	CreatedAt        time.Time         `json:"created_at" dynamodbav:"created_at"`
	UpdatedAt        time.Time         `json:"updated_at" dynamodbav:"updated_at"`
	CompletedAt      *time.Time        `json:"completed_at,omitempty" dynamodbav:"completed_at,omitempty"`
}

// Fees represents the fee structure for a transaction
type Fees struct {
	BaseFee     float64 `json:"base_fee" dynamodbav:"base_fee"`
	VariableFee float64 `json:"variable_fee" dynamodbav:"variable_fee"`
	WiseFee     float64 `json:"wise_fee" dynamodbav:"wise_fee"`
	TotalFee    float64 `json:"total_fee" dynamodbav:"total_fee"`
}

// PaymentDetails contains UPI payment information
type PaymentDetails struct {
	PaymentID   string     `json:"payment_id" dynamodbav:"payment_id"`
	UPIID       string     `json:"upi_id" dynamodbav:"upi_id"`
	PaymentLink string     `json:"payment_link" dynamodbav:"payment_link"`
	Status      string     `json:"status" dynamodbav:"status"`
	PaidAt      *time.Time `json:"paid_at,omitempty" dynamodbav:"paid_at,omitempty"`
}

// RecipientDetails contains information about the recipient
type RecipientDetails struct {
	BankAccount string `json:"bank_account" dynamodbav:"bank_account"`
	BankCode    string `json:"bank_code" dynamodbav:"bank_code"`
	Name        string `json:"name" dynamodbav:"name"`
}

// NewTransaction creates a new transaction with default values
func NewTransaction(userID string, sourceAmount float64, sourceCurrency, targetCurrency string, recipient *RecipientDetails) *Transaction {
	now := time.Now()
	return &Transaction{
		ID:               generateTransactionID(),
		UserID:           userID,
		SourceAmount:     sourceAmount,
		SourceCurrency:   sourceCurrency,
		TargetCurrency:   targetCurrency,
		Status:           StatusInitiated,
		RecipientDetails: recipient,
		CreatedAt:        now,
		UpdatedAt:        now,
	}
}

// generateTransactionID generates a unique transaction ID
func generateTransactionID() string {
	// Implementation using UUID or other unique ID generator
	return "TXN-" + time.Now().Format("20060102150405")
}

// IsCompleted checks if the transaction is completed
func (t *Transaction) IsCompleted() bool {
	return t.Status == StatusCompleted
}

// IsFailed checks if the transaction has failed
func (t *Transaction) IsFailed() bool {
	return t.Status == StatusFailed
}

// UpdateStatus updates the transaction status and updated_at timestamp
func (t *Transaction) UpdateStatus(status TransactionStatus) {
	t.Status = status
	t.UpdatedAt = time.Now()
	if status == StatusCompleted {
		now := time.Now()
		t.CompletedAt = &now
	}
}

// SetPaymentDetails updates the payment details for the transaction
func (t *Transaction) SetPaymentDetails(details *PaymentDetails) {
	t.PaymentDetails = details
	t.UpdatedAt = time.Now()
}

// SetExchangeRate sets the exchange rate and calculates the target amount
func (t *Transaction) SetExchangeRate(rate float64) {
	t.ExchangeRate = rate
	t.TargetAmount = t.SourceAmount * rate
	t.UpdatedAt = time.Now()
}

// SetFees sets the fee structure for the transaction
func (t *Transaction) SetFees(fees *Fees) {
	t.Fees = fees
	t.UpdatedAt = time.Now()
}
