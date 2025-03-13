package com.fintech.remit.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.time.Duration;

/**
 * Configuration properties for UPI integration.
 * These properties are loaded from application.yml or environment variables.
 */
@Data
@Configuration
@ConfigurationProperties(prefix = "remit.integration.upi")
public class UpiProperties {
    
    /**
     * The base URL for the UPI API
     */
    private String baseUrl;
    
    /**
     * The API key for authenticating with the UPI provider
     */
    private String apiKey;
    
    /**
     * The callback URL where UPI provider will notify payment status
     */
    private String callbackUrl;
    
    /**
     * Timeout for UPI API calls
     */
    private Duration timeout = Duration.ofSeconds(30);
} 