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
 * Entity representing Canadian recipient details for a remittance.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table("recipient_details")
public class RecipientDetails {
    
    @Id
    private UUID id;
    
    @Column("remittance_id")
    private UUID remittanceId;
    
    @Column("recipient_name")
    private String recipientName;
    
    @Column("bank_name")
    private String bankName;
    
    @Column("account_number")
    private String accountNumber;
    
    @Column("routing_number")
    private String routingNumber;
    
    @Column("account_type")
    private String accountType;
    
    @Column("address_line1")
    private String addressLine1;
    
    @Column("address_line2")
    private String addressLine2;
    
    @Column("city")
    private String city;
    
    @Column("province")
    private String province;
    
    @Column("postal_code")
    private String postalCode;
    
    @Column("country")
    private String country;
    
    @CreatedDate
    @Column("created_at")
    private Instant createdAt;
    
    @LastModifiedDate
    @Column("updated_at")
    private Instant updatedAt;
    
    /**
     * Creates a new recipient details record
     * 
     * @param remittanceId the ID of the associated remittance
     * @param recipientName name of the recipient
     * @param bankName name of the recipient's bank
     * @param accountNumber recipient's account number
     * @param routingNumber Canadian bank routing number
     * @param accountType type of account (CHECKING/SAVINGS)
     * @param addressLine1 first line of address
     * @param addressLine2 second line of address (optional)
     * @param city city
     * @param province province
     * @param postalCode postal code
     * @return a new RecipientDetails entity
     */
    public static RecipientDetails create(
            UUID remittanceId,
            String recipientName,
            String bankName,
            String accountNumber,
            String routingNumber,
            String accountType,
            String addressLine1,
            String addressLine2,
            String city,
            String province,
            String postalCode) {
        
        return RecipientDetails.builder()
                .id(UUID.randomUUID())
                .remittanceId(remittanceId)
                .recipientName(recipientName)
                .bankName(bankName)
                .accountNumber(accountNumber)
                .routingNumber(routingNumber)
                .accountType(accountType)
                .addressLine1(addressLine1)
                .addressLine2(addressLine2)
                .city(city)
                .province(province)
                .postalCode(postalCode)
                .country("CA") // Default to Canada
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();
    }
} 