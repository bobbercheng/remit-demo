package com.remitservice.integration.wise.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Response model for Wise quote information.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WiseQuoteResponse {
    
    /**
     * Quote ID from Wise
     */
    @JsonProperty("id")
    private String id;
    
    /**
     * Source currency code
     */
    @JsonProperty("sourceCurrency")
    private String sourceCurrency;
    
    /**
     * Target currency code
     */
    @JsonProperty("targetCurrency")
    private String targetCurrency;
    
    /**
     * Source amount
     */
    @JsonProperty("sourceAmount")
    private Double sourceAmount;
    
    /**
     * Target amount after conversion
     */
    @JsonProperty("targetAmount")
    private Double targetAmount;
    
    /**
     * The applied exchange rate
     */
    @JsonProperty("rate")
    private Double rate;
    
    /**
     * Timestamp when quote expires
     */
    @JsonProperty("expirationTime")
    private LocalDateTime expirationTime;
    
    /**
     * Wise fee for the transfer
     */
    @JsonProperty("fee")
    private Double fee;
    
    /**
     * Estimated delivery time
     */
    @JsonProperty("estimatedDelivery")
    private LocalDateTime estimatedDelivery;
} 