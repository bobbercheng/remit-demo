package com.remitservice.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Scanner;

/**
 * Configuration for OpenAPI documentation.
 */
@Configuration
public class OpenApiConfig {

    private final ResourceLoader resourceLoader;

    public OpenApiConfig(ResourceLoader resourceLoader) {
        this.resourceLoader = resourceLoader;
    }

    /**
     * Creates an OpenAPI bean for Swagger documentation.
     * This version directly configures the OpenAPI specification programmatically.
     *
     * @return OpenAPI
     */
    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
                .components(new Components()
                        .addSecuritySchemes("bearer-key",
                                new SecurityScheme()
                                        .type(SecurityScheme.Type.HTTP)
                                        .scheme("bearer")
                                        .bearerFormat("JWT")))
                .info(new Info()
                        .title("Remittance Service API")
                        .description("API for a near real-time cross-border remittance service between India and Canada")
                        .version("1.0.0")
                        .contact(new Contact()
                                .name("Remittance Service Team")
                                .email("contact@remitservice.com")
                                .url("https://remitservice.com"))
                        .license(new License()
                                .name("Private License")
                                .url("https://remitservice.com/license")));
    }

    /**
     * Alternative method to load OpenAPI specification from a JSON file.
     * This can be activated by commenting out the customOpenAPI method and uncommenting this.
     *
     * @return OpenAPI specification loaded from JSON
     * @throws IOException if the file cannot be read
     */
    /*
    @Bean
    public String openApiJson() throws IOException {
        Resource resource = resourceLoader.getResource("classpath:static/swagger/remittance-api-spec.json");
        try (InputStream inputStream = resource.getInputStream()) {
            try (Scanner scanner = new Scanner(inputStream, StandardCharsets.UTF_8.name())) {
                return scanner.useDelimiter("\\A").next();
            }
        }
    }
    */
} 