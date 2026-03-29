# Sales Module Documentation

## Overview
The Sales Module is a complete customer sales and payment tracking system for the Jeton executive management platform. It provides comprehensive tools for managing sales transactions, tracking payments, and generating revenue reports.

## Features

### 1. Sales Management
- **Create Sales**: Record new customer sales with product/service details
- **Track Sales**: View all sales with customer information, amounts, and status
- **Update Sales**: Modify sale details (customer info, quantities, prices)
- **Delete Sales**: Remove sales records with cascade deletion of payments
- **Search & Filter**: Find sales by customer name, product, or email
- **Status Tracking**: Automatic status updates (Pending → Partially Paid → Paid)

### 2. Payment Management
- **Record Payments**: Track individual payments against sales
- **Payment Methods**: Support for Cash, Bank Transfer, Mobile Money, and Other
- **Payment History**: View complete payment history per sale
- **Payment Progress**: Visual progress indicator showing payment completion
- **Payment Validation**: Prevent overpayments beyond remaining balance

### 3. Sales Reporting
- **Revenue Metrics**: Total revenue, collected amounts, outstanding balances
- **Collection Rate**: Percentage of revenue collected
- **Sales Summary**: Count of pending, partially paid, and paid sales
- **Product Analysis**: Revenue by product/service
- **Daily Summary**: Daily sales trends
- **Date Filtering**: Filter reports by date range

### 4. Dashboard Integration
- **Revenue Widget**: Display of collected revenue and totals
- **Real-time Updates**: Metrics refresh every 30 seconds
- **Key Metrics**: Total revenue, collection rate, outstanding balance

## Database Schema

### Sales Table
```sql
CREATE TABLE sales (
  id UUID PRIMARY KEY,
  deal_id UUID,           -- Optional link to deals pipeline
  customer_name VARCHAR,  -- Required
  customer_email VARCHAR,
  product_service VARCHAR, -- Required
  quantity INT,           -- Required, must be > 0
  unit_price DECIMAL(19,4), -- Required, must be >= 0
  total_amount DECIMAL(19,2), -- AUTO-CALCULATED: quantity × unit_price
  sale_date TIMESTAMP DEFAULT now(),
  status ENUM('Pending', 'Partially Paid', 'Paid'), -- AUTO-UPDATED
  currency VARCHAR DEFAULT 'UGX',
  notes TEXT,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
```

### Sales Payments Table
```sql
CREATE TABLE sales_payments (
  id UUID PRIMARY KEY,
  sale_id UUID NOT NULL,  -- Foreign key
  amount DECIMAL(19,2),   -- Must be > 0
  payment_date TIMESTAMP DEFAULT now(),
  payment_method ENUM('Cash', 'Bank Transfer', 'Mobile Money', 'Other'),
  notes TEXT,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
```

### Key Indexes
- `sales(customer_name)` - Fast customer search
- `sales(status)` - Filter by payment status
- `sales(sale_date)` - Sort by date
- `sales(deal_id)` - Link to deals
- `sales(created_at)` - Track creation timeline
- `sales_payments(sale_id)` - Find payments for a sale
- `sales_payments(payment_date)` - Payment timeline

### Database Automation
**Trigger: calculate_sales_total**
- Auto-calculates `total_amount = quantity × unit_price`
- Runs before INSERT or UPDATE on sales table

**Trigger: update_sales_status**
- Auto-updates status based on payment sum:
  - If total_paid >= total_amount: "Paid"
  - If total_paid > 0: "Partially Paid"
  - If total_paid = 0: "Pending"
- Runs after INSERT or UPDATE on sales_payments

**Trigger: update_sales_timestamp**
- Auto-updates `updated_at` to current timestamp
- Runs before UPDATE on sales table

**Trigger: update_sales_payments_timestamp**
- Auto-updates `updated_at` to current timestamp
- Runs before UPDATE on sales_payments table

## API Endpoints

### 1. List Sales
**GET** `/api/sales`

#### Query Parameters
- `page` (optional, default: 1) - Page number for pagination
- `limit` (optional, default: 20) - Results per page
- `search` (optional) - Search by customer name, product, or email
- `status` (optional) - Filter by status: "Pending", "Partially Paid", "Paid"
- `startDate` (optional) - Filter sales on or after this date
- `endDate` (optional) - Filter sales before this date

#### Response
```json
{
  "success": true,
  "data": {
    "sales": [
      {
        "id": "uuid",
        "customer_name": "John Doe",
        "customer_email": "john@example.com",
        "product_service": "Consulting",
        "quantity": 5,
        "unit_price": 1000000,
        "total_amount": 5000000,
        "status": "Partially Paid",
        "sale_date": "2024-01-15T10:00:00Z",
        "total_paid": 3000000,
        "remaining_balance": 2000000
      }
    ],
    "page": 1,
    "limit": 20,
    "total": 45,
    "pages": 3
  }
}
```

### 2. Create Sale
**POST** `/api/sales`

#### Request Body
```json
{
  "customer_name": "John Doe",          // Required
  "customer_email": "john@example.com", // Optional
  "product_service": "Consulting",       // Required
  "quantity": 5,                         // Required, > 0
  "unit_price": 1000000,                 // Required, >= 0
  "sale_date": "2024-01-15",            // Optional, defaults to today
  "currency": "UGX",                     // Optional, defaults to UGX
  "notes": "High-value client"          // Optional
}
```

#### Response
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "customer_name": "John Doe",
    "total_amount": 5000000,
    "status": "Pending",
    "total_paid": 0,
    "remaining_balance": 5000000
  }
}
```

### 3. Get Single Sale with Payment History
**GET** `/api/sales/[id]`

#### Response
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "customer_name": "John Doe",
    "product_service": "Consulting",
    "quantity": 5,
    "unit_price": 1000000,
    "total_amount": 5000000,
    "status": "Partially Paid",
    "total_paid": 3000000,
    "remaining_balance": 2000000,
    "payments": [
      {
        "id": "uuid",
        "amount": 2000000,
        "payment_date": "2024-01-20",
        "payment_method": "Bank Transfer",
        "notes": "First installment"
      },
      {
        "id": "uuid",
        "amount": 1000000,
        "payment_date": "2024-01-25",
        "payment_method": "Mobile Money",
        "notes": "Second installment"
      }
    ]
  }
}
```

### 4. Update Sale
**PUT** `/api/sales/[id]`

#### Request Body
```json
{
  "customer_name": "John Doe Updated", // Optional
  "customer_email": "newemail@example.com", // Optional
  "product_service": "Consulting Services", // Optional
  "quantity": 6,                       // Optional
  "unit_price": 1100000,               // Optional
  "sale_date": "2024-01-16",          // Optional
  "currency": "UGX",                   // Optional
  "notes": "Updated notes"             // Optional
}
```

#### Response
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "customer_name": "John Doe Updated",
    "total_amount": 6600000,
    "status": "Pending",
    "total_paid": 3000000,
    "remaining_balance": 3600000
  }
}
```

### 5. Delete Sale
**DELETE** `/api/sales/[id]`

#### Response
```json
{
  "success": true,
  "message": "Sale deleted successfully",
  "data": { "id": "uuid" }
}
```

Note: Deleting a sale cascades to delete all associated payments.

### 6. Add Payment
**POST** `/api/sales/[id]/payment`

#### Request Body
```json
{
  "amount": 2000000,                  // Required, > 0
  "payment_date": "2024-01-20",       // Optional, defaults to today
  "payment_method": "Bank Transfer",  // Optional, defaults to "Other"
  "notes": "First installment"        // Optional
}
```

#### Response
```json
{
  "success": true,
  "data": {
    "payment": {
      "id": "uuid",
      "sale_id": "uuid",
      "amount": 2000000,
      "payment_date": "2024-01-20",
      "payment_method": "Bank Transfer",
      "notes": "First installment"
    },
    "sale": {
      "id": "uuid",
      "status": "Partially Paid",  // Auto-updated
      "total_amount": 5000000,
      "total_paid": 2000000,
      "remaining_balance": 3000000
    }
  }
}
```

### 7. Sales Report
**GET** `/api/sales/report`

#### Query Parameters
- `startDate` (optional) - Filter from this date
- `endDate` (optional) - Filter to this date
- `status` (optional) - Filter by status

#### Response
```json
{
  "success": true,
  "data": {
    "metrics": {
      "total_sales": 25,
      "paid_count": 12,
      "partial_count": 8,
      "pending_count": 5,
      "total_revenue": 125000000,
      "total_collected": 95000000,
      "total_outstanding": 30000000,
      "collection_rate": "76.0"
    },
    "sales": [ /* array of sales */ ],
    "productSummary": [
      {
        "product_service": "Consulting",
        "count": 10,
        "total_quantity": 50,
        "total_revenue": 50000000,
        "total_collected": 40000000
      }
    ],
    "dailySummary": [
      {
        "date": "2024-01-20",
        "count": 3,
        "revenue": 15000000,
        "collected": 10000000
      }
    ]
  }
}
```

## Frontend Components

### Sales Page
**Location**: `src/app/app/sales/page.js`

#### Key Sections
1. **Header** - Title and "New Sale" button
2. **Metrics Cards** - Display KPIs (total revenue, collected, outstanding, collection rate)
3. **Filter Panel** - Search, status filter, date range filters
4. **Sales Table** - Paginated table with actions (view, edit, delete)
5. **Modals**:
   - Add/Edit Sale Form
   - Sale Details with payment history
   - Add Payment Form

#### Features
- Real-time search and filtering
- Pagination with 10 items per page
- Action buttons for view, edit, delete
- Payment progress bars
- Status badges with color coding
- Responsive design with mobile support
- Dark/light mode support

### Key Utilities
**Location**: `src/lib/sales.js`

#### Functions
- `calculateTotalAmount()` - Compute total from quantity and unit price
- `calculateRemainingBalance()` - Compute unpaid amount
- `getStatusColor()` - Return TailwindCSS color classes
- `getStatusBgColor()` - Return background color classes
- `formatPaymentMethod()` - Format payment method with emoji
- `calculatePaymentProgress()` - Get percentage for progress bar
- `getDaysOverdue()` - Calculate days past 30-day payment terms
- `getSaleStatusLabel()` - Get friendly status label
- `formatCurrency()` - Format amount in UGX currency

## Integration Points

### Sidebar Navigation
- Added "Sales" link under Finance submenu
- Location: `src/components/layout/Sidebar.js`

### Dashboard
- Sales Revenue widget showing collected amounts
- Automatic refresh every 30 seconds
- Location: `src/app/app/dashboard/page.js`

### Deal Pipeline
- Optional `deal_id` foreign key links to deals
- Enables tracking sales from specific deals
- Future enhancement: filter sales by deal

## Workflow Examples

### Typical Sales Workflow
1. **Record Sale**: POST `/api/sales` with customer and product details
   - Total amount auto-calculated via database trigger
   - Status defaults to "Pending"

2. **Receive Payment**: POST `/api/sales/[id]/payment`
   - Add first payment
   - Status auto-updates to "Partially Paid"

3. **Add More Payments**: POST `/api/sales/[id]/payment` again
   - Add remaining payment
   - Status auto-updates to "Paid"

4. **View Details**: GET `/api/sales/[id]`
   - See full payment history
   - View remaining balance

5. **Generate Report**: GET `/api/sales/report?startDate=...&endDate=...`
   - View revenue metrics
   - Analyze by product
   - Track daily trends

### Editing Sales
1. Modify sale details: PUT `/api/sales/[id]`
   - Change customer email, quantities, prices
   - Total amount recalculated automatically
   - Status remains unchanged

2. Delete sale: DELETE `/api/sales/[id]`
   - All payments cascade deleted
   - Status permanently removed

## Error Handling

### Common Errors
- **400 Bad Request**: Invalid input (negative quantity, invalid email)
- **404 Not Found**: Sale or payment ID doesn't exist
- **500 Server Error**: Database or server issue

### Validation
- Required fields: customer_name, product_service, quantity, unit_price
- Quantity must be > 0
- Unit price must be >= 0
- Payment amount cannot exceed remaining balance

## Performance Optimizations

### Database Indexes
- Fast queries on customer_name, status, sale_date
- Efficient payment lookups by sale_id
- Quick date range filtering

### Pagination
- Default 20 items per page
- Reduces memory usage and response time
- Smooth user experience

### Aggregation
- Server-side SUM calculations
- Efficient JOIN with sales_payments
- Single query for metrics

## Future Enhancements

1. **Sales Forecasting**
   - Predict revenue trends
   - Forecast outstanding collections

2. **Invoice Generation**
   - Create downloadable invoices
   - Email invoice to customers

3. **Payment Reminders**
   - Auto-send payment reminders
   - Track overdue payments

4. **Bulk Operations**
   - Import sales from CSV
   - Bulk payment recording

5. **Advanced Reporting**
   - Sales by time period (monthly, quarterly, yearly)
   - Customer lifetime value
   - Product profitability analysis

6. **Integration**
   - Sync with accounting software
   - Email notification on payment received
   - SMS reminders for overdue payments

7. **Multi-currency**
   - Support multiple currencies
   - Auto currency conversion
   - Exchange rate tracking

## Testing Checklist

- [ ] Create sale with all required fields
- [ ] Search sales by customer name
- [ ] Filter sales by status
- [ ] Filter sales by date range
- [ ] Pagination works correctly
- [ ] Add payment to sale
- [ ] Status auto-updates to "Partially Paid"
- [ ] Add remaining payment
- [ ] Status auto-updates to "Paid"
- [ ] Cannot add payment exceeding balance
- [ ] Edit sale details
- [ ] Delete sale and verify payments deleted
- [ ] View sale details with payment history
- [ ] Generate report with metrics
- [ ] Dashboard widget updates in real-time
- [ ] Responsive on mobile devices
- [ ] Dark/light mode works

## Troubleshooting

### Sales not appearing
- Check date filter isn't limiting results
- Verify search isn't filtering them out
- Check status filter

### Payment not recording
- Verify payment amount is positive
- Confirm payment amount ≤ remaining balance
- Check sale exists

### Dashboard not updating
- Verify sales/report API is working
- Check browser console for errors
- Refresh page to force update

### Currency display issues
- Check formatCurrency function
- Verify database uses correct precision (19,4)
- Test with different amounts

## Support
For issues or questions about the Sales module, please refer to the main Jeton documentation or contact the development team.
