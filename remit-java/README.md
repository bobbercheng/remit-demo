# Remittance Service

A near real-time cross-border remittance service between India and Canada built with Spring Boot and reactive programming.

## Overview

This service provides a platform for users to send money from India to Canada with the following features:

- Fund collection in India via UPI
- Currency conversion through an AD Bank
- Cross-border disbursement to Canadian bank accounts via Wise
- Near real-time transaction processing
- Comprehensive transaction tracking

## Architecture

The service follows a hexagonal architecture with reactive programming principles:

- **API Layer**: REST controllers with WebFlux
- **Domain Layer**: Core business entities and logic
- **Service Layer**: Business process orchestration
- **Integration Layer**: External service integrations (UPI, AD Bank, Wise)
- **Persistence Layer**: DynamoDB for data storage

## Workflow

1. **Transaction Initiation**:
   - User initiates a remittance transaction
   - System validates and creates a transaction with "INITIATED" status

2. **Fund Collection**:
   - System generates UPI payment request
   - User completes payment
   - System receives payment confirmation
   - Transaction status updated to "FUNDED"

3. **Currency Conversion**:
   - System requests exchange rate from AD Bank
   - Currency conversion is executed
   - Transaction status updated to "CONVERTED"

4. **Cross-Border Transmission**:
   - System initiates transfer through Wise API
   - Wise processes the cross-border transfer
   - Transaction status updated to "PROCESSING"

5. **Disbursement Confirmation**:
   - System receives confirmation of funds deposit
   - Transaction status updated to "COMPLETED"

## Setup and Running

### Prerequisites

- Java 17
- Docker and Docker Compose

### Local Development

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/remit-service.git
   cd remit-service
   ```

2. Start DynamoDB Local:
   ```
   docker-compose up -d
   ```

3. Build the application:
   ```
   ./gradlew build
   ```

4. Run the application:
   ```
   ./gradlew bootRun
   ```

5. Access the API documentation:
   ```
   http://localhost:8080/swagger-ui.html
   ```

6. Access DynamoDB Admin UI:
   ```
   http://localhost:8001
   ```

## Configuration

The application is configured through `application.yml` with the following key sections:

- **Integration Configurations**: Settings for UPI, AD Bank, and Wise integrations
- **Business Rules**: Transaction limits, fees, and supported currencies
- **DynamoDB Configuration**: Database connection settings
- **Resilience Configuration**: Retry and circuit breaker settings

## API Documentation

The API is documented using OpenAPI/Swagger and can be accessed at `/swagger-ui.html` when the application is running.

A complete OpenAPI specification is available as a JSON file at:
```
src/main/resources/static/swagger/remittance-api-spec.json
```

Key endpoints:

- `POST /api/v1/transactions`: Initiate a new transaction
- `GET /api/v1/transactions`: Get all transactions
- `GET /api/v1/transactions/{id}`: Get a specific transaction
- `POST /api/v1/transactions/{id}/payment`: Generate payment instructions
- `GET /api/v1/exchange-rates`: Get current exchange rate

## Testing

Run tests with:

```
./gradlew test
```

## License

This project is proprietary and confidential.

## Contact

For questions or support, contact the Remittance Service Team at contact@remitservice.com. 