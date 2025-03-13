package com.fintech.remit.domain;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.relational.core.mapping.Column;
import org.springframework.data.relational.core.mapping.Table;

import java.time.Instant;
import java.util.UUID;

/**
 * Entity representing fund transmission details for a remittance via Wise.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table("transmission_details")
public class TransmissionDetails {
    
    @Id
    private UUID id;
    
    @Column("remittance_id")
    private UUID remittanceId;
    
    @Column("wise_transaction_id")
    private String wiseTransactionId;
    
    @Column("transmission_status")
    private String transmissionStatus;
    
    @Column("status_description")
    private String statusDescription;
    
    @Column("estimated_delivery")
    private Instant estimatedDelivery;
    
    @Column("actual_delivery")
    private Instant actualDelivery;
    
    @CreatedDate
    @Column("created_at")
    private Instant createdAt;
    
    @LastModifiedDate
    @Column("updated_at")
    private Instant updatedAt;
    
    /**
     * Creates a new transmission details record
     * 
     * @param remittanceId the ID of the associated remittance
     * @return a new TransmissionDetails entity with initial status
     */
    public static TransmissionDetails create(UUID remittanceId) {
        return TransmissionDetails.builder()
                .id(UUID.randomUUID())
                .remittanceId(remittanceId)
                .transmissionStatus("PENDING")
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();
    }
    
    /**
     * Updates the transmission details after initiating with Wise
     * 
     * @param wiseTransactionId the Wise transaction ID
     * @param estimatedDelivery the estimated delivery time
     * @return the updated transmission details
     */
    public TransmissionDetails updateWithWiseDetails(String wiseTransactionId, Instant estimatedDelivery) {
        this.wiseTransactionId = wiseTransactionId;
        this.estimatedDelivery = estimatedDelivery;
        this.updatedAt = Instant.now();
        return this;
    }
    
    /**
     * Updates the transmission status from Wise callback
     * 
     * @param status the transmission status (COMPLETED/FAILED)
     * @param description optional status description
     * @return the updated transmission details
     */
    public TransmissionDetails updateTransmissionStatus(String status, String description) {
        this.transmissionStatus = status;
        this.statusDescription = description;
        
        if ("COMPLETED".equals(status)) {
            this.actualDelivery = Instant.now();
        }
        
        this.updatedAt = Instant.now();
        return this;
    }
} 