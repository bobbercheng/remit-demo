import boto3
from botocore.exceptions import ClientError
from typing import Dict, List, Optional, Any, TypeVar, Generic, Type
from datetime import datetime
from decimal import Decimal
import os
import json
import logging
from functools import lru_cache

from config.settings import get_settings

# Set up logging
logger = logging.getLogger(__name__)

# Type variable for the repository pattern
T = TypeVar('T')


class DecimalEncoder(json.JSONEncoder):
    """Custom JSON encoder for Decimal types"""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)


@lru_cache()
def get_dynamodb_client():
    """
    Create and return a boto3 DynamoDB client
    
    Uses configuration from settings, with different behavior
    for local development vs production environments.
    """
    settings = get_settings()
    
    # Configure boto3 session
    if settings.ENV == "dev" or settings.ENV == "test":
        # Use local DynamoDB for development and testing
        return boto3.resource(
            'dynamodb',
            endpoint_url=f"http://{settings.DYNAMODB_HOST}:{settings.DYNAMODB_PORT}",
            region_name=settings.DYNAMODB_REGION,
            aws_access_key_id=settings.DYNAMODB_ACCESS_KEY,
            aws_secret_access_key=settings.DYNAMODB_SECRET_KEY
        )
    else:
        # Use AWS DynamoDB in production with IAM role or environment credentials
        return boto3.resource('dynamodb', region_name=settings.DYNAMODB_REGION)


class DynamoDBRepository(Generic[T]):
    """
    Generic repository for DynamoDB operations
    
    This class provides a common interface for database operations
    with DynamoDB for any model type.
    """
    def __init__(self, table_name: str, model_class: Type[T]):
        """
        Initialize repository with table name and model class
        
        Args:
            table_name: Name of the DynamoDB table
            model_class: Class to instantiate from DynamoDB items
        """
        self.table_name = table_name
        self.model_class = model_class
        self.dynamodb = get_dynamodb_client()
        self.table = self.dynamodb.Table(table_name)
    
    def create(self, item: T) -> T:
        """
        Create a new item in DynamoDB
        
        Args:
            item: The model instance to save
            
        Returns:
            The saved model instance
        """
        try:
            dynamodb_item = getattr(item, "to_dynamodb_item")()
            self.table.put_item(Item=dynamodb_item)
            return item
        except ClientError as e:
            logger.error(f"Error creating item in {self.table_name}: {e}")
            raise
    
    def get(self, key: Dict[str, Any]) -> Optional[T]:
        """
        Get an item by its key
        
        Args:
            key: Dictionary containing the partition key and optional sort key
            
        Returns:
            Model instance if found, None otherwise
        """
        try:
            response = self.table.get_item(Key=key)
            if "Item" in response:
                return self.model_class.from_dynamodb_item(response["Item"])
            return None
        except ClientError as e:
            logger.error(f"Error getting item from {self.table_name}: {e}")
            raise
    
    def update(self, key: Dict[str, Any], update_expression: str, 
               expression_values: Dict[str, Any]) -> Optional[T]:
        """
        Update an item with an update expression
        
        Args:
            key: Dictionary containing the partition key and optional sort key
            update_expression: DynamoDB update expression
            expression_values: Values for the update expression
            
        Returns:
            Updated model instance if found, None otherwise
        """
        try:
            response = self.table.update_item(
                Key=key,
                UpdateExpression=update_expression,
                ExpressionAttributeValues=expression_values,
                ReturnValues="ALL_NEW"
            )
            if "Attributes" in response:
                return self.model_class.from_dynamodb_item(response["Attributes"])
            return None
        except ClientError as e:
            logger.error(f"Error updating item in {self.table_name}: {e}")
            raise
    
    def delete(self, key: Dict[str, Any]) -> bool:
        """
        Delete an item by its key
        
        Args:
            key: Dictionary containing the partition key and optional sort key
            
        Returns:
            True if deleted successfully, False otherwise
        """
        try:
            self.table.delete_item(Key=key)
            return True
        except ClientError as e:
            logger.error(f"Error deleting item from {self.table_name}: {e}")
            raise
    
    def query(self, key_condition_expression: str, 
              expression_values: Dict[str, Any]) -> List[T]:
        """
        Query items with a key condition expression
        
        Args:
            key_condition_expression: DynamoDB key condition expression
            expression_values: Values for the key condition expression
            
        Returns:
            List of model instances that match the query
        """
        try:
            response = self.table.query(
                KeyConditionExpression=key_condition_expression,
                ExpressionAttributeValues=expression_values
            )
            return [self.model_class.from_dynamodb_item(item) 
                   for item in response.get("Items", [])]
        except ClientError as e:
            logger.error(f"Error querying items from {self.table_name}: {e}")
            raise 