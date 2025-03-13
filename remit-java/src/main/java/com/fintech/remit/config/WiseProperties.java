package com.fintech.remit.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.time.Duration;

/**
 * Configuration properties for Wise integration.
 * These properties are loaded from application.yml or environment variables.
 */
@Data
@Configuration
@ConfigurationProperties(prefix = "remit.integration.wise")
public class WiseProperties {
    
    /**
     * The base URL for the Wise API
     */
    private String baseUrl;
    
    /**
     * The API key for authenticating with Wise
     */
    private String apiKey;
    
    /**
     * The profile ID for the Wise account
     */
    private String profileId;
    
    /**
     * The webhook URL where Wise will notify transfer status
     */
    private String webhookUrl;
    
    /**
     * Timeout for Wise API calls
     */
    private Duration timeout = Duration.ofSeconds(60);
} 