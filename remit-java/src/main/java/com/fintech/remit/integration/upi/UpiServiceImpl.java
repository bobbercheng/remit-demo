package com.fintech.remit.integration.upi;

import com.fintech.remit.config.UpiProperties;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Implementation of the UPI service for integrating with UPI payment provider.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class UpiServiceImpl implements UpiService {
    
    private final WebClient upiWebClient;
    private final UpiProperties upiProperties;
    
    /**
     * {@inheritDoc}
     */
    @Override
    @CircuitBreaker(name = "upiService")
    @Retry(name = "upiService")
    public Mono<UpiPaymentResponse> initiatePayment(UUID remittanceId, BigDecimal amount, String userId) {
        log.info("Initiating UPI payment for remittance: {}, amount: {}, user: {}", remittanceId, amount, userId);
        
        return upiWebClient.post()
                .uri("/api/v1/payments")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(createPaymentRequest(remittanceId, amount, userId))
                .retrieve()
                .bodyToMono(UpiPaymentResponse.class)
                .doOnSuccess(response -> log.info("UPI payment initiated successfully for remittance: {}, reference: {}", 
                        remittanceId, response.getPaymentReference()))
                .doOnError(error -> log.error("Error initiating UPI payment for remittance: {}", remittanceId, error));
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    @CircuitBreaker(name = "upiService")
    @Retry(name = "upiService")
    public Mono<UpiPaymentStatusResponse> checkPaymentStatus(UUID remittanceId) {
        log.info("Checking UPI payment status for remittance: {}", remittanceId);
        
        return upiWebClient.get()
                .uri(uriBuilder -> uriBuilder
                        .path("/api/v1/payments/status")
                        .queryParam("remittanceId", remittanceId.toString())
                        .build())
                .retrieve()
                .bodyToMono(UpiPaymentStatusResponse.class)
                .doOnSuccess(response -> log.info("UPI payment status for remittance: {}, status: {}", 
                        remittanceId, response.getStatus()))
                .doOnError(error -> log.error("Error checking UPI payment status for remittance: {}", remittanceId, error));
    }
    
    /**
     * Create a payment request object for the UPI API
     * 
     * @param remittanceId the remittance ID
     * @param amount the amount to collect
     * @param userId the user ID
     * @return the payment request object
     */
    private UpiPaymentRequest createPaymentRequest(UUID remittanceId, BigDecimal amount, String userId) {
        return UpiPaymentRequest.builder()
                .remittanceId(remittanceId.toString())
                .amount(amount)
                .userId(userId)
                .callbackUrl(upiProperties.getCallbackUrl())
                .build();
    }
    
    /**
     * Request model for UPI payment initiation.
     */
    @lombok.Data
    @lombok.Builder
    private static class UpiPaymentRequest {
        private String remittanceId;
        private BigDecimal amount;
        private String userId;
        private String callbackUrl;
    }
} 