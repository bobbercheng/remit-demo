package com.fintech.remit.config;

import io.netty.channel.ChannelOption;
import io.netty.handler.timeout.ReadTimeoutHandler;
import io.netty.handler.timeout.WriteTimeoutHandler;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.web.reactive.function.client.ExchangeFilterFunction;
import org.springframework.web.reactive.function.client.ExchangeStrategies;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;
import reactor.netty.http.client.HttpClient;

import java.time.Duration;
import java.util.concurrent.TimeUnit;

/**
 * Configuration for WebClient instances used to call external APIs.
 */
@Configuration
public class WebClientConfig {
    
    /**
     * Create a WebClient builder with common configuration
     * 
     * @return the WebClient.Builder
     */
    @Bean
    public WebClient.Builder webClientBuilder() {
        // Increase memory buffer for large responses
        final int size = 16 * 1024 * 1024; // 16MB
        final ExchangeStrategies strategies = ExchangeStrategies.builder()
                .codecs(codecs -> codecs.defaultCodecs().maxInMemorySize(size))
                .build();
        
        return WebClient.builder()
                .exchangeStrategies(strategies)
                .filter(logRequest())
                .filter(logResponse());
    }
    
    /**
     * Create a WebClient for UPI API calls
     * 
     * @param builder the WebClient.Builder
     * @param properties UPI configuration properties
     * @return WebClient for UPI API
     */
    @Bean
    public WebClient upiWebClient(WebClient.Builder builder, UpiProperties properties) {
        HttpClient httpClient = getHttpClient(properties.getTimeout());
        
        return builder
                .baseUrl(properties.getBaseUrl())
                .clientConnector(new ReactorClientHttpConnector(httpClient))
                .defaultHeader("X-API-KEY", properties.getApiKey())
                .build();
    }
    
    /**
     * Create a WebClient for AD Bank API calls
     * 
     * @param builder the WebClient.Builder
     * @param properties AD Bank configuration properties
     * @return WebClient for AD Bank API
     */
    @Bean
    public WebClient adbankWebClient(WebClient.Builder builder, AdbankProperties properties) {
        HttpClient httpClient = getHttpClient(properties.getTimeout());
        
        return builder
                .baseUrl(properties.getBaseUrl())
                .clientConnector(new ReactorClientHttpConnector(httpClient))
                .defaultHeader("Client-ID", properties.getClientId())
                .defaultHeader("Client-Secret", properties.getClientSecret())
                .build();
    }
    
    /**
     * Create a WebClient for Wise API calls
     * 
     * @param builder the WebClient.Builder
     * @param properties Wise configuration properties
     * @return WebClient for Wise API
     */
    @Bean
    public WebClient wiseWebClient(WebClient.Builder builder, WiseProperties properties) {
        HttpClient httpClient = getHttpClient(properties.getTimeout());
        
        return builder
                .baseUrl(properties.getBaseUrl())
                .clientConnector(new ReactorClientHttpConnector(httpClient))
                .defaultHeader("Authorization", "Bearer " + properties.getApiKey())
                .build();
    }
    
    /**
     * Create an HttpClient with configured timeouts
     * 
     * @param timeout the connection timeout
     * @return the configured HttpClient
     */
    private HttpClient getHttpClient(Duration timeout) {
        return HttpClient.create()
                .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, (int) timeout.toMillis())
                .responseTimeout(timeout)
                .doOnConnected(conn -> 
                        conn.addHandlerLast(new ReadTimeoutHandler(timeout.toMillis(), TimeUnit.MILLISECONDS))
                            .addHandlerLast(new WriteTimeoutHandler(timeout.toMillis(), TimeUnit.MILLISECONDS)));
    }
    
    /**
     * Create a filter function to log requests
     * 
     * @return the filter function
     */
    private ExchangeFilterFunction logRequest() {
        return ExchangeFilterFunction.ofRequestProcessor(clientRequest -> {
            if (org.slf4j.LoggerFactory.getLogger(WebClientConfig.class).isDebugEnabled()) {
                StringBuilder sb = new StringBuilder("Request: \n");
                clientRequest.headers().forEach((name, values) -> values.forEach(value -> sb.append(name).append(":").append(value).append("\n")));
                sb.append(clientRequest.url());
                org.slf4j.LoggerFactory.getLogger(WebClientConfig.class).debug(sb.toString());
            }
            return Mono.just(clientRequest);
        });
    }
    
    /**
     * Create a filter function to log responses
     * 
     * @return the filter function
     */
    private ExchangeFilterFunction logResponse() {
        return ExchangeFilterFunction.ofResponseProcessor(clientResponse -> {
            if (org.slf4j.LoggerFactory.getLogger(WebClientConfig.class).isDebugEnabled()) {
                StringBuilder sb = new StringBuilder("Response: \n");
                clientResponse.headers().asHttpHeaders().forEach((name, values) -> values.forEach(value -> sb.append(name).append(":").append(value).append("\n")));
                sb.append("Status: ").append(clientResponse.statusCode());
                org.slf4j.LoggerFactory.getLogger(WebClientConfig.class).debug(sb.toString());
            }
            return Mono.just(clientResponse);
        });
    }
} 