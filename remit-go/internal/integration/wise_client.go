package integration

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/remit-demo/remit-go/internal/config"
)

type wiseClient struct {
	client    *http.Client
	config    config.WiseConfig
	baseURL   string
	profileID string
}

// NewWiseClient creates a new Wise API client
func NewWiseClient(cfg config.WiseConfig) WiseClient {
	client := &http.Client{
		Timeout: cfg.Timeout,
	}

	return &wiseClient{
		client:    client,
		config:    cfg,
		baseURL:   cfg.Endpoint,
		profileID: cfg.ProfileID,
	}
}

// CreateTransfer initiates a new transfer via Wise
func (c *wiseClient) CreateTransfer(ctx context.Context, req *WiseTransferRequest) (string, error) {
	// Implementation would make an HTTP request to create transfer
	// This is a mock implementation
	transferID := fmt.Sprintf("TR-%d", time.Now().Unix())
	return transferID, nil
}

// GetTransferStatus checks the status of a transfer
func (c *wiseClient) GetTransferStatus(ctx context.Context, transferID string) (string, error) {
	// Implementation would make an HTTP request to check transfer status
	// This is a mock implementation
	return "COMPLETED", nil
}
