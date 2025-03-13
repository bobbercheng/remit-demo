package com.fintech.remit.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.time.Duration;

/**
 * Configuration properties for AD Bank integration.
 * These properties are loaded from application.yml or environment variables.
 */
@Data
@Configuration
@ConfigurationProperties(prefix = "remit.integration.adbank")
public class AdbankProperties {
    
    /**
     * The base URL for the AD Bank API
     */
    private String baseUrl;
    
    /**
     * The client ID for authenticating with AD Bank
     */
    private String clientId;
    
    /**
     * The client secret for authenticating with AD Bank
     */
    private String clientSecret;
    
    /**
     * Timeout for AD Bank API calls
     */
    private Duration timeout = Duration.ofSeconds(45);
} 