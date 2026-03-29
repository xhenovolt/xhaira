import { Pool } from 'pg';
import { NextResponse } from 'next/server';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

/**
 * GET /api/payments/convert
 * Convert amount to UGX
 */
export async function GET(req) {
  try {
    const { searchParams } = new URL(req.url);
    const amount = parseFloat(searchParams.get('amount'));
    const currency = searchParams.get('currency') || 'UGX';
    const exchangeRate = searchParams.get('exchange_rate');
    
    if (isNaN(amount)) {
      return NextResponse.json(
        { error: 'Invalid amount' },
        { status: 400 }
      );
    }
    
    // Get conversion rate
    let rate = exchangeRate ? parseFloat(exchangeRate) : null;
    
    if (!rate && currency !== 'UGX') {
      // Query for exchange rate from config (implement as needed)
      const rates = {
        'USD': 3800,
        'EUR': 4200,
        'GBP': 4800,
        'ZAR': 200,
        'KES': 36,
      };
      rate = rates[currency] || 1;
    }
    
    const amountUgx = currency === 'UGX' ? amount : amount * (rate || 1);
    
    return NextResponse.json({
      success: true,
      original_amount: amount,
      currency: currency,
      exchange_rate: rate,
      amount_ugx: amountUgx
    });
  } catch (error) {
    console.error('Error converting currency:', error);
    return NextResponse.json(
      { error: 'Conversion failed' },
      { status: 500 }
    );
  }
}

/**
 * POST /api/payments
 * Create payment with multi-currency support
 */
export async function POST(req) {
  const {
    account_id,
    amount,
    currency,
    exchange_rate,
    description,
    deal_id,
    invoice_id
  } = await req.json();
  
  if (!account_id || !amount) {
    return NextResponse.json(
      { error: 'account_id and amount are required' },
      { status: 400 }
    );
  }
  
  try {
    let amountUgx = amount;
    let finalRate = exchange_rate;
    const finalCurrency = currency || 'UGX';
    
    if (finalCurrency !== 'UGX') {
      if (!finalRate) {
        const rates = {
          'USD': 3800,
          'EUR': 4200,
          'GBP': 4800,
          'ZAR': 200,
          'KES': 36,
        };
        finalRate = rates[finalCurrency] || 1;
      }
      amountUgx = amount * finalRate;
    }
    
    const result = await pool.query(
      `INSERT INTO payments (account_id, amount, currency, exchange_rate, amount_ugx, description, deal_id, invoice_id, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, CURRENT_TIMESTAMP)
       RETURNING *`,
      [account_id, amount, finalCurrency, finalRate, amountUgx, description, deal_id, invoice_id]
    );
    
    return NextResponse.json(result.rows[0], { status: 201 });
  } catch (error) {
    console.error('Error creating payment:', error);
    return NextResponse.json(
      { error: 'Failed to create payment: ' + error.message },
      { status: 500 }
    );
  }
}
