package com.remitservice.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.enhanced.dynamodb.DynamoDbEnhancedAsyncClient;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.dynamodb.DynamoDbAsyncClient;

import java.net.URI;

/**
 * Configuration for AWS DynamoDB.
 * This class provides the necessary beans for interacting with DynamoDB.
 */
@Configuration
public class DynamoDbConfig {

    @Value("${aws.dynamodb.endpoint}")
    private String dynamoDbEndpoint;

    @Value("${aws.dynamodb.region}")
    private String region;

    @Value("${aws.dynamodb.accessKey}")
    private String accessKey;

    @Value("${aws.dynamodb.secretKey}")
    private String secretKey;

    /**
     * Creates a DynamoDB async client.
     *
     * @return DynamoDbAsyncClient
     */
    @Bean
    public DynamoDbAsyncClient dynamoDbAsyncClient() {
        return DynamoDbAsyncClient.builder()
                .endpointOverride(URI.create(dynamoDbEndpoint))
                .region(Region.of(region))
                .credentialsProvider(
                        StaticCredentialsProvider.create(
                                AwsBasicCredentials.create(accessKey, secretKey)
                        )
                )
                .build();
    }

    /**
     * Creates an enhanced DynamoDB async client.
     *
     * @return DynamoDbEnhancedAsyncClient
     */
    @Bean
    public DynamoDbEnhancedAsyncClient dynamoDbEnhancedAsyncClient(DynamoDbAsyncClient dynamoDbAsyncClient) {
        return DynamoDbEnhancedAsyncClient.builder()
                .dynamoDbClient(dynamoDbAsyncClient)
                .build();
    }
} 