# Remit - Cross-Border Remittance Service

A near real-time cross-border remittance service between India and Canada, built with Elixir and Phoenix.

## Overview

Remit is a service that enables users to send money from India to Canada. The system handles:

1. Fund collection via UPI in India
2. Currency conversion through an Authorized Dealer (AD) Bank
3. Fund transmission to Canada using Wise

The service is designed with a focus on reliability, traceability, and functional programming principles.

## Architecture

The system is built with a modular architecture:

- **API Layer**: Phoenix controllers and views for handling HTTP requests
- **Remittance Core**: Business logic for transaction processing
- **Partner Integrations**: Modules for UPI, AD Bank, and Wise
- **Persistence Layer**: DynamoDB for storing transaction data
- **Configuration**: Environment-specific settings

## Transaction Flow

1. **Initiation**: User initiates a remittance transaction
2. **Fund Collection**: System generates a UPI payment link for the sender
3. **Currency Conversion**: Once funds are collected, the system converts INR to CAD
4. **Transmission**: Converted funds are sent to the recipient in Canada
5. **Completion**: Transaction is marked as completed

## Transaction States

- `initiated`: Transaction has been created
- `funds_collected`: Payment has been received via UPI
- `conversion_in_progress`: Currency conversion has started
- `conversion_completed`: Currency conversion is complete
- `transmission_in_progress`: Funds are being sent to recipient
- `completed`: Transaction is complete
- `failed`: Transaction has failed

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/remittances` | Create a new remittance transaction |
| GET | `/api/remittances/:id` | Get a transaction by ID |
| GET | `/api/remittances/sender/:sender_id` | Get transactions by sender ID |
| GET | `/api/remittances/recipient/:recipient_id` | Get transactions by recipient ID |
| GET | `/api/exchange-rates` | Get current exchange rate |
| POST | `/api/callbacks/payment` | Callback endpoint for UPI payment notifications |

## API Documentation

API documentation is available via Swagger UI at `/api/swagger/index.html` when the server is running.

## Setup and Installation

### Prerequisites

- Elixir 1.14+
- Erlang 25+
- Docker and Docker Compose (for local DynamoDB)

### Local Development

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/remit.git
   cd remit
   ```

2. Install dependencies:
   ```
   mix deps.get
   ```

3. Start DynamoDB local:
   ```
   docker-compose up -d
   ```

4. Create DynamoDB tables:
   ```
   mix remit.setup
   ```

5. Start the Phoenix server:
   ```
   mix phx.server
   ```

The server will be available at http://localhost:4000.

## Configuration

Configuration is managed through environment variables and config files:

- `config/config.exs`: Base configuration
- `config/dev.exs`: Development environment settings
- `config/test.exs`: Test environment settings
- `config/runtime.exs`: Runtime configuration

Key configuration parameters:

- `DYNAMODB_HOST`: DynamoDB host (default: "http://localhost:8000")
- `UPI_API_URL`: UPI provider API URL
- `ADBANK_API_URL`: AD Bank API URL
- `WISE_API_URL`: Wise API URL

## Testing

Run the test suite:

```
mix test
```

The project includes:

- Unit tests for core business logic
- Integration tests for API endpoints
- Mock implementations for external services

## Deployment

The application can be deployed as a Docker container or directly to a cloud provider:

### Docker

1. Build the Docker image:
   ```
   docker build -t remit:latest .
   ```

2. Run the container:
   ```
   docker run -p 4000:4000 -e PORT=4000 -e DYNAMODB_HOST=<your-dynamodb-url> remit:latest
   ```

### Cloud Deployment

For production deployment, consider using:

- AWS Elastic Beanstalk
- Heroku
- Fly.io
- Gigalixir

## Project Structure

```
remit/
├── config/                 # Configuration files
├── lib/
│   ├── remit/              # Core business logic
│   │   ├── remittance/     # Remittance service
│   │   ├── partners/       # Partner integrations
│   │   └── persistence/    # Database operations
│   └── remit_web/          # Phoenix web components
│       ├── controllers/    # API controllers
│       ├── views/          # JSON rendering
│       └── router.ex       # API routes
├── priv/
│   └── openapi/           # OpenAPI/Swagger definition
├── test/                  # Test files
└── docker-compose.yml     # Local development services
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
