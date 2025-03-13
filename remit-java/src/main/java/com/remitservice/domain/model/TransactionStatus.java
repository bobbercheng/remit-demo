package com.remitservice.domain.model;

/**
 * Enum representing the possible states of a remittance transaction.
 */
public enum TransactionStatus {
    /**
     * Transaction has been initiated but not yet funded
     */
    INITIATED,

    /**
     * Transaction has been funded via UPI but currency conversion not done
     */
    FUNDED,

    /**
     * Currency has been converted but not yet transmitted
     */
    CONVERTED,

    /**
     * Transaction is being processed by Wise for cross-border transmission
     */
    PROCESSING,

    /**
     * Transaction has been completed successfully
     */
    COMPLETED,

    /**
     * Transaction has failed
     */
    FAILED
} 