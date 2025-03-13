package com.fintech.remit.repository;

import com.fintech.remit.domain.Remittance;
import com.fintech.remit.domain.RemittanceStatus;
import org.springframework.data.domain.Pageable;
import org.springframework.data.r2dbc.repository.Query;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.Instant;
import java.util.UUID;

/**
 * Repository for accessing and manipulating Remittance entities.
 */
@Repository
public interface RemittanceRepository extends ReactiveCrudRepository<Remittance, UUID> {
    
    /**
     * Find all remittances for a specific user
     * 
     * @param userId the user ID
     * @return a flux of remittances
     */
    Flux<Remittance> findByUserId(String userId);
    
    /**
     * Find all remittances for a specific user with pagination
     * 
     * @param userId the user ID
     * @param pageable pagination information
     * @return a flux of remittances
     */
    Flux<Remittance> findByUserId(String userId, Pageable pageable);
    
    /**
     * Find all remittances with a specific status
     * 
     * @param status the remittance status
     * @return a flux of remittances
     */
    Flux<Remittance> findByStatus(RemittanceStatus status);
    
    /**
     * Find all remittances for a specific user with a specific status
     * 
     * @param userId the user ID
     * @param status the remittance status
     * @return a flux of remittances
     */
    Flux<Remittance> findByUserIdAndStatus(String userId, RemittanceStatus status);
    
    /**
     * Find all remittances created within a date range
     * 
     * @param startDate the start of the date range
     * @param endDate the end of the date range
     * @return a flux of remittances
     */
    Flux<Remittance> findByCreatedAtBetween(Instant startDate, Instant endDate);
    
    /**
     * Count remittances by status
     * 
     * @param status the remittance status
     * @return a mono with the count
     */
    Mono<Long> countByStatus(RemittanceStatus status);
    
    /**
     * Find remittances that have been in a non-terminal state for too long
     * Used for identifying stuck transactions
     * 
     * @param statuses the non-terminal statuses to check
     * @param thresholdTime the time threshold (remittances older than this are "stuck")
     * @return a flux of potentially stuck remittances
     */
    @Query("SELECT * FROM remittance WHERE status IN (:statuses) AND updated_at < :thresholdTime")
    Flux<Remittance> findPotentiallyStuckRemittances(RemittanceStatus[] statuses, Instant thresholdTime);
} 