package service

import (
	"context"
	"fmt"
	"time"

	"github.com/remit-demo/remit-go/internal/domain"
	"github.com/remit-demo/remit-go/internal/integration"
	"github.com/remit-demo/remit-go/internal/repository"
)

// RemittanceService implements the Service interface
type RemittanceService struct {
	repo         repository.Repository
	upiClient    integration.UPIClient
	adBankClient integration.ADBankClient
	wiseClient   integration.WiseClient
	config       *Config
}

// Config holds service configuration
type Config struct {
	MinAmount    float64
	MaxAmount    float64
	DailyLimit   float64
	BaseFee      float64
	VariableFee  float64
	RateValidity time.Duration
}

// NewRemittanceService creates a new remittance service instance
func NewRemittanceService(
	repo repository.Repository,
	upiClient integration.UPIClient,
	adBankClient integration.ADBankClient,
	wiseClient integration.WiseClient,
	config *Config,
) *RemittanceService {
	return &RemittanceService{
		repo:         repo,
		upiClient:    upiClient,
		adBankClient: adBankClient,
		wiseClient:   wiseClient,
		config:       config,
	}
}

// InitiateTransaction starts a new remittance transaction
func (s *RemittanceService) InitiateTransaction(
	ctx context.Context,
	userID string,
	amount float64,
	recipient *domain.RecipientDetails,
) (*domain.Transaction, error) {
	// Validate amount
	if err := s.validateAmount(amount); err != nil {
		return nil, err
	}

	// Validate recipient
	if err := s.validateRecipient(recipient); err != nil {
		return nil, err
	}

	// Check daily limit
	if err := s.checkDailyLimit(ctx, userID, amount); err != nil {
		return nil, err
	}

	// Get current exchange rate
	rate, err := s.GetExchangeRate(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get exchange rate: %w", err)
	}

	// Calculate fees
	fees := s.calculateFees(amount)

	// Create transaction
	tx := domain.NewTransaction(userID, amount, "INR", "CAD", recipient)
	tx.SetExchangeRate(rate)
	tx.SetFees(fees)
	tx.UpdateStatus(domain.StatusInitiated)

	// Save transaction
	if err := s.repo.CreateTransaction(ctx, tx); err != nil {
		return nil, fmt.Errorf("failed to create transaction: %w", err)
	}

	return tx, nil
}

// GetTransaction retrieves a transaction by ID
func (s *RemittanceService) GetTransaction(ctx context.Context, id string) (*domain.Transaction, error) {
	return s.repo.GetTransaction(ctx, id)
}

// ListUserTransactions retrieves transactions for a user
func (s *RemittanceService) ListUserTransactions(
	ctx context.Context,
	userID string,
	limit int,
	lastKey string,
) ([]*domain.Transaction, string, error) {
	return s.repo.ListTransactionsByUser(ctx, userID, limit, lastKey)
}

// GeneratePaymentLink creates a UPI payment link
func (s *RemittanceService) GeneratePaymentLink(ctx context.Context, txID string) (*domain.PaymentDetails, error) {
	// Get transaction
	tx, err := s.repo.GetTransaction(ctx, txID)
	if err != nil {
		return nil, fmt.Errorf("failed to get transaction: %w", err)
	}

	// Generate UPI link
	paymentLink, err := s.upiClient.GeneratePaymentLink(ctx, tx.ID, tx.SourceAmount)
	if err != nil {
		return nil, fmt.Errorf("failed to generate payment link: %w", err)
	}

	// Create payment record
	payment := &domain.PaymentDetails{
		PaymentID:   fmt.Sprintf("PAY-%s", tx.ID),
		PaymentLink: paymentLink,
		Status:      "PENDING",
	}

	if err := s.repo.CreatePayment(ctx, tx.ID, payment); err != nil {
		return nil, fmt.Errorf("failed to create payment record: %w", err)
	}

	// Update transaction status
	tx.UpdateStatus(domain.StatusPaymentPending)
	tx.SetPaymentDetails(payment)
	if err := s.repo.UpdateTransaction(ctx, tx); err != nil {
		return nil, fmt.Errorf("failed to update transaction: %w", err)
	}

	return payment, nil
}

// HandlePaymentCallback processes UPI payment callbacks
func (s *RemittanceService) HandlePaymentCallback(ctx context.Context, paymentID string, status string) error {
	// Get payment details
	payment, err := s.repo.GetPayment(ctx, paymentID)
	if err != nil {
		return fmt.Errorf("failed to get payment: %w", err)
	}

	// Update payment status
	payment.Status = status
	if status == "SUCCESS" {
		now := time.Now()
		payment.PaidAt = &now
	}

	// Get associated transaction
	tx, err := s.repo.GetTransaction(ctx, payment.PaymentID[4:]) // Remove "PAY-" prefix
	if err != nil {
		return fmt.Errorf("failed to get transaction: %w", err)
	}

	// Update transaction status
	if status == "SUCCESS" {
		tx.UpdateStatus(domain.StatusPaymentReceived)
		// Initiate transfer automatically
		go s.InitiateTransfer(context.Background(), tx.ID)
	} else if status == "FAILED" {
		tx.UpdateStatus(domain.StatusFailed)
	}

	// Save updates
	if err := s.repo.UpdatePayment(ctx, tx.ID, payment); err != nil {
		return fmt.Errorf("failed to update payment: %w", err)
	}

	if err := s.repo.UpdateTransaction(ctx, tx); err != nil {
		return fmt.Errorf("failed to update transaction: %w", err)
	}

	return nil
}

// GetExchangeRate retrieves current exchange rate from AD Bank
func (s *RemittanceService) GetExchangeRate(ctx context.Context) (float64, error) {
	return s.adBankClient.GetExchangeRate(ctx, "INR", "CAD")
}

// InitiateTransfer starts the cross-border transfer via Wise
func (s *RemittanceService) InitiateTransfer(ctx context.Context, txID string) error {
	// Get transaction
	tx, err := s.repo.GetTransaction(ctx, txID)
	if err != nil {
		return fmt.Errorf("failed to get transaction: %w", err)
	}

	// Verify transaction is in correct state
	if tx.Status != domain.StatusPaymentReceived {
		return ErrInvalidStatus
	}

	// Initiate transfer via Wise
	transferID, err := s.wiseClient.CreateTransfer(ctx, &integration.WiseTransferRequest{
		SourceAmount:   tx.SourceAmount,
		SourceCurrency: tx.SourceCurrency,
		TargetCurrency: tx.TargetCurrency,
		RecipientName:  tx.RecipientDetails.Name,
		BankAccount:    tx.RecipientDetails.BankAccount,
		BankCode:       tx.RecipientDetails.BankCode,
	})
	if err != nil {
		tx.UpdateStatus(domain.StatusFailed)
		if err := s.repo.UpdateTransaction(ctx, tx); err != nil {
			return fmt.Errorf("failed to update transaction: %w", err)
		}
		return fmt.Errorf("failed to create transfer: %w", err)
	}

	// Update transaction status and store transfer ID
	tx.UpdateStatus(domain.StatusProcessing)
	tx.TransferID = transferID
	if err := s.repo.UpdateTransaction(ctx, tx); err != nil {
		return fmt.Errorf("failed to update transaction: %w", err)
	}

	return nil
}

// HandleTransferCallback processes Wise transfer status callbacks
func (s *RemittanceService) HandleTransferCallback(ctx context.Context, txID string, status string) error {
	// Get transaction
	tx, err := s.repo.GetTransaction(ctx, txID)
	if err != nil {
		return fmt.Errorf("failed to get transaction: %w", err)
	}

	// Update transaction status based on transfer status
	switch status {
	case "COMPLETED":
		tx.UpdateStatus(domain.StatusCompleted)
	case "FAILED":
		tx.UpdateStatus(domain.StatusFailed)
	default:
		return ErrInvalidStatus
	}

	// Save updates
	if err := s.repo.UpdateTransaction(ctx, tx); err != nil {
		return fmt.Errorf("failed to update transaction: %w", err)
	}

	return nil
}

// Helper functions

func (s *RemittanceService) validateAmount(amount float64) error {
	if amount < s.config.MinAmount {
		return ErrInvalidAmount
	}
	if amount > s.config.MaxAmount {
		return ErrInvalidAmount
	}
	return nil
}

func (s *RemittanceService) validateRecipient(recipient *domain.RecipientDetails) error {
	if recipient == nil {
		return ErrInvalidRecipient
	}
	if recipient.BankAccount == "" || recipient.BankCode == "" || recipient.Name == "" {
		return ErrInvalidRecipient
	}
	return nil
}

func (s *RemittanceService) checkDailyLimit(ctx context.Context, userID string, amount float64) error {
	// Get today's transactions
	txns, _, err := s.repo.ListTransactionsByUser(ctx, userID, 100, "")
	if err != nil {
		return fmt.Errorf("failed to get user transactions: %w", err)
	}

	// Calculate daily total
	today := time.Now().UTC().Truncate(24 * time.Hour)
	var dailyTotal float64
	for _, tx := range txns {
		if tx.CreatedAt.After(today) && !tx.IsFailed() {
			dailyTotal += tx.SourceAmount
		}
	}

	if dailyTotal+amount > s.config.DailyLimit {
		return ErrDailyLimitExceeded
	}

	return nil
}

func (s *RemittanceService) calculateFees(amount float64) *domain.Fees {
	variableFee := amount * s.config.VariableFee
	if variableFee < 50 {
		variableFee = 50
	}
	if variableFee > 5000 {
		variableFee = 5000
	}

	return &domain.Fees{
		BaseFee:     s.config.BaseFee,
		VariableFee: variableFee,
		TotalFee:    s.config.BaseFee + variableFee,
	}
}
