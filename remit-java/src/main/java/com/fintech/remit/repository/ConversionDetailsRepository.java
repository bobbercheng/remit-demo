package com.fintech.remit.repository;

import com.fintech.remit.domain.ConversionDetails;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Mono;

import java.util.UUID;

/**
 * Repository for accessing and manipulating ConversionDetails entities.
 */
@Repository
public interface ConversionDetailsRepository extends ReactiveCrudRepository<ConversionDetails, UUID> {
    
    /**
     * Find conversion details for a specific remittance
     * 
     * @param remittanceId the remittance ID
     * @return a mono of the conversion details
     */
    Mono<ConversionDetails> findByRemittanceId(UUID remittanceId);
} 