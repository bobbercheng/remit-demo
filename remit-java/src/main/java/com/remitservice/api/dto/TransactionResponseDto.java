package com.remitservice.api.dto;

import com.remitservice.domain.model.TransactionStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO for transaction responses in API.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TransactionResponseDto {
    
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
    private Double sourceAmount;
    
    /**
     * Amount in destination currency (CAD)
     */
    private Double destinationAmount;
    
    /**
     * Exchange rate used for conversion
     */
    private Double exchangeRate;
    
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
    private RecipientDetailsDto recipientDetails;
    
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
    private Double fee;
    
    /**
     * Reason for failure if transaction failed
     */
    private String failureReason;
} 