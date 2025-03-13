# Remit Rust: Cross-Border Remittance Service

A near real-time cross-border remittance service between India and Canada built with Rust and Actix Web.

## Features

- User verification and KYC validation (via external User Service)
- Fund collection in India via UPI
- Currency conversion via AD Bank
- Cross-border transfer to Canada via Wise
- Real-time transaction status tracking
- Webhook support for payment and transfer notifications
- OpenAPI/Swagger documentation

## Architecture

The service follows a clean architecture approach with the following components:

1. **API Layer**: Handles HTTP requests/responses using Actix Web
2. **Service Layer**: Contains the core business logic
3. **Repository Layer**: Manages data persistence with DynamoDB
4. **Integration Layer**: Connects to external services (UPI, AD Bank, Wise, User Service)

## Remittance Flow

1. **Initiation**: User creates a remittance transaction
2. **Fund Collection**: User pays via UPI in India
3. **Currency Conversion**: INR is converted to CAD via AD Bank
4. **Transfer**: Funds are transferred to Canadian bank account via Wise
5. **Completion**: Transaction is marked as completed when funds are available in recipient's account

## Getting Started

### Prerequisites

- Rust (1.60+)
- Docker and Docker Compose
- AWS CLI (for local DynamoDB setup)

### Setup

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/remit-rust.git
   cd remit-rust
   ```

2. Start the local development environment:
   ```
   docker-compose up -d
   ```

3. Build and run the application:
   ```
   cargo run
   ```

4. Access the API documentation:
   ```
   http://localhost:3000/api/docs
   ```

## Configuration

The application uses a hierarchical configuration system:

1. `config/default.toml`: Base configuration
2. `config/development.toml`: Development environment overrides
3. `config/production.toml`: Production environment overrides
4. Environment variables: Override any config value with `REMIT__SECTION__KEY`

## API Endpoints

### Remittance

- `POST /api/v1/remittance`: Create a new remittance transaction
- `GET /api/v1/remittance/{transaction_id}`: Get transaction details
- `POST /api/v1/remittance/{transaction_id}/payment`: Initiate payment
- `GET /api/v1/remittance/{transaction_id}/status`: Check transaction status
- `GET /api/v1/remittance/user/{user_id}`: Get user transactions
- `POST /api/v1/remittance/estimate`: Estimate exchange rate and fees

### Webhooks

- `POST /api/v1/webhooks/upi-callback`: UPI payment notification
- `POST /api/v1/webhooks/wise-callback`: Wise transfer notification

## Testing

Run the test suite:

```
cargo test
```

## Deployment

For production deployment, set the following environment variables:

- `RUN_MODE=production`
- `AWS_REGION`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `UPI_API_KEY`
- `AD_BANK_API_KEY`
- `AD_BANK_CLIENT_ID`
- `WISE_API_KEY`
- `WISE_PROFILE_ID`
- `USER_SERVICE_API_KEY`

## License

This project is licensed under the MIT License - see the LICENSE file for details. 