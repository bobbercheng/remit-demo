package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	awsconfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/gin-gonic/gin"
	"github.com/remit-demo/remit-go/api/handlers"
	"github.com/remit-demo/remit-go/api/routes"
	"github.com/remit-demo/remit-go/internal/config"
	"github.com/remit-demo/remit-go/internal/integration"
	"github.com/remit-demo/remit-go/internal/repository"
	"github.com/remit-demo/remit-go/internal/service"
)

func main() {
	// Load configuration
	cfg := loadConfig()

	// Initialize AWS DynamoDB client
	awsCfg, err := awsconfig.LoadDefaultConfig(context.Background(),
		awsconfig.WithRegion(cfg.Database.DynamoDB.Region),
		awsconfig.WithEndpointResolverWithOptions(
			aws.EndpointResolverWithOptionsFunc(
				func(service, region string, options ...interface{}) (aws.Endpoint, error) {
					return aws.Endpoint{
						URL: cfg.Database.DynamoDB.Endpoint,
					}, nil
				},
			),
		),
	)
	if err != nil {
		log.Fatalf("unable to load AWS SDK config: %v", err)
	}

	dynamoClient := dynamodb.NewFromConfig(awsCfg)

	// Initialize repository
	repo := repository.NewDynamoDBRepository(
		dynamoClient,
		cfg.Database.DynamoDB.Tables.Transaction,
		cfg.Database.DynamoDB.Tables.Payment,
	)

	// Initialize external service clients
	upiClient := integration.NewUPIClient(cfg.UPI)
	adBankClient := integration.NewADBankClient(cfg.ADBank)
	wiseClient := integration.NewWiseClient(cfg.Wise)

	// Initialize service
	svc := service.NewRemittanceService(repo, upiClient, adBankClient, wiseClient, &service.Config{
		MinAmount:    cfg.Limits.MinAmount,
		MaxAmount:    cfg.Limits.MaxAmount,
		DailyLimit:   cfg.Limits.DailyLimit,
		BaseFee:      cfg.Fees.Base.Amount,
		VariableFee:  cfg.Fees.Percentage.Rate,
		RateValidity: cfg.CurrencyPairs[0].MinRateValidity,
	})

	// Initialize HTTP handler
	handler := handlers.NewHandler(svc)

	// Set up Gin router
	router := gin.Default()

	// Configure routes
	routes.SetupRoutes(router, handler)

	// Start server
	srv := &http.Server{
		Addr:    ":" + cfg.Server.Port,
		Handler: router,
	}

	// Graceful shutdown
	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("listen: %s\n", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatal("Server forced to shutdown:", err)
	}

	log.Println("Server exiting")
}

func loadConfig() *config.Config {
	// Implementation depends on your configuration management choice
	// You could use Viper, environment variables, or other methods
	return &config.Config{
		Server: config.ServerConfig{
			Port: "8080",
		},
		Database: config.DatabaseConfig{
			DynamoDB: config.DynamoDBConfig{
				Endpoint: "http://localhost:8000",
				Region:   "us-west-2",
				Tables: config.TablesConfig{
					Transaction: "remit_transactions",
					Payment:     "remit_payments",
				},
			},
		},
		// ... other configuration values loaded from config files
	}
}
