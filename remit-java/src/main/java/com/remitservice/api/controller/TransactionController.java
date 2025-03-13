package com.remitservice.api.controller;

import com.remitservice.api.dto.TransactionRequestDto;
import com.remitservice.api.dto.TransactionResponseDto;
import com.remitservice.service.transaction.TransactionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * REST controller for transaction operations.
 */
@RestController
@RequestMapping("/api/v1/transactions")
@RequiredArgsConstructor
@Tag(name = "Transactions", description = "API for remittance transaction operations")
public class TransactionController {

    private final TransactionService transactionService;

    /**
     * Initiates a new remittance transaction.
     *
     * @param transactionRequest The transaction request
     * @return Created transaction details
     */
    @PostMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Initiate a new remittance transaction")
    public Mono<TransactionResponseDto> initiateTransaction(
            @Valid @RequestBody TransactionRequestDto transactionRequest) {
        return transactionService.initiateTransaction(transactionRequest);
    }

    /**
     * Gets all transactions for a user.
     *
     * @param status Optional status filter
     * @return List of transactions
     */
    @GetMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    @Operation(summary = "Get all transactions for the authenticated user")
    public Flux<TransactionResponseDto> getTransactions(
            @RequestParam(required = false) String status) {
        return transactionService.getTransactions(status);
    }

    /**
     * Gets details of a specific transaction.
     *
     * @param transactionId Transaction ID
     * @return Transaction details
     */
    @GetMapping(value = "/{transactionId}", produces = MediaType.APPLICATION_JSON_VALUE)
    @Operation(summary = "Get details of a specific transaction")
    public Mono<TransactionResponseDto> getTransaction(
            @PathVariable String transactionId) {
        return transactionService.getTransaction(transactionId);
    }
} 