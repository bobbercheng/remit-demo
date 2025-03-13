package com.fintech.remit.repository;

import com.fintech.remit.domain.RecipientDetails;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Mono;

import java.util.UUID;

/**
 * Repository for accessing and manipulating RecipientDetails entities.
 */
@Repository
public interface RecipientDetailsRepository extends ReactiveCrudRepository<RecipientDetails, UUID> {
    
    /**
     * Find recipient details for a specific remittance
     * 
     * @param remittanceId the remittance ID
     * @return a mono of the recipient details
     */
    Mono<RecipientDetails> findByRemittanceId(UUID remittanceId);
} 