package com.remitservice.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * DTO for error responses in API.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ErrorResponseDto {
    
    /**
     * Error code
     */
    private String code;
    
    /**
     * Error message
     */
    private String message;
    
    /**
     * Timestamp when error occurred
     */
    private LocalDateTime timestamp;
    
    /**
     * Request path
     */
    private String path;
    
    /**
     * Additional error details
     */
    private Map<String, Object> details;
} 