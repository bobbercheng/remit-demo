from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import logging
import boto3
import uuid
import json
import time
from typing import Dict, Any

from app.api.v1.api import api_router
from config.settings import get_settings

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


# Create settings
settings = get_settings()


# Create application
app = FastAPI(
    title=settings.PROJECT_NAME,
    description="API for cross-border remittance from India to Canada",
    version="1.0.0",
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url=f"{settings.API_V1_STR}/docs",
    redoc_url=f"{settings.API_V1_STR}/redoc",
)


# Configure middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict this to specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def add_request_id(request: Request, call_next):
    """Add a unique request ID to each request for tracing"""
    request_id = str(uuid.uuid4())
    response = await call_next(request)
    response.headers["X-Request-ID"] = request_id
    return response


@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log request details for monitoring and debugging"""
    start_time = time.time()
    method = request.method
    url = request.url.path
    
    logger.info(f"Request: {method} {url}")
    
    response = await call_next(request)
    
    process_time = time.time() - start_time
    logger.info(f"Response: {method} {url} - Status: {response.status_code} - Time: {process_time:.4f}s")
    
    return response


# Include API routes
app.include_router(
    api_router,
    prefix=settings.API_V1_STR
)


# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Global exception handler for unexpected errors"""
    logger.error(f"Unhandled exception: {str(exc)}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "An unexpected error occurred. Please try again later."},
    )


# Health check endpoint
@app.get("/health")
async def health_check() -> Dict[str, Any]:
    """Health check endpoint for monitoring"""
    return {
        "status": "healthy",
        "timestamp": time.time(),
        "version": "1.0.0",
        "env": settings.ENV
    }


# Startup event
@app.on_event("startup")
async def startup_event():
    """Initialize resources on application startup"""
    logger.info("Starting remittance service...")
    
    # Create DynamoDB tables if in development mode
    if settings.ENV == "dev" or settings.ENV == "test":
        try:
            # Set up DynamoDB client
            dynamodb = boto3.resource(
                'dynamodb',
                endpoint_url=f"http://{settings.DYNAMODB_HOST}:{settings.DYNAMODB_PORT}",
                region_name=settings.DYNAMODB_REGION,
                aws_access_key_id=settings.DYNAMODB_ACCESS_KEY,
                aws_secret_access_key=settings.DYNAMODB_SECRET_KEY
            )
            
            # Create tables
            
            # Transactions table
            tables = [
                {
                    "TableName": "Transactions",
                    "KeySchema": [
                        {"AttributeName": "transaction_id", "KeyType": "HASH"}
                    ],
                    "AttributeDefinitions": [
                        {"AttributeName": "transaction_id", "AttributeType": "S"},
                        {"AttributeName": "user_id", "AttributeType": "S"}
                    ],
                    "GlobalSecondaryIndexes": [
                        {
                            "IndexName": "UserIndex",
                            "KeySchema": [
                                {"AttributeName": "user_id", "KeyType": "HASH"}
                            ],
                            "Projection": {
                                "ProjectionType": "ALL"
                            },
                            "ProvisionedThroughput": {
                                "ReadCapacityUnits": 5,
                                "WriteCapacityUnits": 5
                            }
                        }
                    ],
                    "ProvisionedThroughput": {
                        "ReadCapacityUnits": 5,
                        "WriteCapacityUnits": 5
                    }
                },
                {
                    "TableName": "TransactionEvents",
                    "KeySchema": [
                        {"AttributeName": "transaction_id", "KeyType": "HASH"},
                        {"AttributeName": "event_id", "KeyType": "RANGE"}
                    ],
                    "AttributeDefinitions": [
                        {"AttributeName": "transaction_id", "AttributeType": "S"},
                        {"AttributeName": "event_id", "AttributeType": "S"}
                    ],
                    "ProvisionedThroughput": {
                        "ReadCapacityUnits": 5,
                        "WriteCapacityUnits": 5
                    }
                },
                {
                    "TableName": "ExchangeRates",
                    "KeySchema": [
                        {"AttributeName": "currency_pair", "KeyType": "HASH"},
                        {"AttributeName": "timestamp", "KeyType": "RANGE"}
                    ],
                    "AttributeDefinitions": [
                        {"AttributeName": "currency_pair", "AttributeType": "S"},
                        {"AttributeName": "timestamp", "AttributeType": "S"}
                    ],
                    "ProvisionedThroughput": {
                        "ReadCapacityUnits": 5,
                        "WriteCapacityUnits": 5
                    }
                }
            ]
            
            for table_config in tables:
                try:
                    table = dynamodb.create_table(**table_config)
                    logger.info(f"Created table {table_config['TableName']}")
                except Exception as e:
                    if "Table already exists" in str(e):
                        logger.info(f"Table {table_config['TableName']} already exists")
                    else:
                        raise
            
            logger.info("DynamoDB tables created successfully")
            
        except Exception as e:
            logger.warning(f"Error setting up DynamoDB tables: {str(e)}")
            # Continue even if table creation fails
    
    logger.info("Remittance service startup complete")


# Shutdown event
@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup resources on application shutdown"""
    logger.info("Shutting down remittance service...")
    # Close any open connections or resources here
    logger.info("Remittance service shutdown complete") 