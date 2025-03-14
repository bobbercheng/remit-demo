package com.remitservice.integration.wise.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Request model for creating a Wise transfer.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WiseTransferRequest {
    
    /**
     * Quote ID from a previously created quote
     */
    @JsonProperty("quoteId")
    private String quoteId;
    
    /**
     * Customer transaction ID for reference
     */
    @JsonProperty("customerTransactionId")
    private String customerTransactionId;
    
    /**
     * Details of the target account
     */
    @JsonProperty("targetAccount")
    private TargetAccount targetAccount;
    
    /**
     * The customer reference text to show in statements
     */
    @JsonProperty("reference")
    private String reference;
    
    /**
     * Callback URL for transfer status updates
     */
    @JsonProperty("callbackUrl")
    private String callbackUrl;
    
    /**
     * Target account details for the transfer.
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TargetAccount {
        
        /**
         * Account holder's full name
         */
        @JsonProperty("accountHolderName")
        private String accountHolderName;
        
        /**
         * Bank account number
         */
        @JsonProperty("accountNumber")
        private String accountNumber;
        
        /**
         * Bank code (routing number in Canada)
         */
        @JsonProperty("routingNumber")
        private String routingNumber;
        
        /**
         * Bank name
         */
        @JsonProperty("bankName")
        private String bankName;
        
        /**
         * City of the account holder
         */
        @JsonProperty("city")
        private String city;
        
        /**
         * Postal code
         */
        @JsonProperty("postCode")
        private String postCode;
        
        /**
         * Country code (e.g., CA for Canada)
         */
        @JsonProperty("country")
        private String country;
    }
} 