-- Remittance Service Database Schema

-- Remittance table to track all remittance transactions
CREATE TABLE remittance (
    id UUID PRIMARY KEY,
    user_id VARCHAR(100) NOT NULL, -- External user ID from User Service
    source_amount DECIMAL(15, 2) NOT NULL, -- Amount in INR
    destination_amount DECIMAL(15, 2), -- Amount in CAD (filled after conversion)
    exchange_rate DECIMAL(10, 6), -- Exchange rate used for conversion
    status VARCHAR(20) NOT NULL, -- INITIATED, FUNDS_COLLECTED, CONVERSION_COMPLETED, TRANSMITTED, COMPLETED, FAILED
    failure_reason TEXT, -- Reason for failure, if any
    purpose_code VARCHAR(5), -- Purpose of remittance (as per regulatory requirements)
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Payment details for fund collection in India
CREATE TABLE payment_details (
    id UUID PRIMARY KEY,
    remittance_id UUID NOT NULL REFERENCES remittance(id),
    source_payment_method VARCHAR(20) NOT NULL, -- UPI in this case
    payment_reference VARCHAR(100), -- UPI transaction ID or reference
    payment_status VARCHAR(20) NOT NULL, -- PENDING, COMPLETED, FAILED
    status_description TEXT,
    payment_timestamp TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Recipient details for Canadian bank account
CREATE TABLE recipient_details (
    id UUID PRIMARY KEY,
    remittance_id UUID NOT NULL REFERENCES remittance(id),
    recipient_name VARCHAR(100) NOT NULL,
    bank_name VARCHAR(100) NOT NULL,
    account_number VARCHAR(50) NOT NULL,
    routing_number VARCHAR(20) NOT NULL, -- Canadian routing number
    account_type VARCHAR(20) NOT NULL, -- CHECKING, SAVINGS
    address_line1 VARCHAR(100),
    address_line2 VARCHAR(100),
    city VARCHAR(50),
    province VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(2) NOT NULL DEFAULT 'CA',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Conversion details for currency exchange via AD Bank
CREATE TABLE conversion_details (
    id UUID PRIMARY KEY,
    remittance_id UUID NOT NULL REFERENCES remittance(id),
    adbank_reference VARCHAR(100), -- AD Bank reference number
    source_currency VARCHAR(3) NOT NULL DEFAULT 'INR',
    destination_currency VARCHAR(3) NOT NULL DEFAULT 'CAD',
    conversion_status VARCHAR(20) NOT NULL, -- PENDING, COMPLETED, FAILED
    status_description TEXT,
    conversion_timestamp TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Transmission details for fund transfer to Canada via Wise
CREATE TABLE transmission_details (
    id UUID PRIMARY KEY,
    remittance_id UUID NOT NULL REFERENCES remittance(id),
    wise_transaction_id VARCHAR(100), -- Wise reference number
    transmission_status VARCHAR(20) NOT NULL, -- PENDING, COMPLETED, FAILED
    status_description TEXT,
    estimated_delivery TIMESTAMP WITH TIME ZONE,
    actual_delivery TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Audit log for all remittance related events
CREATE TABLE audit_log (
    id UUID PRIMARY KEY,
    remittance_id UUID REFERENCES remittance(id),
    event_type VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    metadata JSONB, -- Additional event metadata
    actor VARCHAR(50), -- System or user identifier that triggered the event
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX idx_remittance_user_id ON remittance(user_id);
CREATE INDEX idx_remittance_status ON remittance(status);
CREATE INDEX idx_remittance_created_at ON remittance(created_at);
CREATE INDEX idx_payment_details_remittance_id ON payment_details(remittance_id);
CREATE INDEX idx_recipient_details_remittance_id ON recipient_details(remittance_id);
CREATE INDEX idx_conversion_details_remittance_id ON conversion_details(remittance_id);
CREATE INDEX idx_transmission_details_remittance_id ON transmission_details(remittance_id);
CREATE INDEX idx_audit_log_remittance_id ON audit_log(remittance_id);
CREATE INDEX idx_audit_log_timestamp ON audit_log(timestamp);

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers to automatically update the updated_at column
CREATE TRIGGER update_remittance_updated_at
    BEFORE UPDATE ON remittance
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payment_details_updated_at
    BEFORE UPDATE ON payment_details
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_recipient_details_updated_at
    BEFORE UPDATE ON recipient_details
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_conversion_details_updated_at
    BEFORE UPDATE ON conversion_details
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transmission_details_updated_at
    BEFORE UPDATE ON transmission_details
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column(); 