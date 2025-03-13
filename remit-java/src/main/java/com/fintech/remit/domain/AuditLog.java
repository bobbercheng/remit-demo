package com.fintech.remit.domain;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Column;
import org.springframework.data.relational.core.mapping.Table;

import java.time.Instant;
import java.util.UUID;

/**
 * Entity representing audit logs for remittance events.
 * Used for tracking all events and changes in the remittance process.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table("audit_log")
public class AuditLog {
    
    @Id
    private UUID id;
    
    @Column("remittance_id")
    private UUID remittanceId;
    
    @Column("event_type")
    private String eventType;
    
    @Column("description")
    private String description;
    
    @Column("metadata")
    private String metadata;
    
    @Column("actor")
    private String actor;
    
    @Column("timestamp")
    private Instant timestamp;
    
    /**
     * Creates a new audit log entry
     * 
     * @param remittanceId the ID of the associated remittance (may be null for system-wide events)
     * @param eventType the type of event
     * @param description a description of the event
     * @param metadata additional JSON metadata about the event (optional)
     * @param actor the actor who triggered the event (user ID or system)
     * @return a new AuditLog entity
     */
    public static AuditLog create(UUID remittanceId, String eventType, String description, String metadata, String actor) {
        return AuditLog.builder()
                .id(UUID.randomUUID())
                .remittanceId(remittanceId)
                .eventType(eventType)
                .description(description)
                .metadata(metadata)
                .actor(actor)
                .timestamp(Instant.now())
                .build();
    }
    
    /**
     * Creates a system audit log entry
     * 
     * @param remittanceId the ID of the associated remittance (may be null for system-wide events)
     * @param eventType the type of event
     * @param description a description of the event
     * @param metadata additional JSON metadata about the event (optional)
     * @return a new AuditLog entity with the system as the actor
     */
    public static AuditLog createSystemLog(UUID remittanceId, String eventType, String description, String metadata) {
        return create(remittanceId, eventType, description, metadata, "SYSTEM");
    }
    
    /**
     * Creates a user audit log entry
     * 
     * @param remittanceId the ID of the associated remittance
     * @param eventType the type of event
     * @param description a description of the event
     * @param metadata additional JSON metadata about the event (optional)
     * @param userId the ID of the user who triggered the event
     * @return a new AuditLog entity with the user as the actor
     */
    public static AuditLog createUserLog(UUID remittanceId, String eventType, String description, String metadata, String userId) {
        return create(remittanceId, eventType, description, metadata, "USER:" + userId);
    }
} 