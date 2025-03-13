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
 * Entity representing payment details for a remittance.
 * Tracks the UPI payment in India.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table("payment_details")
public class PaymentDetails {
    
    @Id
    private UUID id;
    
    @Column("remittance_id")
    private UUID remittanceId;
    
    @Column("source_payment_method")
    private String sourcePaymentMethod;
    
    @Column("payment_reference")
    private String paymentReference;
    
    @Column("payment_status")
    private String paymentStatus;
    
    @Column("status_description")
    private String statusDescription;
    
    @Column("payment_timestamp")
    private Instant paymentTimestamp;
    
    @CreatedDate
    @Column("created_at")
    private Instant createdAt;
    
    @LastModifiedDate
    @Column("updated_at")
    private Instant updatedAt;
    
    /**
     * Creates a new payment details record for UPI payment
     * 
     * @param remittanceId the ID of the associated remittance
     * @return a new PaymentDetails entity with initial status
     */
    public static PaymentDetails createForUpi(UUID remittanceId) {
        return PaymentDetails.builder()
                .id(UUID.randomUUID())
                .remittanceId(remittanceId)
                .sourcePaymentMethod("UPI")
                .paymentStatus("PENDING")
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();
    }
    
    /**
     * Updates the payment status after UPI callback
     * 
     * @param paymentReference the UPI transaction reference
     * @param status the payment status (COMPLETED/FAILED)
     * @param description optional status description
     * @return the updated payment details
     */
    public PaymentDetails updatePaymentStatus(String paymentReference, String status, String description) {
        this.paymentReference = paymentReference;
        this.paymentStatus = status;
        this.statusDescription = description;
        this.paymentTimestamp = Instant.now();
        this.updatedAt = Instant.now();
        return this;
    }
} 