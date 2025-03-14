package com.remitservice.integration.wise;

import com.remitservice.config.properties.IntegrationProperties;
import com.remitservice.integration.wise.model.WiseQuoteRequest;
import com.remitservice.integration.wise.model.WiseQuoteResponse;
import com.remitservice.integration.wise.model.WiseTransferRequest;
import com.remitservice.integration.wise.model.WiseTransferResponse;
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

import static org.mockito.Mockito.when;

/**
 * Unit tests for Wise client implementation.
 */
@ExtendWith(MockitoExtension.class)
public class WiseClientImplTest {

    private MockWebServer mockWebServer;
    private WiseClientImpl wiseClient;

    @Mock
    private IntegrationProperties integrationProperties;

    @Mock
    private IntegrationProperties.WiseProperties wiseProperties;

    @BeforeEach
    void setup() {
        mockWebServer = new MockWebServer();
        
        when(integrationProperties.getWise()).thenReturn(wiseProperties);
        when(wiseProperties.getBaseUrl()).thenReturn(mockWebServer.url("/").toString());
        when(wiseProperties.getApiKey()).thenReturn("test-api-key");
        when(wiseProperties.getProfileId()).thenReturn("profile-123");
        when(wiseProperties.getCallbackUrl()).thenReturn("http://localhost:8080/api/v1/callbacks/wise");
        
        WebClient webClient = WebClient.builder()
                .baseUrl(mockWebServer.url("/").toString())
                .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .build();
        
        wiseClient = new WiseClientImpl(WebClient.builder(), integrationProperties);
    }

    @AfterEach
    void tearDown() throws IOException {
        mockWebServer.shutdown();
    }

    @Test
    void createQuote_shouldReturnQuoteResponse() {
        // Given
        String responseBody = """
                {
                  "id": "quote-123456",
                  "sourceCurrency": "INR",
                  "targetCurrency": "CAD",
                  "sourceAmount": 10000.0,
                  "targetAmount": 160.25,
                  "rate": 0.01602,
                  "expirationTime": "2023-08-01T12:00:00",
                  "fee": 150.0,
                  "estimatedDelivery": "2023-08-02T12:00:00"
                }
                """;
        
        mockWebServer.enqueue(new MockResponse()
                .setResponseCode(200)
                .setHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .setBody(responseBody));
        
        WiseQuoteRequest request = WiseQuoteRequest.builder()
                .sourceCurrency("INR")
                .targetCurrency("CAD")
                .sourceAmount(10000.0)
                .build();
        
        // When
        Mono<WiseQuoteResponse> result = wiseClient.createQuote(request);
        
        // Then
        StepVerifier.create(result)
                .expectNextMatches(response -> 
                        response.getId().equals("quote-123456") &&
                        response.getSourceCurrency().equals("INR") &&
                        response.getTargetCurrency().equals("CAD") &&
                        response.getSourceAmount().equals(10000.0) &&
                        response.getTargetAmount().equals(160.25) &&
                        response.getRate().equals(0.01602))
                .verifyComplete();
    }

    @Test
    void createTransfer_shouldReturnTransferResponse() {
        // Given
        String responseBody = """
                {
                  "id": "transfer-123456",
                  "customerTransactionId": "txn-987654",
                  "quoteId": "quote-123456",
                  "status": "PROCESSING",
                  "sourceCurrency": "INR",
                  "sourceAmount": 10000.0,
                  "targetCurrency": "CAD",
                  "targetAmount": 160.25,
                  "reference": "Remittance to Canada",
                  "created": "2023-08-01T10:00:00",
                  "estimatedDelivery": "2023-08-02T12:00:00"
                }
                """;
        
        mockWebServer.enqueue(new MockResponse()
                .setResponseCode(200)
                .setHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .setBody(responseBody));
        
        WiseTransferRequest.TargetAccount targetAccount = WiseTransferRequest.TargetAccount.builder()
                .accountHolderName("John Doe")
                .accountNumber("1234567890")
                .routingNumber("56789")
                .bankName("Royal Bank of Canada")
                .city("Toronto")
                .postCode("M5V 2H1")
                .country("CA")
                .build();
        
        WiseTransferRequest request = WiseTransferRequest.builder()
                .quoteId("quote-123456")
                .customerTransactionId("txn-987654")
                .targetAccount(targetAccount)
                .reference("Remittance to Canada")
                .build();
        
        // When
        Mono<WiseTransferResponse> result = wiseClient.createTransfer(request);
        
        // Then
        StepVerifier.create(result)
                .expectNextMatches(response -> 
                        response.getId().equals("transfer-123456") &&
                        response.getCustomerTransactionId().equals("txn-987654") &&
                        response.getQuoteId().equals("quote-123456") &&
                        response.getStatus().equals("PROCESSING") &&
                        response.getSourceCurrency().equals("INR") &&
                        response.getTargetCurrency().equals("CAD"))
                .verifyComplete();
    }

    @Test
    void getTransfer_shouldReturnTransferDetails() {
        // Given
        String responseBody = """
                {
                  "id": "transfer-123456",
                  "customerTransactionId": "txn-987654",
                  "quoteId": "quote-123456",
                  "status": "COMPLETED",
                  "sourceCurrency": "INR",
                  "sourceAmount": 10000.0,
                  "targetCurrency": "CAD",
                  "targetAmount": 160.25,
                  "reference": "Remittance to Canada",
                  "created": "2023-08-01T10:00:00",
                  "estimatedDelivery": "2023-08-02T12:00:00"
                }
                """;
        
        mockWebServer.enqueue(new MockResponse()
                .setResponseCode(200)
                .setHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .setBody(responseBody));
        
        // When
        Mono<WiseTransferResponse> result = wiseClient.getTransfer("transfer-123456");
        
        // Then
        StepVerifier.create(result)
                .expectNextMatches(response -> 
                        response.getId().equals("transfer-123456") &&
                        response.getStatus().equals("COMPLETED"))
                .verifyComplete();
    }
} 