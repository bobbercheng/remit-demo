package com.remitservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.reactive.config.EnableWebFlux;

/**
 * Main application class for the Remittance Service.
 * This service provides near real-time cross-border remittance between India and Canada.
 */
@SpringBootApplication
@EnableWebFlux
public class RemitServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(RemitServiceApplication.class, args);
    }
} 