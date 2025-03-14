package com.remitservice.integration.wise;

import com.remitservice.integration.wise.model.WiseQuoteRequest;
import com.remitservice.integration.wise.model.WiseQuoteResponse;
import com.remitservice.integration.wise.model.WiseTransferRequest;
import com.remitservice.integration.wise.model.WiseTransferResponse;
import reactor.core.publisher.Mono;

/**
 * Client interface for Wise integration.
 */
public interface WiseClient {
    
    /**
     * Creates a quote to get exchange rate information.
     *
     * @param quoteRequest Quote request details
     * @return Quote response with exchange rate information
     */
    Mono<WiseQuoteResponse> createQuote(WiseQuoteRequest quoteRequest);
    
    /**
     * Creates a transfer for cross-border disbursement.
     *
     * @param transferRequest Transfer request details
     * @return Transfer response with transfer details
     */
    Mono<WiseTransferResponse> createTransfer(WiseTransferRequest transferRequest);
    
    /**
     * Gets transfer details by ID.
     *
     * @param transferId Transfer ID
     * @return Transfer response with transfer details
     */
    Mono<WiseTransferResponse> getTransfer(String transferId);
} 