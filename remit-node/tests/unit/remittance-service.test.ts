import { v4 as uuidv4 } from 'uuid';
import { RemittanceService } from '@/lib/services/remittance';
import remittanceRepository from '@/lib/db/repositories/remittance-repository';
import upiIntegration from '@/lib/integrations/upi';
import adBankIntegration from '@/lib/integrations/adbank';
import wiseIntegration from '@/lib/integrations/wise';
import { 
  RemittanceRequest, 
  RemittanceStatus, 
  Currency,
  UpiWebhookPayload
} from '@/types';

// Mock dependencies
jest.mock('@/lib/db/repositories/remittance-repository');
jest.mock('@/lib/integrations/upi');
jest.mock('@/lib/integrations/adbank');
jest.mock('@/lib/integrations/wise');
jest.mock('uuid');

describe('RemittanceService', () => {
  let remittanceService: RemittanceService;
  
  // Sample data for tests
  const mockTransactionId = '123e4567-e89b-12d3-a456-426614174000';
  const mockUserId = 'user-123';
  
  const mockRemittanceRequest: RemittanceRequest = {
    userId: mockUserId,
    sourceAmount: 50000,
    sourceCurrency: Currency.INR,
    destinationCurrency: Currency.CAD,
    recipient: {
      fullName: 'John Doe',
      accountNumber: '123456789',
      bankName: 'Royal Bank of Canada',
      bankCode: '00123-003',
      address: '123 Maple Street, Toronto, ON',
      email: 'john.doe@example.com',
      phone: '+1 123-456-7890',
    },
    purpose: 'Family support',
  };
  
  const mockUpiPaymentResponse = {
    paymentId: 'payment-123',
    upiId: 'payment@upi',
    paymentReference: 'RM-123456',
    status: 'PENDING',
    expiresAt: '2023-11-20T10:30:00Z',
  };
  
  const mockEstimatedAmount = {
    destinationAmount: 810,
    exchangeRate: 0.0162,
    fees: 300,
  };
  
  const mockWebhookPayload: UpiWebhookPayload = {
    paymentReference: 'RM-123456',
    transactionId: mockTransactionId,
    status: 'SUCCESS',
    amount: 50300,
    currency: Currency.INR,
    upiReferenceId: 'UPI-12345',
    timestamp: '2023-11-20T09:00:00Z',
  };
  
  const mockConversionResponse = {
    sourceCurrency: Currency.INR,
    destinationCurrency: Currency.CAD,
    sourceAmount: 50000,
    destinationAmount: 810,
    exchangeRate: 0.0162,
    fees: 0,
    referenceId: 'ADBANK-67890',
    timestamp: '2023-11-20T09:15:00Z',
  };
  
  const mockWiseTransferResponse = {
    transferId: 'WISE-54321',
    status: 'processing',
    estimatedDeliveryTime: '2023-11-21T12:00:00Z',
    trackingUrl: 'https://wise.com/track/WISE-54321',
  };
  
  beforeEach(() => {
    jest.clearAllMocks();
    remittanceService = new RemittanceService();
    
    // Mock UUID generation
    (uuidv4 as jest.Mock).mockReturnValue(mockTransactionId);
    
    // Mock UPI integration
    (upiIntegration.generateUpiPaymentRequest as jest.Mock).mockResolvedValue(mockUpiPaymentResponse);
    (upiIntegration.verifyUpiWebhookSignature as jest.Mock).mockReturnValue(true);
    (upiIntegration.validateUpiWebhookPayload as jest.Mock).mockReturnValue(true);
    
    // Mock AD Bank integration
    (adBankIntegration.calculateEstimatedAmount as jest.Mock).mockResolvedValue(mockEstimatedAmount);
    (adBankIntegration.convertCurrency as jest.Mock).mockResolvedValue(mockConversionResponse);
    
    // Mock Wise integration
    (wiseIntegration.createTransfer as jest.Mock).mockResolvedValue(mockWiseTransferResponse);
    (wiseIntegration.checkTransferStatus as jest.Mock).mockResolvedValue({
      status: 'processing',
      trackingUrl: 'https://wise.com/track/WISE-54321',
    });
    (wiseIntegration.mapWiseStatus as jest.Mock).mockReturnValue(RemittanceStatus.TRANSFER_INITIATED);
  });
  
  describe('initiateRemittance', () => {
    it('should create a new remittance transaction', async () => {
      // Mock repository
      (remittanceRepository.createTransaction as jest.Mock).mockImplementation(transaction => Promise.resolve(transaction));
      
      // Call the service
      const result = await remittanceService.initiateRemittance(mockRemittanceRequest);
      
      // Verify results
      expect(result).toBeDefined();
      expect(result.transactionId).toBe(mockTransactionId);
      expect(result.status).toBe(RemittanceStatus.INITIATED);
      expect(result.sourceAmount).toBe(mockRemittanceRequest.sourceAmount);
      expect(result.estimatedDestinationAmount).toBe(mockEstimatedAmount.destinationAmount);
      expect(result.estimatedExchangeRate).toBe(mockEstimatedAmount.exchangeRate);
      expect(result.paymentInstructions.upiId).toBe(mockUpiPaymentResponse.upiId);
      
      // Verify interactions
      expect(uuidv4).toHaveBeenCalled();
      expect(adBankIntegration.calculateEstimatedAmount).toHaveBeenCalledWith(mockRemittanceRequest.sourceAmount);
      expect(upiIntegration.generateUpiPaymentRequest).toHaveBeenCalled();
      expect(remittanceRepository.createTransaction).toHaveBeenCalled();
    });
    
    it('should throw an error if amount is outside limits', async () => {
      // Modify request to have invalid amount
      const invalidRequest = {
        ...mockRemittanceRequest,
        sourceAmount: 100, // Below minimum
      };
      
      // Expect error
      await expect(remittanceService.initiateRemittance(invalidRequest))
        .rejects.toThrow(/Source amount must be between/);
      
      // Verify no interactions with external services
      expect(remittanceRepository.createTransaction).not.toHaveBeenCalled();
    });
  });
  
  describe('processPaymentWebhook', () => {
    beforeEach(() => {
      // Mock repository for transaction retrieval
      (remittanceRepository.getTransactionById as jest.Mock).mockResolvedValue({
        transactionId: mockTransactionId,
        status: RemittanceStatus.INITIATED,
        // Other fields not relevant for this test
      });
      
      // Mock repository for status update
      (remittanceRepository.updateTransactionStatus as jest.Mock).mockImplementation(
        (transactionId, status, additionalFields) => Promise.resolve({
          transactionId,
          status,
          ...additionalFields,
        })
      );
    });
    
    it('should process a successful payment webhook', async () => {
      // Call the service
      const result = await remittanceService.processPaymentWebhook(
        mockWebhookPayload,
        'valid-signature'
      );
      
      // Verify results
      expect(result).toBeDefined();
      expect(result?.status).toBe(RemittanceStatus.PAYMENT_RECEIVED);
      expect(result?.upiReferenceId).toBe(mockWebhookPayload.upiReferenceId);
      
      // Verify interactions
      expect(upiIntegration.verifyUpiWebhookSignature).toHaveBeenCalledWith(
        mockWebhookPayload,
        'valid-signature'
      );
      expect(upiIntegration.validateUpiWebhookPayload).toHaveBeenCalledWith(mockWebhookPayload);
      expect(remittanceRepository.getTransactionById).toHaveBeenCalledWith(mockTransactionId);
      expect(remittanceRepository.updateTransactionStatus).toHaveBeenCalledWith(
        mockTransactionId,
        RemittanceStatus.PAYMENT_RECEIVED,
        { upiReferenceId: mockWebhookPayload.upiReferenceId }
      );
    });
    
    it('should handle a failed payment webhook', async () => {
      // Modify webhook payload for failure
      const failedPayload = {
        ...mockWebhookPayload,
        status: 'FAILURE' as const,
        failureReason: 'Insufficient funds',
      };
      
      // Call the service
      const result = await remittanceService.processPaymentWebhook(
        failedPayload,
        'valid-signature'
      );
      
      // Verify results
      expect(result).toBeDefined();
      expect(result?.status).toBe(RemittanceStatus.FAILED);
      expect(result?.failureReason).toBe(failedPayload.failureReason);
      
      // Verify interactions
      expect(remittanceRepository.updateTransactionStatus).toHaveBeenCalledWith(
        mockTransactionId,
        RemittanceStatus.FAILED,
        { failureReason: failedPayload.failureReason }
      );
    });
    
    it('should throw an error if signature is invalid', async () => {
      // Mock invalid signature
      (upiIntegration.verifyUpiWebhookSignature as jest.Mock).mockReturnValue(false);
      
      // Expect error
      await expect(remittanceService.processPaymentWebhook(
        mockWebhookPayload,
        'invalid-signature'
      )).rejects.toThrow('Invalid webhook signature');
      
      // Verify no updates
      expect(remittanceRepository.updateTransactionStatus).not.toHaveBeenCalled();
    });
  });
  
  describe('checkTransferStatus', () => {
    it('should check and update transfer status if needed', async () => {
      // Mock repository for transaction retrieval
      (remittanceRepository.getTransactionById as jest.Mock).mockResolvedValue({
        transactionId: mockTransactionId,
        status: RemittanceStatus.TRANSFER_INITIATED,
        wiseReferenceId: 'WISE-54321',
      });
      
      // Mock Wise status to be different (completed)
      (wiseIntegration.mapWiseStatus as jest.Mock).mockReturnValue(RemittanceStatus.COMPLETED);
      
      // Call the service
      const result = await remittanceService.checkTransferStatus(mockTransactionId);
      
      // Verify results
      expect(result).toBeDefined();
      expect(result?.status).toBe(RemittanceStatus.COMPLETED);
      
      // Verify interactions
      expect(remittanceRepository.getTransactionById).toHaveBeenCalledWith(mockTransactionId);
      expect(wiseIntegration.checkTransferStatus).toHaveBeenCalledWith('WISE-54321');
      expect(remittanceRepository.updateTransactionStatus).toHaveBeenCalledWith(
        mockTransactionId,
        RemittanceStatus.COMPLETED
      );
    });
    
    it('should not update status if it has not changed', async () => {
      // Mock repository for transaction retrieval
      (remittanceRepository.getTransactionById as jest.Mock).mockResolvedValue({
        transactionId: mockTransactionId,
        status: RemittanceStatus.TRANSFER_INITIATED,
        wiseReferenceId: 'WISE-54321',
      });
      
      // Mock Wise status to be the same
      (wiseIntegration.mapWiseStatus as jest.Mock).mockReturnValue(RemittanceStatus.TRANSFER_INITIATED);
      
      // Call the service
      const result = await remittanceService.checkTransferStatus(mockTransactionId);
      
      // Verify results
      expect(result).toBeDefined();
      expect(result?.status).toBe(RemittanceStatus.TRANSFER_INITIATED);
      
      // Verify no update was made
      expect(remittanceRepository.updateTransactionStatus).not.toHaveBeenCalled();
    });
  });
}); 