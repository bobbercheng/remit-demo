package com.remitservice.config.properties;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * Configuration properties for external integrations.
 */
@Data
@Configuration
@ConfigurationProperties(prefix = "integration")
public class IntegrationProperties {

    private UpiProperties upi;
    private AdBankProperties adbank;
    private WiseProperties wise;

    /**
     * UPI integration properties.
     */
    @Data
    public static class UpiProperties {
        private String baseUrl;
        private String apiKey;
        private String callbackUrl;
        private int timeoutSeconds;
    }

    /**
     * AD Bank integration properties.
     */
    @Data
    public static class AdBankProperties {
        private String baseUrl;
        private String apiKey;
        private int timeoutSeconds;
    }

    /**
     * Wise integration properties.
     */
    @Data
    public static class WiseProperties {
        private String baseUrl;
        private String apiKey;
        private String profileId;
        private String callbackUrl;
        private int timeoutSeconds;
    }
} 