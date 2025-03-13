# Cross-Border Remittance Service: India to Canada

A near real-time remittance service that enables money transfers from India to Canada, built with Python, FastAPI, and DynamoDB.

## Overview

This service facilitates cross-border remittances with the following workflow:

1. User initiates a remittance request with amount and recipient details
2. System calculates exchange rates and fees
3. User pays via UPI in India
4. System converts the currency via AD Bank integration
5. Funds are transmitted to a Canadian bank account via Wise
6. Status updates are provided throughout the process

## Architecture

The application follows a clean, functional architecture with strong typing and separation of concerns:

- **API Layer**: FastAPI endpoints that handle requests and responses
- **Service Layer**: Business logic for remittance processing
- **Data Layer**: DynamoDB repositories for data persistence
- **Integration Layer**: External service integrations (UPI, AD Bank, Wise)
- **Model Layer**: Pydantic models for validation and serialization

## Technology Stack

- **Backend**: Python 3.9+, FastAPI
- **Database**: Amazon DynamoDB
- **Containerization**: Docker, Docker Compose
- **External Services**:
  - UPI Payment Provider (mock)
  - AD Bank for currency conversion (mock)
  - Wise for international transfers (mock)

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Python 3.9 or higher (for local development)

### Running with Docker

1. Clone the repository:

```bash
git clone <repository-url>
cd remit-python
```

2. Start the services:

```bash
docker-compose up -d
```

3. Access the API documentation at http://localhost:8000/api/v1/docs

4. Access the DynamoDB Admin UI at http://localhost:8002

### Local Development

1. Install dependencies:

```bash
pip install -r requirements.txt
```

2. Start DynamoDB Local:

```bash
docker-compose up -d dynamodb dynamodb-admin
```

3. Run the application:

```bash
uvicorn app.main:app --reload
```

## API Documentation

The service provides the following main endpoints:

### Remittance Endpoints

- `POST /api/v1/remittances` - Create a new remittance request
- `POST /api/v1/remittances/{transaction_id}/confirm` - Confirm and initiate payment
- `GET /api/v1/remittances/{transaction_id}` - Get status of a remittance
- `GET /api/v1/remittances` - List user's remittances
- `POST /api/v1/remittances/calculate` - Calculate conversion without creating a transaction

### Exchange Rate Endpoints

- `GET /api/v1/rates/current` - Get current exchange rate
- `GET /api/v1/rates/historical` - Get historical exchange rates

### Webhook Endpoints

- `POST /api/v1/webhooks/upi` - UPI payment confirmations
- `POST /api/v1/webhooks/adbank` - AD Bank conversion callbacks
- `POST /api/v1/webhooks/wise` - Wise transfer status updates

## Configuration

Configuration is managed through:

- Environment variables
- JSON configuration files per environment (dev, test, prod)
- Pydantic settings model

Key configuration settings:

- External service URLs and credentials
- Transaction limits and fees
- DynamoDB connection details
- Timeouts and retry settings

## Sample Transaction Flow

1. **Initiate Transaction**:
   ```
   POST /api/v1/remittances
   {
     "amount_inr": 10000,
     "sender_id": "user123",
     "recipient": {
       "full_name": "John Doe",
       "bank_name": "Royal Bank of Canada",
       "account_number": "12345678",
       "transit_number": "12345",
       "institution_number": "123",
       "phone": "+16135551234",
       "email": "john.doe@example.com"
     }
   }
   ```

2. **Confirm Payment**:
   ```
   POST /api/v1/remittances/{transaction_id}/confirm
   {
     "upi_details": {
       "upi_id": "user@okbank"
     }
   }
   ```

3. **Check Status**:
   ```
   GET /api/v1/remittances/{transaction_id}
   ```

## Database Schema

The service uses three main DynamoDB tables:

1. **Transactions** - Main transaction data
   - Primary key: `transaction_id`
   - GSI: `user_id` for user-based queries

2. **TransactionEvents** - Event history for audit
   - Primary key: `transaction_id` (partition), `event_id` (sort)

3. **ExchangeRates** - Historical exchange rates
   - Primary key: `currency_pair` (partition), `timestamp` (sort)

## Testing

The codebase includes:

- Unit tests for business logic
- Integration tests for API endpoints
- Mock implementations of external services

Run tests with:

```bash
pytest
```

## License

[MIT](LICENSE) 