package integration

import (
	"context"
	"net/http"
	"sync"
	"time"

	"github.com/remit-demo/remit-go/internal/config"
)

type adBankClient struct {
	client  *http.Client
	config  config.ADBankConfig
	baseURL string

	// Cache for exchange rates
	rateCache     map[string]float64
	rateCacheMu   sync.RWMutex
	lastRateCheck time.Time
}

// NewADBankClient creates a new AD Bank API client
func NewADBankClient(cfg config.ADBankConfig) ADBankClient {
	client := &http.Client{
		Timeout: cfg.Timeout,
	}

	return &adBankClient{
		client:    client,
		config:    cfg,
		baseURL:   cfg.Endpoint,
		rateCache: make(map[string]float64),
	}
}

// GetExchangeRate retrieves the current exchange rate
func (c *adBankClient) GetExchangeRate(ctx context.Context, sourceCurrency, targetCurrency string) (float64, error) {
	// Check cache first
	c.rateCacheMu.RLock()
	if time.Since(c.lastRateCheck) < c.config.RateRefreshInterval {
		if rate, ok := c.rateCache[sourceCurrency+targetCurrency]; ok {
			c.rateCacheMu.RUnlock()
			return rate, nil
		}
	}
	c.rateCacheMu.RUnlock()

	// Implementation would make an HTTP request to get current rates
	// This is a mock implementation
	c.rateCacheMu.Lock()
	defer c.rateCacheMu.Unlock()

	// Mock exchange rate: 1 INR = 0.016 CAD
	rate := 0.016
	c.rateCache[sourceCurrency+targetCurrency] = rate
	c.lastRateCheck = time.Now()

	return rate, nil
}

// ValidateAccount validates a bank account
func (c *adBankClient) ValidateAccount(ctx context.Context, bankCode, accountNumber string) (bool, error) {
	// Implementation would make an HTTP request to validate account
	// This is a mock implementation
	return true, nil
}
