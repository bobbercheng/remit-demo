package com.remitservice.api.controller;

import com.remitservice.api.dto.PaymentInstructionsResponseDto;
import com.remitservice.service.payment.PaymentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

/**
 * REST controller for payment operations.
 */
@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
@Tag(name = "Payments", description = "API for payment operations")
public class PaymentController {

    private final PaymentService paymentService;

    /**
     * Generates payment instructions for a transaction.
     *
     * @param transactionId Transaction ID
     * @return Payment instructions
     */
    @PostMapping(value = "/transactions/{transactionId}/payment", produces = MediaType.APPLICATION_JSON_VALUE)
    @Operation(summary = "Generate payment instructions for a transaction")
    public Mono<PaymentInstructionsResponseDto> generatePaymentInstructions(
            @PathVariable String transactionId) {
        return paymentService.generatePaymentInstructions(transactionId);
    }

    /**
     * Handles UPI payment callback.
     *
     * @param paymentReference Payment reference
     * @param status Payment status
     * @return Success response
     */
    @PostMapping(value = "/callbacks/upi", produces = MediaType.APPLICATION_JSON_VALUE)
    @Operation(summary = "Handle UPI payment callback")
    public Mono<Void> handleUpiCallback(
            @RequestParam String paymentReference,
            @RequestParam String status) {
        return paymentService.processPaymentCallback(paymentReference, status);
    }
} 