package config

import "time"

// Config represents the application configuration
type Config struct {
	Server        ServerConfig         `yaml:"server"`
	Database      DatabaseConfig       `yaml:"database"`
	UPI           UPIConfig            `yaml:"upi"`
	ADBank        ADBankConfig         `yaml:"ad_bank"`
	Wise          WiseConfig           `yaml:"wise"`
	Limits        LimitsConfig         `yaml:"limits"`
	Fees          FeesConfig           `yaml:"fees"`
	CurrencyPairs []CurrencyPairConfig `yaml:"currency_pairs"`
}

// ServerConfig holds server-related configuration
type ServerConfig struct {
	Port    string        `yaml:"port"`
	Timeout TimeoutConfig `yaml:"timeout"`
}

// TimeoutConfig holds timeout settings
type TimeoutConfig struct {
	Read  time.Duration `yaml:"read"`
	Write time.Duration `yaml:"write"`
	Idle  time.Duration `yaml:"idle"`
}

// DatabaseConfig holds database configuration
type DatabaseConfig struct {
	DynamoDB DynamoDBConfig `yaml:"dynamodb"`
}

// DynamoDBConfig holds DynamoDB configuration
type DynamoDBConfig struct {
	Endpoint string       `yaml:"endpoint"`
	Region   string       `yaml:"region"`
	Tables   TablesConfig `yaml:"tables"`
}

// TablesConfig holds DynamoDB table names
type TablesConfig struct {
	Transaction string `yaml:"transaction"`
	Payment     string `yaml:"payment"`
}

// UPIConfig holds UPI payment gateway configuration
type UPIConfig struct {
	Provider string        `yaml:"provider"`
	Endpoint string        `yaml:"endpoint"`
	Timeout  time.Duration `yaml:"timeout"`
	Retry    RetryConfig   `yaml:"retry"`
	VPA      string        `yaml:"vpa"` // Virtual Payment Address for receiving payments
}

// ADBankConfig holds AD Bank API configuration
type ADBankConfig struct {
	Endpoint            string        `yaml:"endpoint"`
	Timeout             time.Duration `yaml:"timeout"`
	RateRefreshInterval time.Duration `yaml:"rate_refresh_interval"`
	Retry               RetryConfig   `yaml:"retry"`
}

// WiseConfig holds Wise API configuration
type WiseConfig struct {
	Endpoint  string        `yaml:"endpoint"`
	Timeout   time.Duration `yaml:"timeout"`
	ProfileID string        `yaml:"profile_id"`
	Retry     RetryConfig   `yaml:"retry"`
}

// RetryConfig holds retry settings
type RetryConfig struct {
	MaxAttempts     int           `yaml:"max_attempts"`
	InitialInterval time.Duration `yaml:"initial_interval"`
	MaxInterval     time.Duration `yaml:"max_interval"`
}

// LimitsConfig holds transaction limit settings
type LimitsConfig struct {
	MinAmount  float64 `yaml:"min_amount"`
	MaxAmount  float64 `yaml:"max_amount"`
	DailyLimit float64 `yaml:"daily_limit"`
}

// FeesConfig holds fee structure configuration
type FeesConfig struct {
	Base       FeeConfig `yaml:"base"`
	Percentage FeeConfig `yaml:"percentage"`
	Wise       FeeConfig `yaml:"wise"`
}

// FeeConfig holds fee settings
type FeeConfig struct {
	Type   string  `yaml:"type"`
	Amount float64 `yaml:"amount"`
	Rate   float64 `yaml:"rate"`
	Min    float64 `yaml:"min"`
	Max    float64 `yaml:"max"`
}

// CurrencyPairConfig holds currency pair settings
type CurrencyPairConfig struct {
	Source          string        `yaml:"source"`
	Target          string        `yaml:"target"`
	Enabled         bool          `yaml:"enabled"`
	Margin          float64       `yaml:"margin"`
	MinRateValidity time.Duration `yaml:"min_rate_validity"`
}
