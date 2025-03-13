package com.fintech.remit.repository;

import com.fintech.remit.domain.PaymentDetails;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Mono;

import java.util.UUID;

/**
 * Repository for accessing and manipulating PaymentDetails entities.
 */
@Repository
public interface PaymentDetailsRepository extends ReactiveCrudRepository<PaymentDetails, UUID> {
    
    /**
     * Find payment details for a specific remittance
     * 
     * @param remittanceId the remittance ID
     * @return a mono of the payment details
     */
    Mono<PaymentDetails> findByRemittanceId(UUID remittanceId);
} 