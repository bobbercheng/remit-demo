package routes

import (
	"github.com/gin-gonic/gin"
	"github.com/remit-demo/remit-go/api/handlers"
)

// SetupRoutes configures the API routes
func SetupRoutes(router *gin.Engine, h *handlers.Handler) {
	// API v1 group
	v1 := router.Group("/api/v1")
	{
		// Transaction endpoints
		v1.POST("/transactions", h.InitiateTransaction)
		v1.GET("/transactions/:id", h.GetTransaction)
		v1.GET("/transactions", h.ListTransactions)

		// Payment endpoints
		v1.POST("/transactions/:id/payment", h.GeneratePaymentLink)

		// Exchange rate endpoint
		v1.GET("/exchange-rate", h.GetExchangeRate)

		// Callback endpoints
		callbacks := v1.Group("/callbacks")
		{
			callbacks.POST("/payment", h.HandlePaymentCallback)
			callbacks.POST("/transfer", h.HandleTransferCallback)
		}
	}
}
