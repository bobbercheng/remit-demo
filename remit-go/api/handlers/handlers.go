package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/remit-demo/remit-go/internal/domain"
	"github.com/remit-demo/remit-go/internal/service"
)

// Handler handles HTTP requests
type Handler struct {
	svc service.Service
}

// NewHandler creates a new handler instance
func NewHandler(svc service.Service) *Handler {
	return &Handler{svc: svc}
}

// InitiateTransaction handles transaction initiation requests
func (h *Handler) InitiateTransaction(c *gin.Context) {
	var req struct {
		Amount    float64                  `json:"amount" binding:"required,gt=0"`
		Recipient *domain.RecipientDetails `json:"recipient" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get user ID from context (set by auth middleware)
	userID := c.GetString("user_id")
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	tx, err := h.svc.InitiateTransaction(c.Request.Context(), userID, req.Amount, req.Recipient)
	if err != nil {
		switch err {
		case service.ErrInvalidAmount:
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid amount"})
		case service.ErrInvalidRecipient:
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid recipient details"})
		case service.ErrDailyLimitExceeded:
			c.JSON(http.StatusBadRequest, gin.H{"error": "daily limit exceeded"})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error"})
		}
		return
	}

	c.JSON(http.StatusCreated, tx)
}

// GetTransaction handles transaction retrieval requests
func (h *Handler) GetTransaction(c *gin.Context) {
	txID := c.Param("id")
	if txID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "transaction ID required"})
		return
	}

	tx, err := h.svc.GetTransaction(c.Request.Context(), txID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to get transaction"})
		return
	}

	if tx == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "transaction not found"})
		return
	}

	c.JSON(http.StatusOK, tx)
}

// ListTransactions handles transaction listing requests
func (h *Handler) ListTransactions(c *gin.Context) {
	userID := c.GetString("user_id")
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	limit := 10 // Default limit
	if limitStr := c.Query("limit"); limitStr != "" {
		// Parse limit from query parameter
	}

	lastKey := c.Query("last_key")

	txns, nextKey, err := h.svc.ListUserTransactions(c.Request.Context(), userID, limit, lastKey)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list transactions"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"transactions": txns,
		"next_key":     nextKey,
	})
}

// GeneratePaymentLink handles payment link generation requests
func (h *Handler) GeneratePaymentLink(c *gin.Context) {
	txID := c.Param("id")
	if txID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "transaction ID required"})
		return
	}

	payment, err := h.svc.GeneratePaymentLink(c.Request.Context(), txID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate payment link"})
		return
	}

	c.JSON(http.StatusOK, payment)
}

// HandlePaymentCallback processes payment status callbacks
func (h *Handler) HandlePaymentCallback(c *gin.Context) {
	var req struct {
		PaymentID string `json:"payment_id" binding:"required"`
		Status    string `json:"status" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.svc.HandlePaymentCallback(c.Request.Context(), req.PaymentID, req.Status); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to process payment callback"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "success"})
}

// HandleTransferCallback processes transfer status callbacks
func (h *Handler) HandleTransferCallback(c *gin.Context) {
	var req struct {
		TransactionID string `json:"transaction_id" binding:"required"`
		Status        string `json:"status" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.svc.HandleTransferCallback(c.Request.Context(), req.TransactionID, req.Status); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to process transfer callback"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "success"})
}

// GetExchangeRate handles exchange rate requests
func (h *Handler) GetExchangeRate(c *gin.Context) {
	rate, err := h.svc.GetExchangeRate(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to get exchange rate"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"rate": rate})
}
