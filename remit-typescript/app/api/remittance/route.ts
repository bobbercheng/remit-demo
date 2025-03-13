import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import remittanceService from '@/lib/services/remittance';
import { Currency } from '@/types';

/**
 * POST /api/remittance
 * 
 * Create a new remittance transaction from India to Canada
 */
export async function POST(req: NextRequest) {
  try {
    // Parse and validate request body
    const body = await req.json();
    
    // Define schema for validation
    const schema = z.object({
      userId: z.string().min(1),
      sourceAmount: z.number().positive(),
      sourceCurrency: z.enum([Currency.INR]),
      destinationCurrency: z.enum([Currency.CAD]),
      recipient: z.object({
        fullName: z.string().min(1),
        accountNumber: z.string().min(1),
        bankName: z.string().min(1),
        bankCode: z.string().min(1),
        address: z.string().optional(),
        email: z.string().email().optional(),
        phone: z.string().optional(),
      }),
      purpose: z.string().optional(),
    });
    
    // Validate request body against schema
    const validatedData = schema.parse(body);
    
    // Initialize remittance
    const result = await remittanceService.initiateRemittance(validatedData);
    
    // Return success response
    return NextResponse.json(result, { status: 201 });
  } catch (error) {
    console.error('Error creating remittance:', error);
    
    // Handle validation errors
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { 
          error: {
            code: 'VALIDATION_ERROR',
            message: 'Invalid request data',
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

/**
 * GET /api/remittance
 * 
 * Get all remittances for a user
 */
export async function GET(req: NextRequest) {
  try {
    // Get userId from query parameter
    const userId = req.nextUrl.searchParams.get('userId');
    
    if (!userId) {
      return NextResponse.json(
        { 
          error: {
            code: 'MISSING_PARAMETER',
            message: 'userId is required',
          }
        }, 
        { status: 400 }
      );
    }
    
    // Get remittances for the user
    const remittances = await remittanceService.getUserTransactions(userId);
    
    // Return success response
    return NextResponse.json({ remittances });
  } catch (error) {
    console.error('Error fetching remittances:', error);
    
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