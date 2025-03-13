package com.fintech.remit.domain;

/**
 * Enum representing the various states a remittance can be in.
 * This follows the sequential workflow of the remittance process.
 */
public enum RemittanceStatus {
    /**
     * Initial state when the remittance request is created
     */
    INITIATED,
    
    /**
     * Funds have been successfully collected via UPI in India
     */
    FUNDS_COLLECTED,
    
    /**
     * Currency conversion from INR to CAD has been completed via AD Bank
     */
    CONVERSION_COMPLETED,
    
    /**
     * Funds have been transmitted to Canada via Wise
     */
    TRANSMITTED,
    
    /**
     * Remittance has been successfully completed, funds delivered to recipient
     */
    COMPLETED,
    
    /**
     * Remittance has failed at some point in the process
     */
    FAILED
} 