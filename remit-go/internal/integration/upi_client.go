package integration

import (
	"context"
	"fmt"
	"net/http"

	"github.com/remit-demo/remit-go/internal/config"
)

type upiClient struct {
	client  *http.Client
	config  config.UPIConfig
	baseURL string
}

// NewUPIClient creates a new UPI payment gateway client
func NewUPIClient(cfg config.UPIConfig) UPIClient {
	client := &http.Client{
		Timeout: cfg.Timeout,
	}

	return &upiClient{
		client:  client,
		config:  cfg,
		baseURL: cfg.Endpoint,
	}
}

// GeneratePaymentLink creates a new UPI payment link
func (c *upiClient) GeneratePaymentLink(ctx context.Context, txID string, amount float64) (string, error) {
	// Implementation would make an HTTP request to generate payment link
	// This is a mock implementation
	paymentLink := fmt.Sprintf("upi://pay?pa=%s&pn=RemitGo&am=%f&tr=%s",
		c.config.VPA,
		amount,
		txID,
	)
	return paymentLink, nil
}

// VerifyPayment checks the status of a UPI payment
func (c *upiClient) VerifyPayment(ctx context.Context, paymentID string) (string, error) {
	// Implementation would make an HTTP request to check payment status
	// This is a mock implementation
	return "SUCCESS", nil
}
