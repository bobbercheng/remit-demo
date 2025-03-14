package com.remitservice.integration.upi.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Request model for creating a UPI payment request.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpiPaymentRequest {
    
    /**
     * Amount to be paid in INR
     */
    @JsonProperty("amount")
    private Double amount;
    
    /**
     * Currency code (always INR for UPI)
     */
    @JsonProperty("currency")
    private String currency;
    
    /**
     * Merchant reference ID (our transactionId or paymentId)
     */
    @JsonProperty("reference")
    private String reference;
    
    /**
     * Description of the payment
     */
    @JsonProperty("description")
    private String description;
    
    /**
     * UPI VPA (Virtual Payment Address) of the merchant
     */
    @JsonProperty("vpa")
    private String vpa;
    
    /**
     * Callback URL for payment notifications
     */
    @JsonProperty("callbackUrl")
    private String callbackUrl;
    
    /**
     * Expiry time in minutes
     */
    @JsonProperty("expiryMinutes")
    private Integer expiryMinutes;
} 