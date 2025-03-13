package com.remitservice.api.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO for recipient details in API requests and responses.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RecipientDetailsDto {
    
    /**
     * Recipient's full name
     */
    @NotBlank(message = "Recipient name is required")
    private String name;
    
    /**
     * Recipient's bank account number
     */
    @NotBlank(message = "Account number is required")
    private String accountNumber;
    
    /**
     * Recipient's bank code (routing number in Canada)
     */
    @NotBlank(message = "Bank code is required")
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