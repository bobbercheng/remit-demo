package com.remitservice.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO for payment instructions in API responses.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PaymentInstructionsResponseDto {
    
    /**
     * ID of the transaction
     */
    private String transactionId;
    
    /**
     * ID of the payment
     */
    private String paymentId;
    
    /**
     * UPI ID to receive payment
     */
    private String upiId;
    
    /**
     * Payment amount
     */
    private Double amount;
    
    /**
     * Payment currency
     */
    private String currency;
    
    /**
     * Reference number to include with payment
     */
    private String referenceNumber;
    
    /**
     * Deep link to UPI app to process payment
     */
    private String deepLink;
    
    /**
     * QR code for payment (base64 encoded)
     */
    private String qrCode;
    
    /**
     * Expiration time for payment instructions
     */
    private LocalDateTime expiresAt;
} 