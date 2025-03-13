# Remit-Node: Cross-Border Remittance Service

A near real-time cross-border remittance service between India and Canada, built with TypeScript and Next.js.

## Overview

This service enables users to send money from India to Canada through a secure, efficient, and transparent process. The system handles the entire remittance workflow:

1. **Initiation**: User submits remittance details
2. **Payment Collection**: User pays in INR via UPI
3. **Currency Conversion**: INR is converted to CAD through AD Bank
4. **Transfer to Canada**: Funds are sent to Canadian bank accounts via Wise

## Architecture

The service follows a clean architecture approach with the following components:

- **API Layer**: RESTful endpoints using Next.js API routes
- **Service Layer**: Core business logic for remittance operations
- **Integration Layer**: External API integrations (UPI, AD Bank, Wise)
- **Persistence Layer**: DynamoDB for transaction storage
- **Configuration Layer**: Environment-based configuration management

## Remittance Workflow

![Remittance Workflow](docs/workflow.png)

1. **Initiation**: User submits remittance request with recipient details
2. **Payment**: User pays in INR via UPI, payment confirmation via webhook
3. **Conversion**: INR is converted to CAD through AD Bank integration
4. **Transfer**: Funds are sent to Canadian account via Wise integration
5. **Completion**: User is notified of successful remittance

Each transaction progresses through multiple statuses:
- INITIATED → PAYMENT_RECEIVED → CURRENCY_CONVERTED → TRANSFER_INITIATED → COMPLETED
- (or FAILED at any stage)

## Getting Started

### Prerequisites

- Node.js 18+
- Docker and Docker Compose (for local DynamoDB)
- AWS account (for production deployment)

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/remit-node.git
   cd remit-node
   ```

2. Install dependencies:
   ```
   npm install
   ```

3. Set up environment variables:
   ```
   cp .env.example .env.local
   ```
   Edit `.env.local` with your configuration values.

4. Start local DynamoDB:
   ```
   npm run dynamo:start
   ```

5. Initialize database tables:
   ```
   npx ts-node lib/db/schema/init-db.ts
   ```

6. Run the development server:
   ```
   npm run dev
   ```

7. Access the API at http://localhost:3000

## API Documentation

The API is documented using OpenAPI/Swagger. You can view the API documentation at:

- `/docs/openapi.json` - OpenAPI specification
- Import the OpenAPI spec into tools like Postman or Swagger UI for interactive documentation

### Key Endpoints

- `POST /api/remittance` - Create a new remittance transaction
- `GET /api/remittance/{transactionId}` - Get transaction details
- `PATCH /api/remittance/{transactionId}` - Check and update transaction status
- `POST /api/remittance/payment-webhook` - Webhook for UPI payment notifications
- `GET /api/exchange-rate` - Get current exchange rate
- `GET /api/exchange-rate/history` - Get historical exchange rates

## Configuration

The service is highly configurable through environment variables. See `.env.example` for all available options:

- **App Configuration**: Environment, port, etc.
- **DynamoDB Configuration**: Endpoint, region, credentials
- **Integration Configurations**: API endpoints and credentials for UPI, AD Bank, and Wise
- **Transaction Limits**: Min/max amounts for transactions
- **Fee Configuration**: Fixed and percentage fees

## Testing

Run the test suite:

```
npm test
```

Run tests in watch mode:

```
npm run test:watch
```

## Deployment

### AWS Deployment

1. Set up AWS credentials
2. Configure DynamoDB tables in production
3. Deploy using your preferred method (AWS Amplify, Vercel, etc.)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Next.js](https://nextjs.org/)
- [DynamoDB](https://aws.amazon.com/dynamodb/)
- [TypeScript](https://www.typescriptlang.org/)
- [Zod](https://github.com/colinhacks/zod) 