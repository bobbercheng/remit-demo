package com.remitservice.config.properties;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.util.List;

/**
 * Configuration properties for remittance business rules.
 */
@Data
@Configuration
@ConfigurationProperties(prefix = "remittance")
public class RemittanceProperties {

    private double minimumAmount;
    private double maximumAmount;
    private List<String> supportedSourceCurrencies;
    private List<String> supportedDestinationCurrencies;
    private int exchangeRateValidity;
    private int processingTimeHours;
    private FeeProperties fee;
    private CallbackProperties callback;

    /**
     * Fee structure properties.
     */
    @Data
    public static class FeeProperties {
        private double percentage;
        private double flat;
    }

    /**
     * Callback configuration properties.
     */
    @Data
    public static class CallbackProperties {
        private int retryDelaySeconds;
        private int maxRetries;
    }
} 