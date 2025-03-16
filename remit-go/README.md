# Remit-Go: Cross-Border Remittance Service

A near real-time cross-border remittance service that facilitates money transfers between India and Canada. The service integrates with UPI for payment collection in India and uses Wise for international transfers to Canadian bank accounts.

## Features

- Real-time INR to CAD currency conversion
- UPI payment integration for collecting funds in India
- Wise integration for international transfers
- DynamoDB for transaction and payment data storage
- RESTful API with Gin framework
- Configurable fee structure and transaction limits
- Rate caching and exchange rate margin management
- Transaction status tracking and webhooks
- OpenAPI/Swagger documentation

## Prerequisites

- Go 1.21 or later
- Docker and Docker Compose
- AWS CLI (for local DynamoDB setup)

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/remit-go.git
cd remit-go
```

### 2. Environment Setup

Start the local DynamoDB instance:

```bash
docker-compose up -d
```

This will start:
- DynamoDB Local on port 8000
- DynamoDB Admin UI on port 8001

### 3. Configuration

The service uses YAML configuration files located in the `config` directory:

- `app.yaml`: Core application settings
- `provider.yaml`: External service provider configurations
- `rate.yaml`: Currency and fee configurations

Update the configuration files with your specific settings.

### 4. Build and Run

```bash
go mod tidy
go build -o remit-server ./cmd/server
./remit-server
```

The server will start on port 8080 by default.

## API Documentation

The API is documented using OpenAPI/Swagger specification. You can find the complete API documentation in:

```
api/swagger/swagger.yaml
```

To view the API documentation:

1. Install Swagger UI:
```bash
docker run -p 8083:8080 -e SWAGGER_JSON=/swagger/swagger.yaml -v $(pwd)/api/swagger:/swagger swaggerapi/swagger-ui
```

2. Open your browser and navigate to:
```
http://localhost:8083
```

The documentation includes:
- Detailed endpoint descriptions
- Request/response schemas
- Authentication requirements
- Error responses
- Example payloads

## API Endpoints

### Transactions

- `POST /api/v1/transactions`
  - Initiate a new remittance transaction
  - Requires user authentication

- `GET /api/v1/transactions/:id`
  - Get transaction details
  - Requires user authentication

- `GET /api/v1/transactions`
  - List user transactions
  - Supports pagination
  - Requires user authentication

### Payments

- `POST /api/v1/transactions/:id/payment`
  - Generate UPI payment link
  - Requires user authentication

### Exchange Rates

- `GET /api/v1/exchange-rate`
  - Get current INR to CAD exchange rate

### Callbacks

- `POST /api/v1/callbacks/payment`
  - UPI payment status webhook
  - Called by payment provider

- `POST /api/v1/callbacks/transfer`
  - Wise transfer status webhook
  - Called by Wise

## Architecture

### Components

1. **API Layer**
   - HTTP handlers using Gin framework
   - Request validation and response formatting
   - Authentication middleware (to be implemented)

2. **Service Layer**
   - Business logic implementation
   - Transaction flow management
   - Fee calculation and limit checks

3. **Repository Layer**
   - DynamoDB data persistence
   - Transaction and payment record management

4. **Integration Layer**
   - UPI payment gateway client
   - AD Bank exchange rate client
   - Wise transfer client

### Data Flow

1. User initiates transaction
2. System validates amount and recipient
3. Exchange rate is fetched and locked
4. UPI payment link is generated
5. User completes UPI payment
6. System receives payment confirmation
7. International transfer is initiated via Wise
8. Transfer status is tracked and updated

## Configuration

### Transaction Limits

- Minimum amount: 100 INR
- Maximum amount: 1,000,000 INR
- Daily limit per user: 2,000,000 INR

### Fee Structure

- Base fee: Fixed amount
- Variable fee: Percentage of transaction amount
- Wise fee: Pass-through with margin

### Exchange Rates

- Source: AD Bank API
- Cache duration: 5 minutes
- Margin: 0.5%

## Development

### Adding New Features

1. Define interfaces in appropriate packages
2. Implement business logic in service layer
3. Add repository methods if needed
4. Create API endpoints in handlers
5. Update configuration if required
6. Add tests for new functionality

### Testing

```bash
go test ./...
```

### Linting

```bash
golangci-lint run
```

## Production Deployment

For production deployment:

1. Use proper AWS credentials
2. Configure real DynamoDB tables
3. Set up proper UPI integration
4. Configure Wise API credentials
5. Implement proper authentication
6. Set up monitoring and logging
7. Configure proper SSL/TLS

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request 