package com.remitservice.integration.upi;

import com.remitservice.config.properties.IntegrationProperties;
import com.remitservice.integration.upi.model.UpiPaymentRequest;
import com.remitservice.integration.upi.model.UpiPaymentResponse;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

/**
 * Implementation of UPI client using WebClient for HTTP requests.
 */
@Slf4j
@Component
public class UpiClientImpl implements UpiClient {
    
    private final WebClient webClient;
    private final IntegrationProperties.UpiProperties upiProperties;
    
    /**
     * Constructor with WebClient and UPI properties.
     *
     * @param webClientBuilder WebClient.Builder for creating WebClient
     * @param integrationProperties Integration properties
     */
    public UpiClientImpl(WebClient.Builder webClientBuilder, IntegrationProperties integrationProperties) {
        this.upiProperties = integrationProperties.getUpi();
        this.webClient = webClientBuilder
                .baseUrl(upiProperties.getBaseUrl())
                .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .defaultHeader(HttpHeaders.ACCEPT, MediaType.APPLICATION_JSON_VALUE)
                .defaultHeader("X-API-KEY", upiProperties.getApiKey())
                .build();
    }
    
    /**
     * Creates a UPI payment request with circuit breaker and retry patterns.
     *
     * @param request UPI payment request details
     * @return UPI payment response with payment instructions
     */
    @Override
    @CircuitBreaker(name = "upiClient")
    @Retry(name = "upiClient")
    public Mono<UpiPaymentResponse> createPaymentRequest(UpiPaymentRequest request) {
        log.info("Creating UPI payment request: {}", request);
        
        // Set the callback URL from properties if not already set
        if (request.getCallbackUrl() == null) {
            request.setCallbackUrl(upiProperties.getCallbackUrl());
        }
        
        return webClient.post()
                .uri("/v1/payment-requests")
                .bodyValue(request)
                .retrieve()
                .bodyToMono(UpiPaymentResponse.class)
                .doOnSuccess(response -> log.info("UPI payment request created successfully: {}", response))
                .doOnError(error -> log.error("Error creating UPI payment request: {}", error.getMessage()));
    }
    
    /**
     * Checks the status of a UPI payment with circuit breaker and retry patterns.
     *
     * @param paymentId UPI payment ID
     * @return UPI payment response with status
     */
    @Override
    @CircuitBreaker(name = "upiClient")
    @Retry(name = "upiClient")
    public Mono<UpiPaymentResponse> checkPaymentStatus(String paymentId) {
        log.info("Checking UPI payment status for paymentId: {}", paymentId);
        
        return webClient.get()
                .uri("/v1/payment-requests/{paymentId}", paymentId)
                .retrieve()
                .bodyToMono(UpiPaymentResponse.class)
                .doOnSuccess(response -> log.info("UPI payment status: {}", response.getStatus()))
                .doOnError(error -> log.error("Error checking UPI payment status: {}", error.getMessage()));
    }
} 