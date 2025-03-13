package com.fintech.remit.repository;

import com.fintech.remit.domain.TransmissionDetails;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Mono;

import java.util.UUID;

/**
 * Repository for accessing and manipulating TransmissionDetails entities.
 */
@Repository
public interface TransmissionDetailsRepository extends ReactiveCrudRepository<TransmissionDetails, UUID> {
    
    /**
     * Find transmission details for a specific remittance
     * 
     * @param remittanceId the remittance ID
     * @return a mono of the transmission details
     */
    Mono<TransmissionDetails> findByRemittanceId(UUID remittanceId);
    
    /**
     * Find transmission details by Wise transaction ID
     * 
     * @param wiseTransactionId the Wise transaction ID
     * @return a mono of the transmission details
     */
    Mono<TransmissionDetails> findByWiseTransactionId(String wiseTransactionId);
} 