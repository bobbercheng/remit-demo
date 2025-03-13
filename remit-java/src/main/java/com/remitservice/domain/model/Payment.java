package com.remitservice.domain.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Domain model representing a payment associated with a remittance transaction.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Payment {
    
    /**
     * Unique identifier for the payment
     */
    private String paymentId;
    
    /**
     * ID of the transaction this payment is for
     */
    private String transactionId;
    
    /**
     * Payment method used (UPI)
     */
    private String paymentMethod;
    
    /**
     * Status of the payment (PENDING, COMPLETED, FAILED)
     */
    private String paymentStatus;
    
    /**
     * Payment amount
     */
    private double amount;
    
    /**
     * Payment currency
     */
    private String currency;
    
    /**
     * External reference from payment provider
     */
    private String paymentReference;
    
    /**
     * UPI ID used for payment
     */
    private String upiId;
    
    /**
     * QR code for payment (base64 encoded)
     */
    private String qrCode;
    
    /**
     * Payment creation timestamp
     */
    private LocalDateTime createdAt;
    
    /**
     * Payment completion timestamp
     */
    private LocalDateTime completedAt;
    
    /**
     * Payment expiration timestamp
     */
    private LocalDateTime expiresAt;
} 