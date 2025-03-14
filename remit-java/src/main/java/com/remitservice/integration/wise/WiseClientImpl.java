package com.remitservice.integration.wise;

import com.remitservice.config.properties.IntegrationProperties;
import com.remitservice.integration.wise.model.WiseQuoteRequest;
import com.remitservice.integration.wise.model.WiseQuoteResponse;
import com.remitservice.integration.wise.model.WiseTransferRequest;
import com.remitservice.integration.wise.model.WiseTransferResponse;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

/**
 * Implementation of Wise client using WebClient for HTTP requests.
 */
@Slf4j
@Component
public class WiseClientImpl implements WiseClient {
    
    private final WebClient webClient;
    private final IntegrationProperties.WiseProperties wiseProperties;
    
    /**
     * Constructor with WebClient and Wise properties.
     *
     * @param webClientBuilder WebClient.Builder for creating WebClient
     * @param integrationProperties Integration properties
     */
    public WiseClientImpl(WebClient.Builder webClientBuilder, IntegrationProperties integrationProperties) {
        this.wiseProperties = integrationProperties.getWise();
        this.webClient = webClientBuilder
                .baseUrl(wiseProperties.getBaseUrl())
                .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .defaultHeader(HttpHeaders.ACCEPT, MediaType.APPLICATION_JSON_VALUE)
                .defaultHeader("Authorization", "Bearer " + wiseProperties.getApiKey())
                .build();
    }
    
    /**
     * Creates a quote to get exchange rate information.
     *
     * @param quoteRequest Quote request details
     * @return Quote response with exchange rate information
     */
    @Override
    @CircuitBreaker(name = "wiseClient")
    @Retry(name = "wiseClient")
    public Mono<WiseQuoteResponse> createQuote(WiseQuoteRequest quoteRequest) {
        log.info("Creating Wise quote request: {}", quoteRequest);
        
        // Set profile ID from properties if not already set
        if (quoteRequest.getProfileId() == null) {
            quoteRequest.setProfileId(wiseProperties.getProfileId());
        }
        
        return webClient.post()
                .uri("/v3/profiles/{profileId}/quotes", wiseProperties.getProfileId())
                .bodyValue(quoteRequest)
                .retrieve()
                .bodyToMono(WiseQuoteResponse.class)
                .doOnSuccess(response -> log.info("Wise quote created successfully: {}", response))
                .doOnError(error -> log.error("Error creating Wise quote: {}", error.getMessage()));
    }
    
    /**
     * Creates a transfer for cross-border disbursement.
     *
     * @param transferRequest Transfer request details
     * @return Transfer response with transfer details
     */
    @Override
    @CircuitBreaker(name = "wiseClient")
    @Retry(name = "wiseClient")
    public Mono<WiseTransferResponse> createTransfer(WiseTransferRequest transferRequest) {
        log.info("Creating Wise transfer: {}", transferRequest);
        
        // Set callback URL from properties if not already set
        if (transferRequest.getCallbackUrl() == null) {
            transferRequest.setCallbackUrl(wiseProperties.getCallbackUrl());
        }
        
        return webClient.post()
                .uri("/v1/transfers")
                .bodyValue(transferRequest)
                .retrieve()
                .bodyToMono(WiseTransferResponse.class)
                .doOnSuccess(response -> log.info("Wise transfer created successfully: {}", response))
                .doOnError(error -> log.error("Error creating Wise transfer: {}", error.getMessage()));
    }
    
    /**
     * Gets transfer details by ID.
     *
     * @param transferId Transfer ID
     * @return Transfer response with transfer details
     */
    @Override
    @CircuitBreaker(name = "wiseClient")
    @Retry(name = "wiseClient")
    public Mono<WiseTransferResponse> getTransfer(String transferId) {
        log.info("Getting Wise transfer details for transferId: {}", transferId);
        
        return webClient.get()
                .uri("/v1/transfers/{transferId}", transferId)
                .retrieve()
                .bodyToMono(WiseTransferResponse.class)
                .doOnSuccess(response -> log.info("Wise transfer status: {}", response.getStatus()))
                .doOnError(error -> log.error("Error getting Wise transfer details: {}", error.getMessage()));
    }
} 