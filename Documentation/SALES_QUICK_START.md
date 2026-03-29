# Sales Module - Quick Start Guide

## Overview
The Sales Module is now fully implemented and ready to use. It provides complete customer sales and payment tracking with automatic status updates and comprehensive reporting.

## Quick Access

### View Sales
1. Click "Sales" in the Finance submenu (Sidebar)
2. View all sales in a paginated table
3. Search by customer name, product, or email
4. Filter by status (Pending, Partially Paid, Paid)
5. Filter by date range

### Create New Sale
1. Click "New Sale" button in header
2. Fill in customer details (required: name, product, quantity, unit price)
3. Optional: add email, notes
4. Click "Add Sale"
5. Total amount auto-calculates

### Record Payment
1. Click eye icon to view sale details
2. Click "Add Payment" button
3. Enter payment amount (max: remaining balance)
4. Select payment method
5. Optional: add notes
6. Click "Record Payment"
7. Status auto-updates:
   - Pending → Partially Paid (after first payment)
   - Partially Paid → Paid (when fully paid)

### Edit Sale
1. Click pencil icon on sale row
2. Modify details
3. Click "Update Sale"
4. Total recalculated if quantity or price changed

### Delete Sale
1. Click trash icon on sale row
2. Confirm deletion
3. All payments cascade deleted

### View Reports
Reports automatically show:
- Total revenue and collected amounts
- Outstanding balance
- Collection rate percentage
- Breakdown by status
- Revenue by product
- Daily sales trends

## Key Features

### Automatic Calculations
- Total amount = quantity × unit price (auto-calculated)
- Status updates automatically based on payments
- Remaining balance = total amount - total paid
- Collection rate = (total paid / total revenue) × 100%

### Filtering & Search
- Search across customer name, product, and email
- Filter by payment status
- Filter by date range
- Pagination with 10 items per page

### Payment Management
- Track multiple payments per sale
- View full payment history
- Prevent overpayments
- Support multiple payment methods

### Dashboard Widget
- Sales revenue widget on main dashboard
- Shows total revenue, collected, outstanding
- Real-time updates every 30 seconds

## Database Auto-Updates

The database automatically:
1. **Calculates total_amount** from quantity × unit_price
2. **Updates status** based on payment sum:
   - Total paid = 0 → Pending
   - Total paid > 0 and < total → Partially Paid
   - Total paid ≥ total → Paid
3. **Updates timestamps** on any modification

## API Reference (Quick)

### List Sales
```
GET /api/sales?page=1&limit=20&search=customer&status=Pending&startDate=2024-01-01&endDate=2024-12-31
```

### Create Sale
```
POST /api/sales
{
  "customer_name": "John Doe",
  "customer_email": "john@example.com",
  "product_service": "Consulting",
  "quantity": 5,
  "unit_price": 1000000,
  "notes": "Optional notes"
}
```

### Add Payment
```
POST /api/sales/[id]/payment
{
  "amount": 2000000,
  "payment_method": "Bank Transfer",
  "notes": "First installment"
}
```

### Get Report
```
GET /api/sales/report?startDate=2024-01-01&endDate=2024-12-31
```

## Field Specifications

### Sales Fields
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| customer_name | String | Yes | Customer/company name |
| customer_email | String | No | Customer email address |
| product_service | String | Yes | What was sold |
| quantity | Number | Yes | Must be > 0 |
| unit_price | Decimal | Yes | Price per unit (UGX) |
| total_amount | Decimal | Auto | quantity × unit_price |
| sale_date | Date | No | Defaults to today |
| status | Enum | Auto | Pending/Partially Paid/Paid |
| currency | String | No | Defaults to UGX |
| notes | Text | No | Optional notes |

### Payment Fields
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| amount | Decimal | Yes | Must be > 0 and ≤ remaining balance |
| payment_date | Date | No | Defaults to today |
| payment_method | Enum | No | Cash/Bank Transfer/Mobile Money/Other |
| notes | Text | No | Optional payment notes |

## Common Workflows

### Workflow 1: Full Payment on Sale
1. Create sale: 10 units × 100,000 = 1,000,000 UGX
2. Record payment: 1,000,000 UGX
3. Status auto-updates to "Paid"

### Workflow 2: Installment Payments
1. Create sale: 5 units × 500,000 = 2,500,000 UGX (status: Pending)
2. Record payment: 1,000,000 UGX (status: Partially Paid)
3. Record payment: 1,000,000 UGX (status: Partially Paid)
4. Record payment: 500,000 UGX (status: Paid)

### Workflow 3: Correction
1. Create sale with wrong quantity
2. Click edit (pencil icon)
3. Change quantity
4. Total auto-recalculates
5. Save changes

## Error Messages

| Error | Meaning | Solution |
|-------|---------|----------|
| "Quantity must be positive" | Qty ≤ 0 | Enter qty > 0 |
| "Unit price must be non-negative" | Price < 0 | Enter price ≥ 0 |
| "Payment cannot exceed remaining balance" | Overpayment attempted | Reduce payment amount |
| "Sale not found" | Invalid sale ID | Sale may be deleted |
| "Please fill in all required fields" | Missing required field | Check: name, product, qty, price |

## Tips & Tricks

1. **Bulk Review**: Use date range filter to review period sales
2. **Customer Analysis**: Search by customer name to see all their sales
3. **Product Performance**: Check product revenue in reports
4. **Outstanding Tracking**: Filter by "Pending" to see unpaid sales
5. **Payment Deadlines**: Sales have 30 days; overdue calculated automatically
6. **Mobile Friendly**: Works on phones and tablets
7. **Dark Mode**: Toggle in settings for dark mode viewing
8. **Export Data**: Use report section for period analysis

## Troubleshooting

### Sales not showing up
- Check search/filter constraints
- Verify date range is correct
- Ensure status filter isn't limiting results

### Payment not recording
- Verify amount is positive
- Confirm amount ≤ remaining balance
- Check sale ID is correct

### Dashboard not updating
- Refresh page (F5)
- Check network connection
- Verify sales/report API is accessible

### Status not updating
- Status updates automatically after payment
- Refresh page to see latest status
- Check total paid calculation is correct

## Support
For detailed API documentation, see `docs/SALES_MANAGEMENT.md`
For implementation details, see `SALES_IMPLEMENTATION.md`

## Success Indicators
✅ You should see:
- Sales listed in table on /app/sales
- Ability to add, edit, delete sales
- Ability to record payments
- Status auto-updating
- Metrics on dashboard
- Sales link in sidebar Finance menu
- Reports generating metrics

---
**Status**: Production Ready 🟢
**Version**: 1.0
**Last Updated**: 2024
