import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import remittanceService from '@/lib/services/remittance';
import { Currency } from '@/types';

/**
 * POST /api/remittance/payment-webhook
 * 
 * Webhook for UPI payment status updates
 */
export async function POST(req: NextRequest) {
  try {
    // Extract signature from headers
    const signature = req.headers.get('x-upi-signature') || '';
    
    // Parse request body
    const body = await req.json();
    
    // Define schema for validation
    const schema = z.object({
      paymentReference: z.string(),
      transactionId: z.string(),
      status: z.enum(['SUCCESS', 'FAILURE']),
      amount: z.number().positive(),
      currency: z.enum([Currency.INR]),
      upiReferenceId: z.string(),
      timestamp: z.string(),
      metadata: z.record(z.unknown()).optional(),
      failureReason: z.string().optional(),
    });
    
    // Validate request body against schema
    const validatedData = schema.parse(body);
    
    // Process payment webhook
    const result = await remittanceService.processPaymentWebhook(validatedData, signature);
    
    // Return success response
    return NextResponse.json({ 
      status: 'success',
      message: 'Webhook processed successfully',
      transactionId: validatedData.transactionId,
      transactionStatus: result?.status,
    });
  } catch (error) {
    console.error('Error processing payment webhook:', error);
    
    // Handle validation errors
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { 
          error: {
            code: 'VALIDATION_ERROR',
            message: 'Invalid webhook payload',
            details: error.errors,
          }
        }, 
        { status: 400 }
      );
    }
    
    // Handle other errors
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