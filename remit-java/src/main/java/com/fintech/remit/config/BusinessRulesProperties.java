package com.fintech.remit.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.math.BigDecimal;
import java.util.List;

/**
 * Configuration properties for business rules.
 * These properties are loaded from application.yml or environment variables.
 */
@Data
@Configuration
@ConfigurationProperties(prefix = "remit.business")
public class BusinessRulesProperties {
    
    /**
     * Minimum amount allowed for remittance in INR
     */
    private BigDecimal minAmountInr = new BigDecimal("1000");
    
    /**
     * Maximum amount allowed for remittance in INR
     */
    private BigDecimal maxAmountInr = new BigDecimal("1000000");
    
    /**
     * List of supported source countries
     */
    private List<String> supportedSourceCountries;
    
    /**
     * List of supported destination countries
     */
    private List<String> supportedDestinationCountries;
    
    /**
     * Retry configuration for external services
     */
    private RetryConfig retry = new RetryConfig();
    
    /**
     * Retry configuration properties
     */
    @Data
    public static class RetryConfig {
        /**
         * Maximum number of retry attempts
         */
        private int maxAttempts = 3;
        
        /**
         * Initial interval between retries in milliseconds
         */
        private long initialInterval = 1000;
        
        /**
         * Multiplier for exponential backoff
         */
        private double multiplier = 2.0;
    }
} 