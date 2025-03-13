package com.fintech.remit.integration.upi;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Response model for UPI payment initiation.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpiPaymentResponse {
    
    /**
     * The UPI payment reference ID
     */
    private String paymentReference;
    
    /**
     * The remittance ID this payment is for
     */
    private UUID remittanceId;
    
    /**
     * The amount to be collected
     */
    private BigDecimal amount;
    
    /**
     * The UPI payment link that can be opened in UPI apps
     */
    private String paymentLink;
    
    /**
     * Base64 encoded QR code for UPI payment
     */
    private String qrCode;
    
    /**
     * Status of the payment initiation (SUCCESS/FAILED)
     */
    private String status;
    
    /**
     * Optional error code if initiation failed
     */
    private String errorCode;
    
    /**
     * Optional error message if initiation failed
     */
    private String errorMessage;
} 