package com.remitservice.domain.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Domain model representing a disbursement to the recipient in Canada.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Disbursement {
    
    /**
     * Unique identifier for the disbursement
     */
    private String disbursementId;
    
    /**
     * ID of the transaction this disbursement is for
     */
    private String transactionId;
    
    /**
     * Disbursement provider (Wise)
     */
    private String provider;
    
    /**
     * Transaction ID from provider (Wise)
     */
    private String providerTransactionId;
    
    /**
     * Status of the disbursement (PENDING, PROCESSING, COMPLETED, FAILED)
     */
    private String status;
    
    /**
     * Disbursement amount
     */
    private double amount;
    
    /**
     * Disbursement currency (CAD)
     */
    private String currency;
    
    /**
     * Estimated arrival time at recipient's bank
     */
    private LocalDateTime estimatedArrivalTime;
    
    /**
     * Disbursement creation timestamp
     */
    private LocalDateTime createdAt;
    
    /**
     * Disbursement completion timestamp
     */
    private LocalDateTime completedAt;
    
    /**
     * Reason for failure if disbursement failed
     */
    private String failureReason;
} 