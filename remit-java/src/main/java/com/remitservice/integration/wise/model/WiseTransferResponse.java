package com.remitservice.integration.wise.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Response model for Wise transfer details.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WiseTransferResponse {
    
    /**
     * Transfer ID from Wise
     */
    @JsonProperty("id")
    private String id;
    
    /**
     * Customer transaction ID
     */
    @JsonProperty("customerTransactionId")
    private String customerTransactionId;
    
    /**
     * Quote ID used for the transfer
     */
    @JsonProperty("quoteId")
    private String quoteId;
    
    /**
     * Status of the transfer
     */
    @JsonProperty("status")
    private String status;
    
    /**
     * Source currency
     */
    @JsonProperty("sourceCurrency")
    private String sourceCurrency;
    
    /**
     * Source amount
     */
    @JsonProperty("sourceAmount")
    private Double sourceAmount;
    
    /**
     * Target currency
     */
    @JsonProperty("targetCurrency")
    private String targetCurrency;
    
    /**
     * Target amount
     */
    @JsonProperty("targetAmount")
    private Double targetAmount;
    
    /**
     * Customer reference text
     */
    @JsonProperty("reference")
    private String reference;
    
    /**
     * Transfer creation timestamp
     */
    @JsonProperty("created")
    private LocalDateTime created;
    
    /**
     * Estimated completion time
     */
    @JsonProperty("estimatedDelivery")
    private LocalDateTime estimatedDelivery;
    
    /**
     * Reason if the transfer failed
     */
    @JsonProperty("failureReason")
    private String failureReason;
} 