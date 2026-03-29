# Invoice System - Quick Start Guide

## 5-Minute Setup

### 1. Apply Database Migrations

```bash
# Option A: Using psql directly
psql "postgresql://neondb_owner:npg_HExwNUY6aVP9@ep-small-sound-adgn2dmu-pooler.c-2.us-east-1.aws.neon.tech/xhaira?sslmode=require" << 'EOF'

-- Create invoices table
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    invoice_name VARCHAR(255) NOT NULL,
    client_name VARCHAR(255) NOT NULL,
    client_email VARCHAR(255),
    client_phone VARCHAR(20),
    client_address TEXT,
    company_name VARCHAR(255) DEFAULT 'Xhenvolt Uganda SMC Limited',
    company_address VARCHAR(255) DEFAULT 'Bulubandi, Iganga, Uganda',
    company_service_type VARCHAR(255) DEFAULT 'Software Development & Digital Solutions',
    issue_date TIMESTAMP NOT NULL,
    due_date TIMESTAMP,
    subtotal DECIMAL(15, 2) NOT NULL DEFAULT 0,
    tax DECIMAL(15, 2) NOT NULL DEFAULT 0,
    discount DECIMAL(15, 2) NOT NULL DEFAULT 0,
    total DECIMAL(15, 2) NOT NULL DEFAULT 0,
    amount_paid DECIMAL(15, 2) NOT NULL DEFAULT 0,
    balance_due DECIMAL(15, 2) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    notes TEXT,
    currency VARCHAR(3) DEFAULT 'UGX',
    signed_by VARCHAR(255) DEFAULT 'HAMUZA IBRAHIM',
    signed_by_title VARCHAR(255) DEFAULT 'Chief Executive Officer (CEO)',
    payment_methods TEXT,
    payment_method_used VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT status_check CHECK (status IN ('draft', 'sent', 'paid', 'partially_paid', 'overdue', 'cancelled')),
    CONSTRAINT amounts_valid CHECK (subtotal >= 0 AND tax >= 0 AND discount >= 0 AND total >= 0 AND amount_paid >= 0)
);

CREATE INDEX idx_invoice_number ON invoices(invoice_number);
CREATE INDEX idx_invoice_status ON invoices(status);
CREATE INDEX idx_invoice_client ON invoices(client_name);
CREATE INDEX idx_invoice_created ON invoices(created_at DESC);

-- Create invoice_items table
CREATE TABLE IF NOT EXISTS invoice_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL,
    description TEXT NOT NULL,
    quantity DECIMAL(10, 2) NOT NULL DEFAULT 1,
    unit_price DECIMAL(15, 2) NOT NULL,
    total_price DECIMAL(15, 2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_invoice_items_invoices FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE,
    CONSTRAINT quantity_check CHECK (quantity > 0),
    CONSTRAINT price_check CHECK (unit_price >= 0 AND total_price >= 0)
);

CREATE INDEX idx_invoice_items_invoice_id ON invoice_items(invoice_id);

EOF
```

### 2. Verify Installation

```bash
# Check that tables exist
psql "postgresql://neondb_owner:npg_HExwNUY6aVP9@ep-small-sound-adgn2dmu-pooler.c-2.us-east-1.aws.neon.tech/xhaira?sslmode=require" << 'EOF'
\dt invoices
\dt invoice_items
EOF
```

### 3. Start Development Server

```bash
npm run dev
# Visit http://localhost:3000/invoices
```

---

## Core API Endpoints Reference

### Create Invoice

```bash
curl -X POST http://localhost:3000/api/invoices \
  -H "Content-Type: application/json" \
  -d '{
    "invoiceNumber": "XH/INV/2601/001",
    "invoiceName": "Website Development",
    "clientName": "ABC Company",
    "clientEmail": "contact@abc.com",
    "issueDate": "2026-02-18T00:00:00Z",
    "currency": "UGX",
    "status": "draft",
    "items": [{
      "description": "Website Development",
      "quantity": 1,
      "unitPrice": 5000000,
      "totalPrice": 5000000
    }]
  }'
```

### List Invoices

```bash
curl http://localhost:3000/api/invoices?page=1&limit=20&status=draft
```

### Get Single Invoice

```bash
curl http://localhost:3000/api/invoices/{invoice-id}
```

### Update Invoice

```bash
curl -X PUT http://localhost:3000/api/invoices/{invoice-id} \
  -H "Content-Type: application/json" \
  -d '{
    "clientName": "Updated Client Name",
    "status": "sent"
  }'
```

### Update Invoice Status

```bash
curl -X PUT http://localhost:3000/api/invoices/{invoice-id}/status \
  -H "Content-Type: application/json" \
  -d '{"status": "paid"}'
```

### Delete Invoice

```bash
curl -X DELETE http://localhost:3000/api/invoices/{invoice-id}
```

### Get Statistics

```bash
curl http://localhost:3000/api/invoices/stats
```

### Get Next Invoice Number

```bash
curl http://localhost:3000/api/invoices/next-number?prefix=XH
```

---

## UI Workflows

### Create an Invoice

1. Navigate to `/invoices`
2. Click **"Create Invoice"** button
3. Form auto-populates with next invoice number
4. Add client details
5. Add items with description, quantity, unit price
6. System calculates totals automatically
7. Adjust tax rate and discount if needed
8. Click **"Save as Draft"** or **"Send Invoice"**

### View & Print Invoice

1. Click the **eye icon** on any invoice
2. Use **"Print"** button to print
3. Use **"Download PDF"** button for PDF
4. Browser print dialog: Ctrl+P / Cmd+P

### Manage Invoices

- **Search:** Use top search box by invoice number or client name
- **Filter:** Click status buttons (All, Draft, Sent, etc.)
- **Paginate:** Use Previous/Next buttons
- **Edit:** Click pencil icon
- **Delete:** Click trash icon (requires confirmation)

---

## Database Query Examples

### Get All Invoices for a Client

```sql
SELECT * FROM invoices 
WHERE client_name ILIKE '%client_name%'
ORDER BY created_at DESC;
```

### Get Overdue Invoices

```sql
SELECT * FROM invoices 
WHERE due_date < NOW() 
  AND status != 'paid'
ORDER BY due_date ASC;
```

### Get Total Revenue

```sql
SELECT 
  SUM(total) as total_revenue,
  SUM(amount_paid) as total_paid,
  SUM(balance_due) as pending_revenue
FROM invoices
WHERE status != 'cancelled';
```

### Get Statistics

```sql
SELECT 
  COUNT(*) as total_invoices,
  SUM(CASE WHEN status = 'paid' THEN 1 ELSE 0 END) as paid_count,
  SUM(CASE WHEN status = 'draft' THEN 1 ELSE 0 END) as draft_count,
  SUM(total) as total_amount,
  SUM(amount_paid) as total_paid,
  SUM(balance_due) as total_pending
FROM invoices;
```

### Get Invoice with Items

```sql
SELECT 
  i.*,
  json_agg(
    json_build_object(
      'id', ii.id,
      'description', ii.description,
      'quantity', ii.quantity,
      'unitPrice', ii.unit_price,
      'totalPrice', ii.total_price
    )
  ) as items
FROM invoices i
LEFT JOIN invoice_items ii ON i.id = ii.invoice_id
WHERE i.id = {invoice_id}
GROUP BY i.id;
```

---

## Common Tasks

### Reset Invoice Series

If you want to reset the invoice numbering:

```sql
DELETE FROM invoices WHERE created_at > '2026-02-18';
DELETE FROM invoice_items WHERE created_at > '2026-02-18';
```

### Export All Invoices to CSV

```sql
COPY (
  SELECT i.*, ii.description, ii.quantity, ii.unit_price, ii.total_price
  FROM invoices i
  LEFT JOIN invoice_items ii ON i.id = ii.invoice_id
  ORDER BY i.created_at DESC
)
TO '/tmp/invoices_export.csv' WITH (FORMAT csv, HEADER);
```

### Archive Old Invoices

```sql
-- Create archive table
CREATE TABLE invoices_archive AS
SELECT * FROM invoices
WHERE created_at < '2025-01-01';

-- Delete from main table
DELETE FROM invoices
WHERE created_at < '2025-01-01';
```

---

## Validation Rules

### Invoice Fields
- **Invoice Number:** Max 50 chars, must be unique
- **Client Name:** Required, max 255 chars
- **Amount Fields:** Non-negative decimals
- **Email:** Valid email format (optional)
- **Status:** Must be one of: draft, sent, paid, partially_paid, overdue, cancelled

### Invoice Items
- **Description:** Required, max 500 chars
- **Quantity:** Must be > 0
- **Unit Price:** Must be >= 0
- **At least one item required per invoice**

### Calculations
- Subtotal = SUM(item quantities × unit prices)
- Tax = Subtotal × (tax rate / 100)
- Total = Subtotal + Tax - Discount
- Balance Due = Total - Amount Paid

All calculations are validated server-side.

---

## Status Transitions

```
draft ──→ sent, cancelled
  ↓
sent ──→ paid, partially_paid, overdue, cancelled
  ↓
partially_paid ──→ paid, overdue, sent
  ↓
paid ──→ sent (for reversals)
  ↓
overdue ──→ paid, partially_paid
  ↓
cancelled ──→ draft (to reinstate)
```

---

## Performance Tips

1. **Use pagination:** Don't load all invoices at once
2. **Index frequently searched fields:** Already done
3. **Archive old invoices:** Keep active data small
4. **Use status filters:** Reduce result sets
5. **Cache statistics:** Update periodically
6. **Optimize PDF generation:** Use print-to-PDF instead

---

## Troubleshooting

### "Invoice not found"
- Verify invoice ID exists
- Check spelling of invoice number
- Ensure invoice hasn't been deleted

### "Validation failed"
- Check all required fields are filled
- Verify email format is valid
- Ensure at least one invoice item exists
- Check amount calculations are correct

### "Database connection error"
- Verify DATABASE_URL in .env.local
- Check Neon project is running
- Restart development server
- Check network connection

### "PDF not generating"
- Use browser print function (Ctrl+P)
- Install Puppeteer for true PDF: `npm install puppeteer`
- Check Puppeteer configuration in API route

---

## Next Steps

1. ✅ Create your first invoice
2. ✅ Test printing/downloading
3. ✅ Verify calculations are correct
4. ✅ Test status transitions
5. ✅ Explore statistics dashboard
6. ✅ Deploy to production

---

**Questions?** Check the full documentation in `INVOICE_SYSTEM_COMPLETE.md`
