package com.remitservice.api.mapper;

import com.remitservice.api.dto.TransactionRequestDto;
import com.remitservice.api.dto.TransactionResponseDto;
import com.remitservice.domain.model.Transaction;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Mapper for converting between Transaction domain models and DTOs.
 */
@Component
public class TransactionMapper {

    private final RecipientDetailsMapper recipientDetailsMapper;

    public TransactionMapper(RecipientDetailsMapper recipientDetailsMapper) {
        this.recipientDetailsMapper = recipientDetailsMapper;
    }

    /**
     * Maps TransactionRequestDto to Transaction domain model.
     *
     * @param requestDto The request DTO
     * @return Transaction domain model
     */
    public Mono<Transaction> toEntity(TransactionRequestDto requestDto) {
        return Mono.just(Transaction.builder()
                .transactionId(UUID.randomUUID().toString())
                .sourceAmount(requestDto.getSourceAmount())
                .sourceCurrency(requestDto.getSourceCurrency())
                .destinationCurrency(requestDto.getDestinationCurrency())
                .recipientDetails(recipientDetailsMapper.toEntity(requestDto.getRecipientDetails()))
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build());
    }

    /**
     * Maps Transaction domain model to TransactionResponseDto.
     *
     * @param transaction The transaction entity
     * @return Transaction response DTO
     */
    public Mono<TransactionResponseDto> toDto(Transaction transaction) {
        return Mono.just(TransactionResponseDto.builder()
                .transactionId(transaction.getTransactionId())
                .userId(transaction.getUserId())
                .sourceAmount(transaction.getSourceAmount())
                .destinationAmount(transaction.getDestinationAmount())
                .exchangeRate(transaction.getExchangeRate())
                .sourceCurrency(transaction.getSourceCurrency())
                .destinationCurrency(transaction.getDestinationCurrency())
                .status(transaction.getStatus())
                .recipientDetails(recipientDetailsMapper.toDto(transaction.getRecipientDetails()))
                .createdAt(transaction.getCreatedAt())
                .updatedAt(transaction.getUpdatedAt())
                .estimatedCompletionTime(transaction.getEstimatedCompletionTime())
                .fee(transaction.getFee())
                .failureReason(transaction.getFailureReason())
                .build());
    }
} 