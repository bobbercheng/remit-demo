package com.remitservice.api.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO for creating a new remittance transaction.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TransactionRequestDto {
    
    /**
     * Amount in source currency (INR)
     */
    @NotNull(message = "Source amount is required")
    @Positive(message = "Source amount must be positive")
    private Double sourceAmount;
    
    /**
     * Source currency code
     */
    @NotBlank(message = "Source currency is required")
    private String sourceCurrency;
    
    /**
     * Destination currency code
     */
    @NotBlank(message = "Destination currency is required")
    private String destinationCurrency;
    
    /**
     * Recipient details
     */
    @NotNull(message = "Recipient details are required")
    @Valid
    private RecipientDetailsDto recipientDetails;
} 