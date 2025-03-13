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
 * Entity representing currency conversion details for a remittance via AD Bank.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table("conversion_details")
public class ConversionDetails {
    
    @Id
    private UUID id;
    
    @Column("remittance_id")
    private UUID remittanceId;
    
    @Column("adbank_reference")
    private String adbankReference;
    
    @Column("source_currency")
    private String sourceCurrency;
    
    @Column("destination_currency")
    private String destinationCurrency;
    
    @Column("conversion_status")
    private String conversionStatus;
    
    @Column("status_description")
    private String statusDescription;
    
    @Column("conversion_timestamp")
    private Instant conversionTimestamp;
    
    @CreatedDate
    @Column("created_at")
    private Instant createdAt;
    
    @LastModifiedDate
    @Column("updated_at")
    private Instant updatedAt;
    
    /**
     * Creates a new conversion details record for INR to CAD conversion
     * 
     * @param remittanceId the ID of the associated remittance
     * @return a new ConversionDetails entity with initial status
     */
    public static ConversionDetails createForInrToCad(UUID remittanceId) {
        return ConversionDetails.builder()
                .id(UUID.randomUUID())
                .remittanceId(remittanceId)
                .sourceCurrency("INR")
                .destinationCurrency("CAD")
                .conversionStatus("PENDING")
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();
    }
    
    /**
     * Updates the conversion details after AD Bank processing
     * 
     * @param adbankReference the AD Bank reference number
     * @param status the conversion status (COMPLETED/FAILED)
     * @param description optional status description
     * @return the updated conversion details
     */
    public ConversionDetails updateConversionStatus(String adbankReference, String status, String description) {
        this.adbankReference = adbankReference;
        this.conversionStatus = status;
        this.statusDescription = description;
        this.conversionTimestamp = Instant.now();
        this.updatedAt = Instant.now();
        return this;
    }
} 