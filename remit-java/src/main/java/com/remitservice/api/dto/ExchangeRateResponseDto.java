package com.remitservice.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO for exchange rate responses in API.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ExchangeRateResponseDto {
    
    /**
     * Source currency code
     */
    private String sourceCurrency;
    
    /**
     * Destination currency code
     */
    private String destinationCurrency;
    
    /**
     * Exchange rate value
     */
    private Double rate;
    
    /**
     * Timestamp when rate was fetched
     */
    private LocalDateTime timestamp;
    
    /**
     * Source of exchange rate (bank name)
     */
    private String provider;
    
    /**
     * Rate validity period
     */
    private LocalDateTime validUntil;
} 