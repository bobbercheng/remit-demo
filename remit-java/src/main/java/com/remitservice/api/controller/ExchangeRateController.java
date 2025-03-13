package com.remitservice.api.controller;

import com.remitservice.api.dto.ExchangeRateResponseDto;
import com.remitservice.service.exchange.ExchangeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.NotBlank;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

/**
 * REST controller for exchange rate operations.
 */
@RestController
@RequestMapping("/api/v1/exchange-rates")
@RequiredArgsConstructor
@Validated
@Tag(name = "Exchange Rates", description = "API for currency exchange rates")
public class ExchangeRateController {

    private final ExchangeService exchangeService;

    /**
     * Gets the current exchange rate for a currency pair.
     *
     * @param sourceCurrency      Source currency code (e.g., INR)
     * @param destinationCurrency Destination currency code (e.g., CAD)
     * @return Exchange rate information
     */
    @GetMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    @Operation(summary = "Get current exchange rate for a currency pair")
    public Mono<ExchangeRateResponseDto> getExchangeRate(
            @NotBlank(message = "Source currency is required")
            @RequestParam String sourceCurrency,
            @NotBlank(message = "Destination currency is required")
            @RequestParam String destinationCurrency) {
        return exchangeService.getExchangeRate(sourceCurrency, destinationCurrency);
    }
} 