package com.remitservice.domain.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Domain model representing a remittance transaction.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Transaction {
    
    /**
     * Unique identifier for the transaction
     */
    private String transactionId;
    
    /**
     * User ID who initiated the transaction
     */
    private String userId;
    
    /**
     * Amount in source currency (INR)
     */
    private double sourceAmount;
    
    /**
     * Amount in destination currency (CAD)
     */
    private double destinationAmount;
    
    /**
     * Exchange rate used for conversion
     */
    private double exchangeRate;
    
    /**
     * Source currency code
     */
    private String sourceCurrency;
    
    /**
     * Destination currency code
     */
    private String destinationCurrency;
    
    /**
     * Current status of the transaction
     */
    private TransactionStatus status;
    
    /**
     * Recipient details
     */
    private RecipientDetails recipientDetails;
    
    /**
     * Transaction creation timestamp
     */
    private LocalDateTime createdAt;
    
    /**
     * Last update timestamp
     */
    private LocalDateTime updatedAt;
    
    /**
     * Estimated completion time
     */
    private LocalDateTime estimatedCompletionTime;
    
    /**
     * Total fee charged for the transaction
     */
    private double fee;
    
    /**
     * Reason for failure if transaction failed
     */
    private String failureReason;
} 