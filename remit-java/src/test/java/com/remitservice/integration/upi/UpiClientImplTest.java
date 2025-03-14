package com.remitservice.integration.upi;

import com.remitservice.config.properties.IntegrationProperties;
import com.remitservice.integration.upi.model.UpiPaymentRequest;
import com.remitservice.integration.upi.model.UpiPaymentResponse;
import okhttp3.mockwebserver.MockResponse;
import okhttp3.mockwebserver.MockWebServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

import java.io.IOException;
import java.time.LocalDateTime;

import static org.mockito.Mockito.when;

/**
 * Unit tests for UPI client implementation.
 */
@ExtendWith(MockitoExtension.class)
public class UpiClientImplTest {

    private MockWebServer mockWebServer;
    private UpiClientImpl upiClient;

    @Mock
    private IntegrationProperties integrationProperties;

    @Mock
    private IntegrationProperties.UpiProperties upiProperties;

    @BeforeEach
    void setup() {
        mockWebServer = new MockWebServer();
        
        when(integrationProperties.getUpi()).thenReturn(upiProperties);
        when(upiProperties.getBaseUrl()).thenReturn(mockWebServer.url("/").toString());
        when(upiProperties.getApiKey()).thenReturn("test-api-key");
        when(upiProperties.getCallbackUrl()).thenReturn("http://localhost:8080/api/v1/callbacks/upi");
        
        WebClient webClient = WebClient.builder()
                .baseUrl(mockWebServer.url("/").toString())
                .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .build();
        
        upiClient = new UpiClientImpl(WebClient.builder(), integrationProperties);
    }

    @AfterEach
    void tearDown() throws IOException {
        mockWebServer.shutdown();
    }

    @Test
    void createPaymentRequest_shouldReturnPaymentResponse() {
        // Given
        String responseBody = """
                {
                  "paymentId": "upi-123456",
                  "reference": "txn-987654",
                  "status": "PENDING",
                  "upiId": "merchant@upi",
                  "amount": 1000.0,
                  "currency": "INR",
                  "deepLink": "upi://pay?pa=merchant@upi&am=1000.0&tr=txn-987654",
                  "qrCode": "base64encodedqrcode",
                  "expiresAt": "2023-08-01T12:00:00"
                }
                """;
        
        mockWebServer.enqueue(new MockResponse()
                .setResponseCode(200)
                .setHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .setBody(responseBody));
        
        UpiPaymentRequest request = UpiPaymentRequest.builder()
                .amount(1000.0)
                .currency("INR")
                .reference("txn-987654")
                .description("Test payment")
                .vpa("merchant@upi")
                .expiryMinutes(30)
                .build();
        
        // When
        Mono<UpiPaymentResponse> result = upiClient.createPaymentRequest(request);
        
        // Then
        StepVerifier.create(result)
                .expectNextMatches(response -> 
                        response.getPaymentId().equals("upi-123456") &&
                        response.getReference().equals("txn-987654") &&
                        response.getStatus().equals("PENDING") &&
                        response.getAmount().equals(1000.0) &&
                        response.getCurrency().equals("INR"))
                .verifyComplete();
    }

    @Test
    void checkPaymentStatus_shouldReturnPaymentStatus() {
        // Given
        String responseBody = """
                {
                  "paymentId": "upi-123456",
                  "reference": "txn-987654",
                  "status": "SUCCESS",
                  "upiId": "merchant@upi",
                  "amount": 1000.0,
                  "currency": "INR"
                }
                """;
        
        mockWebServer.enqueue(new MockResponse()
                .setResponseCode(200)
                .setHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .setBody(responseBody));
        
        // When
        Mono<UpiPaymentResponse> result = upiClient.checkPaymentStatus("upi-123456");
        
        // Then
        StepVerifier.create(result)
                .expectNextMatches(response -> 
                        response.getPaymentId().equals("upi-123456") &&
                        response.getReference().equals("txn-987654") &&
                        response.getStatus().equals("SUCCESS"))
                .verifyComplete();
    }
} 