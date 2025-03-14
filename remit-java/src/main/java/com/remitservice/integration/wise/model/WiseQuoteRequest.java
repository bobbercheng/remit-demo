package com.remitservice.integration.wise.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Request model for creating a Wise quote (exchange rate).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WiseQuoteRequest {
    
    /**
     * Source currency code (e.g., INR)
     */
    @JsonProperty("sourceCurrency")
    private String sourceCurrency;
    
    /**
     * Target currency code (e.g., CAD)
     */
    @JsonProperty("targetCurrency")
    private String targetCurrency;
    
    /**
     * Source amount to convert
     */
    @JsonProperty("sourceAmount")
    private Double sourceAmount;
    
    /**
     * Wise profile ID
     */
    @JsonProperty("profile")
    private String profileId;
} 