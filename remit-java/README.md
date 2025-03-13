# Remit - Cross-Border Remittance Service

A near real-time cross-border remittance service between India and Canada, built with Spring Boot and Reactive programming.

## Features

- User-friendly API for initiating and tracking remittances
- Near real-time fund transfers from India to Canada
- Secure processing with comprehensive audit trails
- Integration with UPI for Indian fund collection
- Integration with AD Bank for currency conversion
- Integration with Wise for fund transmission to Canada
- Reactive architecture for high throughput and concurrency

## Technical Architecture

- Java 17
- Spring Boot 3.x with WebFlux for reactive programming
- PostgreSQL with R2DBC for reactive database access
- Flyway for database migrations
- Spring Cloud OpenFeign for API integrations
- Resilience4j for fault tolerance
- OpenAPI/Swagger for API documentation

## System Workflow

1. **Initiation Phase**: User initiates remittance request
2. **Fund Collection Phase**: Funds collected via UPI in India
3. **Currency Conversion Phase**: INR converted to CAD via AD Bank
4. **Transmission Phase**: Funds sent to Canada via Wise
5. **Completion Phase**: Confirmation of successful delivery

## Getting Started

### Prerequisites

- Java 17+
- Maven 3.8+
- PostgreSQL 14+
- Docker (optional, for containerization)

### Setup

1. Clone the repository:
   ```
   git clone https://github.com/fintech/remit.git
   cd remit
   ```

2. Create a PostgreSQL database:
   ```
   createdb remitdb
   ```

3. Configure application properties in `src/main/resources/application.yml` or using environment variables.

4. Build the application:
   ```
   mvn clean install
   ```

5. Run the application:
   ```
   mvn spring-boot:run
   ```

6. Access the API documentation:
   ```
   http://localhost:8080/swagger-ui.html
   ```

### Running with Docker

```
docker-compose up -d
```

## Configuration

The application uses externalized configuration for all integration parameters and business rules. The following environment variables can be configured:

### Database Configuration
- `DATABASE_URL`: R2DBC URL for PostgreSQL
- `DATABASE_USER`: Database username
- `DATABASE_PASSWORD`: Database password

### UPI Configuration
- `UPI_API_KEY`: API key for UPI integration
- `UPI_CALLBACK_URL`: Callback URL for UPI payment notifications

### AD Bank Configuration
- `ADBANK_CLIENT_ID`: Client ID for AD Bank integration
- `ADBANK_CLIENT_SECRET`: Client secret for AD Bank integration

### Wise Configuration
- `WISE_API_KEY`: API key for Wise integration
- `WISE_PROFILE_ID`: Profile ID for Wise integration
- `WISE_WEBHOOK_URL`: Webhook URL for Wise payment notifications

## API Documentation

The API is documented using OpenAPI/Swagger. When the application is running, you can access the documentation at:

```
http://localhost:8080/swagger-ui.html
```

## Testing

Run unit and integration tests:

```
mvn test
```

## License

MIT License 