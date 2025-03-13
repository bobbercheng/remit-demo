package com.fintech.remit;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.info.Contact;

/**
 * Main application class for the Remittance Service.
 * This service provides near real-time cross-border remittance functionality
 * between India and Canada.
 */
@SpringBootApplication
@OpenAPIDefinition(
    info = @Info(
        title = "Remittance API",
        version = "1.0",
        description = "API for managing cross-border remittances between India and Canada",
        contact = @Contact(name = "FinTech Remit Team", email = "support@fintechremit.com")
    )
)
public class RemitApplication {

    public static void main(String[] args) {
        SpringApplication.run(RemitApplication.class, args);
    }
} 