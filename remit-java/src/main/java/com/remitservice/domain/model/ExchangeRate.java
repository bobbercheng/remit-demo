package com.remitservice.domain.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Domain model representing an exchange rate for a currency pair.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ExchangeRate {
    
    /**
     * Currency pair identifier (e.g., "INR-CAD")
     */
    private String pairId;
    
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
    private double rate;
    
    /**
     * Timestamp when rate was fetched
     */
    private LocalDateTime timestamp;
    
    /**
     * Source of exchange rate (AD Bank name)
     */
    private String provider;
    
    /**
     * Rate validity period
     */
    private LocalDateTime validUntil;
} 