package com.remitservice.api.mapper;

import com.remitservice.api.dto.RecipientDetailsDto;
import com.remitservice.domain.model.RecipientDetails;
import org.springframework.stereotype.Component;

/**
 * Mapper for converting between RecipientDetails domain models and DTOs.
 */
@Component
public class RecipientDetailsMapper {

    /**
     * Maps RecipientDetailsDto to RecipientDetails domain model.
     *
     * @param recipientDetailsDto The recipient details DTO
     * @return RecipientDetails domain model
     */
    public RecipientDetails toEntity(RecipientDetailsDto recipientDetailsDto) {
        if (recipientDetailsDto == null) {
            return null;
        }
        
        return RecipientDetails.builder()
                .name(recipientDetailsDto.getName())
                .accountNumber(recipientDetailsDto.getAccountNumber())
                .bankCode(recipientDetailsDto.getBankCode())
                .bankName(recipientDetailsDto.getBankName())
                .address(recipientDetailsDto.getAddress())
                .city(recipientDetailsDto.getCity())
                .postalCode(recipientDetailsDto.getPostalCode())
                .province(recipientDetailsDto.getProvince())
                .build();
    }

    /**
     * Maps RecipientDetails domain model to RecipientDetailsDto.
     *
     * @param recipientDetails The recipient details entity
     * @return RecipientDetails DTO
     */
    public RecipientDetailsDto toDto(RecipientDetails recipientDetails) {
        if (recipientDetails == null) {
            return null;
        }
        
        return RecipientDetailsDto.builder()
                .name(recipientDetails.getName())
                .accountNumber(recipientDetails.getAccountNumber())
                .bankCode(recipientDetails.getBankCode())
                .bankName(recipientDetails.getBankName())
                .address(recipientDetails.getAddress())
                .city(recipientDetails.getCity())
                .postalCode(recipientDetails.getPostalCode())
                .province(recipientDetails.getProvince())
                .build();
    }
} 