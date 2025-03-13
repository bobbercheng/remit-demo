package com.fintech.remit.integration.upi;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Response model for UPI payment status check.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpiPaymentStatusResponse {
    
    /**
     * The UPI payment reference ID
     */
    private String paymentReference;
    
    /**
     * The remittance ID this payment is for
     */
    private UUID remittanceId;
    
    /**
     * The amount collected
     */
    private BigDecimal amount;
    
    /**
     * Status of the payment (PENDING/COMPLETED/FAILED)
     */
    private String status;
    
    /**
     * Timestamp when the payment was completed or failed
     */
    private Instant timestamp;
    
    /**
     * Optional error code if payment failed
     */
    private String errorCode;
    
    /**
     * Optional error message if payment failed
     */
    private String errorMessage;
} 