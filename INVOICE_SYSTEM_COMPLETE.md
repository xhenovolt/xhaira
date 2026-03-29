# Complete Invoice System Documentation

## Overview

A production-ready invoice management system integrated with Neon PostgreSQL database. Supports creating, managing, viewing, printing, and downloading invoices with automatic calculations and professional templates.

**Key Features:**
- 📋 Full invoice CRUD operations
- 📊 Real-time statistics dashboard
- 🖨️ Print & PDF export capabilities
- ✅ Automatic calculations (subtotal, tax, discount, balance)
- 📱 Responsive design for all devices
- 🔒 Data validation and error handling
- 🗂️ Clean database architecture with proper indexing
- 🚀 Scalable API design
- 💾 Persistent storage in Neon PostgreSQL

---

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Database Design](#database-design)
3. [API Routes](#api-routes)
4. [Components](#components)
5. [Setup Instructions](#setup-instructions)
6. [Usage Guide](#usage-guide)
7. [Deployment Guide](#deployment-guide)
8. [Troubleshooting](#troubleshooting)

---

## System Architecture

### Technology Stack
- **Frontend:** React 19, Next.js 16, TailwindCSS
- **Backend:** Next.js API Routes
- **Database:** Neon PostgreSQL
- **Validation:** Zod
- **Package Manager:** npm

### Directory Structure

```
project-root/
├── migrations/
│   ├── 006_create_invoices_table.sql
│   └── 007_create_invoice_items_table.sql
├── src/
│   ├── app/
│   │   ├── api/
│   │   │   └── invoices/
│   │   │       ├── route.js (GET all, POST create)
│   │   │       ├── [id]/
│   │   │       │   ├── route.js (GET, PUT, DELETE)
│   │   │       │   ├── status/
│   │   │       │   │   └── route.js (PUT status)
│   │   │       │   ├── items/
│   │   │       │   │   └── route.js (PUT items)
│   │   │       │   └── pdf/
│   │   │       │       └── route.js (GET PDF)
│   │   │       ├── number/
│   │   │       │   └── [number]/
│   │   │       │       └── route.js (GET by number)
│   │   │       ├── next-number/
│   │   │       │   └── route.js (GET next)
│   │   │       └── stats/
│   │   │           └── route.js (GET stats)
│   │   ├── invoices/
│   │   │   ├── page.js (Main management page)
│   │   │   ├── [id]/
│   │   │   │   ├── view/
│   │   │   │   │   └── page.js
│   │   │   │   ├── edit/
│   │   │   │   │   └── page.js
│   │   │   │   └── print/
│   │   │   │       └── page.js
│   │   └── layout.js
│   ├── lib/
│   │   ├── db-invoices.js (Database functions)
│   │   └── invoice-validation.js (Validation schemas)
│   └── components/
│       └── invoice/
│           ├── InvoiceList.jsx (Main list component)
│           ├── InvoiceList.css
│           ├── InvoiceForm.jsx (Create/edit form)
│           ├── InvoiceForm.css
│           ├── InvoiceTemplate.jsx (Display template)
│           └── InvoiceTemplate.css
├── package.json
├── next.config.mjs
└── .env.local
```

---

## Database Design

### Tables

#### `invoices` Table

Stores invoice metadata and summary information.

```sql
-- Key Columns:
id              UUID PRIMARY KEY
invoice_number  VARCHAR(50) UNIQUE NOT NULL -- e.g., "XH/INV/2601/001"
invoice_name    VARCHAR(255) NOT NULL       -- Project name/title
client_name     VARCHAR(255) NOT NULL
client_email    VARCHAR(255)
client_phone    VARCHAR(20)
client_address  TEXT
company_name    VARCHAR(255)
company_address VARCHAR(255)
issue_date      TIMESTAMP NOT NULL
due_date        TIMESTAMP
subtotal        DECIMAL(15,2)
tax             DECIMAL(15,2)
discount        DECIMAL(15,2)
total           DECIMAL(15,2)
amount_paid     DECIMAL(15,2)
balance_due     DECIMAL(15,2)
status          VARCHAR(20) -- draft, sent, paid, partially_paid, overdue, cancelled
currency        VARCHAR(3) -- e.g., UGX, USD
created_at      TIMESTAMP NOT NULL
updated_at      TIMESTAMP NOT NULL
```

**Indexes:**
- `invoice_number` - Fast lookup by invoice number
- `status` - Quick filtering by status
- `client_name` - Search by client
- `created_at` - Sorting and pagination
- `due_date` - Tracking overdue invoices

#### `invoice_items` Table

Stores individual line items for each invoice.

```sql
-- Key Columns:
id              UUID PRIMARY KEY
invoice_id      UUID NOT NULL FOREIGN KEY → invoices(id) ON DELETE CASCADE
description     TEXT NOT NULL
quantity        DECIMAL(10,2)
unit_price      DECIMAL(15,2)
total_price     DECIMAL(15,2)
created_at      TIMESTAMP NOT NULL
updated_at      TIMESTAMP NOT NULL
```

**Constraints:**
- Foreign key relationship ensures referential integrity
- Cascading delete removes items when invoice is deleted
- Check constraints validate positive quantities and prices

---

## API Routes

### Invoice Management

#### GET `/api/invoices`
Fetch all invoices with pagination

**Parameters:**
- `page` (int, default: 1)
- `limit` (int, default: 20, max: 100)
- `status` (string, optional) - Filter by status

**Response:**
```json
{
  "success": true,
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 50,
    "totalPages": 3,
    "hasMore": true
  }
}
```

#### POST `/api/invoices`
Create a new invoice

**Request Body:**
```json
{
  "invoiceNumber": "XH/INV/2601/001",
  "invoiceName": "Project Name",
  "clientName": "Client Name",
  "clientEmail": "client@example.com",
  "clientPhone": "+256...",
  "clientAddress": "Address",
  "issueDate": "2026-02-18T00:00:00Z",
  "dueDate": "2026-03-18T00:00:00Z",
  "currency": "UGX",
  "status": "draft",
  "notes": "Optional notes",
  "items": [
    {
      "description": "Service description",
      "quantity": 1,
      "unitPrice": 1000000,
      "totalPrice": 1000000
    }
  ]
}
```

#### GET `/api/invoices/[id]`
Fetch a single invoice with items

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "invoice_number": "XH/INV/2601/001",
    ...invoice fields...,
    "items": [...]
  }
}
```

#### PUT `/api/invoices/[id]`
Update an invoice

**Request Body:** Same as create (partial fields accepted)

#### DELETE `/api/invoices/[id]`
Delete an invoice (cascades to items)

#### PUT `/api/invoices/[id]/status`
Update invoice status

**Request Body:**
```json
{
  "status": "sent"
}
```

#### PUT `/api/invoices/[id]/items`
Update invoice items

**Request Body:**
```json
{
  "items": [
    {
      "description": "...",
      "quantity": 1,
      "unitPrice": 1000000,
      "totalPrice": 1000000
    }
  ]
}
```

#### GET `/api/invoices/number/[number]`
Fetch invoice by invoice number

#### GET `/api/invoices/next-number`
Get the next invoice number to use

**Parameters:**
- `prefix` (string, default: "XH")

**Response:**
```json
{
  "success": true,
  "data": {
    "nextInvoiceNumber": "XH/INV/2601/001",
    "prefix": "XH"
  }
}
```

#### GET `/api/invoices/stats`
Get invoice statistics

**Response:**
```json
{
  "success": true,
  "data": {
    "total_invoices": 50,
    "paid_count": 15,
    "draft_count": 10,
    "sent_count": 20,
    "partially_paid_count": 5,
    "overdue_count": 3,
    "total_amount": 50000000,
    "total_paid": 20000000,
    "total_pending": 30000000
  }
}
```

#### GET `/api/invoices/[id]/pdf`
Download invoice as PDF/HTML

---

## Components

### InvoiceList.jsx
Main invoice management component
- List all invoices with filtering
- Display statistics
- Quick actions (view, edit, delete, print, download)
- Pagination support
- Search functionality

### InvoiceForm.jsx
Create and edit invoice form
- Dynamic item management
- Real-time calculations
- Form validation
- Error handling
- Auto-saving as draft or sending

### InvoiceTemplate.jsx
Invoice display/print template
- Professional layout
- QR code generation
- Payment method display
- Print-optimized styling
- Responsive design

---

## Setup Instructions

### 1. Database Setup

Run migrations in Neon to create tables:

```bash
# Using psql (install if needed)
psql -h ep-small-sound-adgn2dmu-pooler.c-2.us-east-1.aws.neon.tech \
     -U neondb_owner \
     -d jeton \
     -f migrations/006_create_invoices_table.sql

psql -h ep-small-sound-adgn2dmu-pooler.c-2.us-east-1.aws.neon.tech \
     -U neondb_owner \
     -d jeton \
     -f migrations/007_create_invoice_items_table.sql
```

Or use Neon console to run SQL directly.

### 2. Dependencies

All required dependencies are in `package.json`. If missing:

```bash
npm install pg zod
```

### 3. Environment Variables

Already configured in `.env.local` (verify):

```env
DATABASE_URL='postgresql://neondb_owner:npg_HExwNUY6aVP9@ep-small-sound-adgn2dmu-pooler.c-2.us-east-1.aws.neon.tech/jeton?sslmode=require&channel_binding=require'
```

### 4. QR Code Library

Add to `[root]/src/app/layout.js` or relevant layout:

```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>
```

### 5. Start Development Server

```bash
npm run dev
```

Access at: `http://localhost:3000/invoices`

---

## Usage Guide

### Creating an Invoice

1. Navigate to `/invoices`
2. Click "Create Invoice" button
3. Fill in invoice details:
   - Invoice number (auto-generated)
   - Client information
   - Invoice items (add multiple with "Add Item" button)
4. System auto-calculates totals
5. Save as draft or send
6. Adjust tax rate and discount as needed

### Managing Invoices

- **View:** Click eye icon to see full invoice
- **Edit:** Click edit icon (pencil) to modify
- **Print:** Click print icon to print invoice
- **Download:** Click download icon for PDF/HTML
- **Delete:** Click trash icon to remove
- **Change Status:** Use dropdown in status column

### Filtering & Search

- Use status buttons to filter by status (All, Draft, Sent, etc.)
- Search by invoice number or client name
- Pagination for large lists

### Invoice Statuses

- **Draft:** Not yet sent to client
- **Sent:** Sent to client, awaiting payment
- **Partially Paid:** Payment received but balance remains
- **Paid:** Fully paid
- **Overdue:** Due date passed, not paid
- **Cancelled:** No longer valid

---

## Deployment Guide

### Production Checklist

- [ ] Database migrations applied to production Neon instance
- [ ] Environment variables configured
- [ ] QR code library added to layout
- [ ] PDF export tested (optional: configure Puppeteer)
- [ ] Email notifications configured (if needed)
- [ ] Backup strategy implemented
- [ ] SSL/TLS enabled
- [ ] Error logging configured

### Deploy to Production (Vercel)

```bash
# Push to GitHub
git add .
git commit -m "feat: complete invoice system"
git push

# Vercel auto-deploys from main branch
# Or manually:
vercel --prod
```

### Key Configuration for Vercel

```env
# In Vercel project settings → Environment Variables
DATABASE_URL=<your_neon_connection_string>
NODE_ENV=production
```

---

## Troubleshooting

### Database Connection Issues

**Error:** `connect ECONNREFUSED`

**Solution:**
1. Verify DATABASE_URL in `.env.local`
2. Check Neon project status
3. Restart development server

### QR Code Not Showing

**Solution:**
1. Ensure qrcodejs library is loaded
2. Check browser console for errors
3. Verify `qrRef` element exists

### Invoice Not Saving

**Solution:**
1. Check form validation errors
2. Verify database connection
3. Check browser network tab for API response
4. Review server logs

### PDF Download Issues

**Solution:**
1. For PDF generation: install Puppeteer (`npm install puppeteer`)
2. Uncomment PDF generation code in `/api/invoices/[id]/pdf/route.js`
3. For HTML print-to-PDF: use browser's print dialog (Ctrl+P / Cmd+P)

### Pagination Not Working

**Solution:**
1. Verify `page` and `limit` parameters in URL
2. Check totalPages calculation
3. Ensure LIMIT and OFFSET in SQL query

---

## Performance Optimization

### Database Optimization

- Indexes on frequently queried columns already created
- Foreign key constraints ensure data integrity
- Cascading deletes prevent orphaned records

### Frontend Optimization

- Lazy load components with Next.js dynamic imports
- Pagination prevents loading all invoices at once
- CSS modules for scoped styling
- Memoization in form handlers

### API Optimization

- Response pagination (default 20 items per page)
- Indexed queries for fast lookups
- Efficient SQL with proper joins
- Error handling prevents cascading failures

---

## Future Enhancements

1. **Email Integration:** Send invoices via email
2. **Payment Integration:** Accept online payments
3. **Multi-currency Support:** Real-time exchange rates
4. **Recurring Invoices:** Automatic invoice generation
5. **Client Portal:** Clients view/pay invoices
6. **Advanced Reports:** Financial analytics
7. **Multi-user Support:** Team collaboration
8. **Invoice Templates:** Custom designs
9. **SMS Notifications:** Status updates
10. **Audit Trail:** Track all changes

---

## Support & Maintenance

### Regular Maintenance

- Monitor database growth
- Archive old invoices when needed
- Review and optimize slow queries
- Keep Next.js and dependencies updated

### Backup Strategy

```bash
# Neon automatically backs up daily
# Export important invoices periodically:
SELECT * INTO OUTFILE 'invoices_backup_2026_02_18.csv'
FROM invoices;
```

### Monitoring

- Monitor API response times
- Track error rates
- Monitor database connection pool
- Set up alerts for failed operations

---

## License & Credits

Built with Next.js, React, and Neon PostgreSQL.
Based on professional invoice template design.

**Created:** February 18, 2026
**Version:** 1.0.0

---

For more help, check the inline code comments or review the component implementations.
