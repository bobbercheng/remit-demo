package com.fintech.remit.integration.upi;

import reactor.core.publisher.Mono;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Service interface for integrating with UPI payment provider.
 */
public interface UpiService {
    
    /**
     * Initiate a UPI payment for a remittance
     * 
     * @param remittanceId the remittance ID
     * @param amount the amount to collect in INR
     * @param userId the user ID
     * @return a Mono containing the payment link or QR code
     */
    Mono<UpiPaymentResponse> initiatePayment(UUID remittanceId, BigDecimal amount, String userId);
    
    /**
     * Check the status of a UPI payment
     * 
     * @param remittanceId the remittance ID
     * @return a Mono containing the payment status
     */
    Mono<UpiPaymentStatusResponse> checkPaymentStatus(UUID remittanceId);
} 