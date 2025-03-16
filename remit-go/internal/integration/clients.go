package integration

import (
	"context"
)

// UPIClient defines the interface for UPI payment gateway
type UPIClient interface {
	GeneratePaymentLink(ctx context.Context, txID string, amount float64) (string, error)
	VerifyPayment(ctx context.Context, paymentID string) (string, error)
}

// ADBankClient defines the interface for AD Bank API
type ADBankClient interface {
	GetExchangeRate(ctx context.Context, sourceCurrency, targetCurrency string) (float64, error)
	ValidateAccount(ctx context.Context, bankCode, accountNumber string) (bool, error)
}

// WiseClient defines the interface for Wise API
type WiseClient interface {
	CreateTransfer(ctx context.Context, req *WiseTransferRequest) (string, error)
	GetTransferStatus(ctx context.Context, transferID string) (string, error)
}

// WiseTransferRequest represents a transfer request to Wise
type WiseTransferRequest struct {
	SourceAmount   float64 `json:"source_amount"`
	SourceCurrency string  `json:"source_currency"`
	TargetCurrency string  `json:"target_currency"`
	RecipientName  string  `json:"recipient_name"`
	BankAccount    string  `json:"bank_account"`
	BankCode       string  `json:"bank_code"`
}
