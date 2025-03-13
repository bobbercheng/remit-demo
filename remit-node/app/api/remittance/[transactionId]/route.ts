import { NextRequest, NextResponse } from 'next/server';
import remittanceService from '@/lib/services/remittance';

/**
 * GET /api/remittance/[transactionId]
 * 
 * Get details of a specific remittance transaction
 */
export async function GET(
  req: NextRequest,
  { params }: { params: { transactionId: string } }
) {
  try {
    const { transactionId } = params;
    
    // Check if transactionId is valid
    if (!transactionId) {
      return NextResponse.json(
        { 
          error: {
            code: 'INVALID_PARAMETER',
            message: 'Transaction ID is required',
          }
        }, 
        { status: 400 }
      );
    }
    
    // Get transaction details
    const transaction = await remittanceService.getTransactionDetails(transactionId);
    
    // If transaction not found
    if (!transaction) {
      return NextResponse.json(
        { 
          error: {
            code: 'NOT_FOUND',
            message: `Transaction with ID ${transactionId} not found`,
          }
        }, 
        { status: 404 }
      );
    }
    
    // Return success response
    return NextResponse.json(transaction);
  } catch (error) {
    console.error(`Error fetching transaction ${params.transactionId}:`, error);
    
    // Handle errors
    return NextResponse.json(
      { 
        error: {
          code: 'INTERNAL_SERVER_ERROR',
          message: error instanceof Error ? error.message : 'An unexpected error occurred',
        }
      }, 
      { status: 500 }
    );
  }
}

/**
 * PATCH /api/remittance/[transactionId]
 * 
 * Check and update the status of a transaction
 */
export async function PATCH(
  req: NextRequest,
  { params }: { params: { transactionId: string } }
) {
  try {
    const { transactionId } = params;
    
    // Check if transactionId is valid
    if (!transactionId) {
      return NextResponse.json(
        { 
          error: {
            code: 'INVALID_PARAMETER',
            message: 'Transaction ID is required',
          }
        }, 
        { status: 400 }
      );
    }
    
    // Check and update transaction status
    const updatedTransaction = await remittanceService.checkTransferStatus(transactionId);
    
    // If transaction not found
    if (!updatedTransaction) {
      return NextResponse.json(
        { 
          error: {
            code: 'NOT_FOUND',
            message: `Transaction with ID ${transactionId} not found`,
          }
        }, 
        { status: 404 }
      );
    }
    
    // Return success response
    return NextResponse.json(updatedTransaction);
  } catch (error) {
    console.error(`Error updating transaction ${params.transactionId}:`, error);
    
    // Handle errors
    return NextResponse.json(
      { 
        error: {
          code: 'INTERNAL_SERVER_ERROR',
          message: error instanceof Error ? error.message : 'An unexpected error occurred',
        }
      }, 
      { status: 500 }
    );
  }
} 