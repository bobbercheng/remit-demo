import { v4 as uuidv4 } from 'uuid';
import config from '@/config';
import { 
  RemittanceTransaction, 
  RemittanceRequest, 
  RemittanceResponse, 
  RemittanceStatus,
  Currency,
  UpiWebhookPayload,
  WiseTransferRequest
} from '@/types';
import remittanceRepository from '@/lib/db/repositories/remittance-repository';
import upiIntegration from '@/lib/integrations/upi';
import adBankIntegration from '@/lib/integrations/adbank';
import wiseIntegration from '@/lib/integrations/wise';

/**
 * Remittance Service
 * 
 * Core business logic for remittance operations.
 * Orchestrates the end-to-end remittance process.
 */
export class RemittanceService {
  /**
   * Initialize a new remittance transaction
   * 
   * @param request The remittance request
   */
  async initiateRemittance(request: RemittanceRequest): Promise<RemittanceResponse> {
    try {
      // Validate request
      this.validateRemittanceRequest(request);
      
      // Generate transaction ID
      const transactionId = uuidv4();
      
      // Calculate fees
      const fixedFee = config.fees.fixedFeeInr;
      const percentageFee = (request.sourceAmount * config.fees.percentageFee) / 100;
      const totalFee = fixedFee + percentageFee;
      
      // Get estimated exchange rate and destination amount
      const estimation = await adBankIntegration.calculateEstimatedAmount(request.sourceAmount);
      
      // Create UPI payment request
      const paymentDescription = `Remittance to ${request.recipient.fullName} in Canada`;
      const upiPayment = await upiIntegration.generateUpiPaymentRequest(
        request.sourceAmount + totalFee,
        transactionId,
        paymentDescription
      );
      
      // Create transaction record
      const transaction: RemittanceTransaction = {
        transactionId,
        userId: request.userId,
        status: RemittanceStatus.INITIATED,
        sourceAmount: request.sourceAmount,
        sourceCurrency: request.sourceCurrency,
        destinationCurrency: request.destinationCurrency,
        fees: {
          fixedFee,
          percentageFee,
          totalFee
        },
        recipient: request.recipient,
        paymentMethod: 'UPI',
        purpose: request.purpose,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };
      
      // Save transaction to database
      await remittanceRepository.createTransaction(transaction);
      
      // Prepare response
      const response: RemittanceResponse = {
        transactionId,
        status: RemittanceStatus.INITIATED,
        sourceAmount: request.sourceAmount,
        sourceCurrency: request.sourceCurrency,
        estimatedDestinationAmount: estimation.destinationAmount,
        destinationCurrency: request.destinationCurrency,
        estimatedExchangeRate: estimation.exchangeRate,
        fees: {
          fixedFee,
          percentageFee,
          totalFee
        },
        paymentInstructions: {
          upiId: upiPayment.upiId,
          paymentReference: upiPayment.paymentReference,
          amountToPay: request.sourceAmount + totalFee,
        },
        createdAt: transaction.createdAt,
      };
      
      return response;
    } catch (error) {
      console.error('Error initiating remittance:', error);
      throw error;
    }
  }
  
  /**
   * Process UPI payment webhook
   * 
   * @param payload The webhook payload
   * @param signature The signature from request headers
   */
  async processPaymentWebhook(
    payload: UpiWebhookPayload,
    signature: string
  ): Promise<RemittanceTransaction | null> {
    try {
      // Verify webhook signature
      const isValidSignature = upiIntegration.verifyUpiWebhookSignature(payload, signature);
      if (!isValidSignature) {
        throw new Error('Invalid webhook signature');
      }
      
      // Validate payload
      const isValidPayload = upiIntegration.validateUpiWebhookPayload(payload);
      if (!isValidPayload) {
        throw new Error('Invalid webhook payload');
      }
      
      // Get transaction
      const transaction = await remittanceRepository.getTransactionById(payload.transactionId);
      if (!transaction) {
        throw new Error(`Transaction not found: ${payload.transactionId}`);
      }
      
      // Check if transaction is in correct state
      if (transaction.status !== RemittanceStatus.INITIATED) {
        throw new Error(`Invalid transaction status: ${transaction.status}`);
      }
      
      // Process based on payment status
      if (payload.status === 'SUCCESS') {
        // Update transaction with payment details
        const updatedTransaction = await remittanceRepository.updateTransactionStatus(
          payload.transactionId,
          RemittanceStatus.PAYMENT_RECEIVED,
          {
            upiReferenceId: payload.upiReferenceId,
          }
        );
        
        // Trigger currency conversion
        if (updatedTransaction) {
          await this.processCurrencyConversion(updatedTransaction);
        }
        
        return updatedTransaction;
      } else {
        // Payment failed
        return await remittanceRepository.updateTransactionStatus(
          payload.transactionId,
          RemittanceStatus.FAILED,
          {
            failureReason: payload.failureReason || 'Payment failed',
          }
        );
      }
    } catch (error) {
      console.error('Error processing payment webhook:', error);
      throw error;
    }
  }
  
  /**
   * Process currency conversion
   * 
   * @param transaction The transaction to process
   */
  async processCurrencyConversion(
    transaction: RemittanceTransaction
  ): Promise<RemittanceTransaction | null> {
    try {
      // Convert currency using AD Bank
      const conversionResult = await adBankIntegration.convertCurrency(transaction.sourceAmount);
      
      // Update transaction with conversion details
      const updatedTransaction = await remittanceRepository.updateTransactionStatus(
        transaction.transactionId,
        RemittanceStatus.CURRENCY_CONVERTED,
        {
          exchangeRate: conversionResult.exchangeRate,
          destinationAmount: conversionResult.destinationAmount,
          adBankReferenceId: conversionResult.referenceId,
        }
      );
      
      // Trigger transfer to Canada
      if (updatedTransaction) {
        await this.initiateTransferToCanada(updatedTransaction);
      }
      
      return updatedTransaction;
    } catch (error) {
      console.error('Error processing currency conversion:', error);
      
      // Update transaction status to failed
      await remittanceRepository.updateTransactionStatus(
        transaction.transactionId,
        RemittanceStatus.FAILED,
        {
          failureReason: `Currency conversion failed: ${error.message || 'Unknown error'}`,
        }
      );
      
      throw error;
    }
  }
  
  /**
   * Initiate transfer to Canadian bank account
   * 
   * @param transaction The transaction to process
   */
  async initiateTransferToCanada(
    transaction: RemittanceTransaction
  ): Promise<RemittanceTransaction | null> {
    try {
      // Create transfer request for Wise
      const transferRequest: WiseTransferRequest = {
        sourceAmount: transaction.sourceAmount,
        sourceCurrency: Currency.INR,
        targetCurrency: Currency.CAD,
        targetAccount: {
          accountHolderName: transaction.recipient.fullName,
          accountNumber: transaction.recipient.accountNumber,
          bankCode: transaction.recipient.bankCode,
          address: transaction.recipient.address,
        },
        reference: transaction.transactionId,
      };
      
      // Create transfer using Wise
      const transferResult = await wiseIntegration.createTransfer(transferRequest);
      
      // Update transaction with transfer details
      const updatedTransaction = await remittanceRepository.updateTransactionStatus(
        transaction.transactionId,
        RemittanceStatus.TRANSFER_INITIATED,
        {
          wiseReferenceId: transferResult.transferId,
        }
      );
      
      return updatedTransaction;
    } catch (error) {
      console.error('Error initiating transfer to Canada:', error);
      
      // Update transaction status to failed
      await remittanceRepository.updateTransactionStatus(
        transaction.transactionId,
        RemittanceStatus.FAILED,
        {
          failureReason: `Transfer initiation failed: ${error.message || 'Unknown error'}`,
        }
      );
      
      throw error;
    }
  }
  
  /**
   * Check and update the status of a pending transfer
   * 
   * @param transactionId The transaction ID to check
   */
  async checkTransferStatus(transactionId: string): Promise<RemittanceTransaction | null> {
    try {
      // Get transaction
      const transaction = await remittanceRepository.getTransactionById(transactionId);
      if (!transaction) {
        throw new Error(`Transaction not found: ${transactionId}`);
      }
      
      // Only check status for transactions in TRANSFER_INITIATED state
      if (transaction.status !== RemittanceStatus.TRANSFER_INITIATED || !transaction.wiseReferenceId) {
        return transaction;
      }
      
      // Check status with Wise
      const statusResult = await wiseIntegration.checkTransferStatus(transaction.wiseReferenceId);
      const mappedStatus = wiseIntegration.mapWiseStatus(statusResult.status);
      
      // If status has changed, update the transaction
      if (mappedStatus !== transaction.status) {
        return await remittanceRepository.updateTransactionStatus(
          transactionId,
          mappedStatus as RemittanceStatus,
        );
      }
      
      return transaction;
    } catch (error) {
      console.error('Error checking transfer status:', error);
      throw error;
    }
  }
  
  /**
   * Get transaction details
   * 
   * @param transactionId The transaction ID to retrieve
   */
  async getTransactionDetails(transactionId: string): Promise<RemittanceTransaction | null> {
    try {
      return await remittanceRepository.getTransactionById(transactionId);
    } catch (error) {
      console.error('Error getting transaction details:', error);
      throw error;
    }
  }
  
  /**
   * Get all transactions for a user
   * 
   * @param userId The user ID to retrieve transactions for
   */
  async getUserTransactions(userId: string): Promise<RemittanceTransaction[]> {
    try {
      return await remittanceRepository.getTransactionsByUserId(userId);
    } catch (error) {
      console.error('Error getting user transactions:', error);
      throw error;
    }
  }
  
  /**
   * Validate remittance request
   * 
   * @param request The remittance request to validate
   */
  private validateRemittanceRequest(request: RemittanceRequest): void {
    // Check source amount limits
    if (
      request.sourceAmount < config.transactionLimits.minAmountInr ||
      request.sourceAmount > config.transactionLimits.maxAmountInr
    ) {
      throw new Error(
        `Source amount must be between ${config.transactionLimits.minAmountInr} and ${config.transactionLimits.maxAmountInr} INR`
      );
    }
    
    // Validate recipient info
    if (!request.recipient.fullName || !request.recipient.accountNumber || !request.recipient.bankCode) {
      throw new Error('Recipient information is incomplete');
    }
    
    // Validate currencies
    if (request.sourceCurrency !== Currency.INR || request.destinationCurrency !== Currency.CAD) {
      throw new Error('Only INR to CAD remittances are supported');
    }
  }
}

// Export a singleton instance
export const remittanceService = new RemittanceService();
export default remittanceService; 