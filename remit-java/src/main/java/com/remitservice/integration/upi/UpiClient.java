package com.remitservice.integration.upi;

import com.remitservice.integration.upi.model.UpiPaymentRequest;
import com.remitservice.integration.upi.model.UpiPaymentResponse;
import reactor.core.publisher.Mono;

/**
 * Client interface for UPI payment integration.
 */
public interface UpiClient {
    
    /**
     * Creates a UPI payment request.
     *
     * @param request UPI payment request details
     * @return UPI payment response with payment instructions
     */
    Mono<UpiPaymentResponse> createPaymentRequest(UpiPaymentRequest request);
    
    /**
     * Checks the status of a UPI payment.
     *
     * @param paymentId UPI payment ID
     * @return UPI payment response with status
     */
    Mono<UpiPaymentResponse> checkPaymentStatus(String paymentId);
} 