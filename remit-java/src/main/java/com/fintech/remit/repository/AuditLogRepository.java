package com.fintech.remit.repository;

import com.fintech.remit.domain.AuditLog;
import org.springframework.data.domain.Pageable;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;

import java.time.Instant;
import java.util.UUID;

/**
 * Repository for accessing and manipulating AuditLog entities.
 */
@Repository
public interface AuditLogRepository extends ReactiveCrudRepository<AuditLog, UUID> {
    
    /**
     * Find audit logs for a specific remittance
     * 
     * @param remittanceId the remittance ID
     * @return a flux of audit logs
     */
    Flux<AuditLog> findByRemittanceId(UUID remittanceId);
    
    /**
     * Find audit logs for a specific remittance with pagination
     * 
     * @param remittanceId the remittance ID
     * @param pageable pagination information
     * @return a flux of audit logs
     */
    Flux<AuditLog> findByRemittanceId(UUID remittanceId, Pageable pageable);
    
    /**
     * Find audit logs for a specific event type
     * 
     * @param eventType the event type
     * @return a flux of audit logs
     */
    Flux<AuditLog> findByEventType(String eventType);
    
    /**
     * Find audit logs within a time range
     * 
     * @param startTime the start of the time range
     * @param endTime the end of the time range
     * @return a flux of audit logs
     */
    Flux<AuditLog> findByTimestampBetween(Instant startTime, Instant endTime);
    
    /**
     * Find audit logs by actor
     * 
     * @param actor the actor (user ID or system)
     * @return a flux of audit logs
     */
    Flux<AuditLog> findByActor(String actor);
} 