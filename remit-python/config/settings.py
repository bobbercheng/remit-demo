from typing import Dict, Any, Optional
from pydantic import Field
from pydantic_settings import BaseSettings
from functools import lru_cache
import os
import json
from pathlib import Path


class Settings(BaseSettings):
    """
    Application settings. 
    Values are loaded from environment variables and/or .env file.
    Sensitive values should never be hardcoded.
    """
    # API configuration
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "Remittance Service"
    
    # Environment settings
    ENV: str = Field(default="dev")
    DEBUG: bool = Field(default=False)
    
    # DynamoDB settings
    DYNAMODB_HOST: str = Field(default="localhost")
    DYNAMODB_PORT: int = Field(default=8000)
    DYNAMODB_REGION: str = Field(default="us-east-1")
    DYNAMODB_ACCESS_KEY: str = Field(default="dummy")
    DYNAMODB_SECRET_KEY: str = Field(default="dummy")
    
    # UPI Payment Service settings
    UPI_API_URL: str = Field(default="https://upi-mock.example.com/api")
    UPI_API_KEY: str = Field(default="dummy-api-key")
    UPI_MERCHANT_ID: str = Field(default="MERCHANT001")
    
    # AD Bank settings for forex conversion
    ADBANK_API_URL: str = Field(default="https://adbank-mock.example.com/api")
    ADBANK_API_KEY: str = Field(default="dummy-api-key")
    ADBANK_CLIENT_ID: str = Field(default="CLIENT001")
    
    # Wise API settings for international transfers
    WISE_API_URL: str = Field(default="https://api.wise.com")
    WISE_API_KEY: str = Field(default="dummy-api-key")
    WISE_PROFILE_ID: str = Field(default="profile-id")
    
    # Transaction limits and settings
    MIN_TRANSACTION_AMOUNT_INR: float = Field(default=1000.0)
    MAX_TRANSACTION_AMOUNT_INR: float = Field(default=100000.0)
    DEFAULT_SERVICE_FEE_PERCENT: float = Field(default=0.5)
    
    # Timeouts and retry settings
    DEFAULT_TIMEOUT_SECONDS: int = Field(default=30)
    MAX_RETRIES: int = Field(default=3)
    RETRY_BACKOFF_FACTOR: float = Field(default=1.5)

    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings(env: Optional[str] = None) -> Settings:
    """
    Returns the settings instance, optionally loading additional
    configuration from a JSON file based on the environment.
    
    This function is cached to avoid repeatedly loading config files.
    """
    settings = Settings()
    
    # If env is not provided, use the setting from env variable
    env = env or settings.ENV
    
    # Load environment-specific config if it exists
    config_file = Path(f"config/{env}.json")
    if config_file.exists():
        with open(config_file) as f:
            config_data = json.load(f)
            for key, value in config_data.items():
                if hasattr(settings, key):
                    setattr(settings, key, value)
    
    return settings 