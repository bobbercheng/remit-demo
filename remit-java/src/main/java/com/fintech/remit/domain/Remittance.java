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

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Represents a remittance transaction from India to Canada.
 * This is the core domain entity of the system.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table("remittance")
public class Remittance {
    
    @Id
    private UUID id;
    
    @Column("user_id")
    private String userId;
    
    @Column("source_amount")
    private BigDecimal sourceAmount;
    
    @Column("destination_amount")
    private BigDecimal destinationAmount;
    
    @Column("exchange_rate")
    private BigDecimal exchangeRate;
    
    @Column("status")
    private RemittanceStatus status;
    
    @Column("failure_reason")
    private String failureReason;
    
    @Column("purpose_code")
    private String purposeCode;
    
    @CreatedDate
    @Column("created_at")
    private Instant createdAt;
    
    @LastModifiedDate
    @Column("updated_at")
    private Instant updatedAt;
    
    /**
     * Create a new remittance with initial status
     * 
     * @param userId the user initiating the remittance
     * @param sourceAmount the amount in INR to be remitted
     * @param purposeCode the regulatory purpose code for the remittance
     * @return a new Remittance entity
     */
    public static Remittance createNew(String userId, BigDecimal sourceAmount, String purposeCode) {
        return Remittance.builder()
                .id(UUID.randomUUID())
                .userId(userId)
                .sourceAmount(sourceAmount)
                .status(RemittanceStatus.INITIATED)
                .purposeCode(purposeCode)
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();
    }
    
    /**
     * Update the remittance status
     * 
     * @param newStatus the new status
     * @return the updated remittance
     */
    public Remittance updateStatus(RemittanceStatus newStatus) {
        this.status = newStatus;
        this.updatedAt = Instant.now();
        return this;
    }
    
    /**
     * Mark the remittance as failed with a reason
     * 
     * @param reason the failure reason
     * @return the updated remittance
     */
    public Remittance markAsFailed(String reason) {
        this.status = RemittanceStatus.FAILED;
        this.failureReason = reason;
        this.updatedAt = Instant.now();
        return this;
    }
    
    /**
     * Update the remittance with currency conversion details
     * 
     * @param destinationAmount the converted amount in CAD
     * @param exchangeRate the exchange rate used
     * @return the updated remittance
     */
    public Remittance updateWithConversionDetails(BigDecimal destinationAmount, BigDecimal exchangeRate) {
        this.destinationAmount = destinationAmount;
        this.exchangeRate = exchangeRate;
        this.updatedAt = Instant.now();
        return this;
    }
} 