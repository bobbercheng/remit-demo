package com.remitservice.domain.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Model class representing recipient details for a remittance transaction.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RecipientDetails {
    
    /**
     * Recipient's full name
     */
    private String name;
    
    /**
     * Recipient's bank account number
     */
    private String accountNumber;
    
    /**
     * Recipient's bank code (routing number in Canada)
     */
    private String bankCode;
    
    /**
     * Recipient's bank name
     */
    private String bankName;
    
    /**
     * Recipient's address
     */
    private String address;
    
    /**
     * Recipient's city
     */
    private String city;
    
    /**
     * Recipient's postal code
     */
    private String postalCode;
    
    /**
     * Recipient's province/state
     */
    private String province;
} 