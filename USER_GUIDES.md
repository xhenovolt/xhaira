# JETON USER GUIDES
**Step-by-Step Instructions for Common Tasks**

---

## TABLE OF CONTENTS

1. [How to Add a Prospect](#how-to-add-a-prospect)
2. [How to Record a Follow-Up](#how-to-record-a-follow-up)
3. [How to Convert a Prospect to Client](#how-to-convert-a-prospect-to-client)
4. [How to Create a Deal](#how-to-create-a-deal)
5. [How to Close a Deal](#how-to-close-a-deal)
6. [How to Record a Payment](#how-to-record-a-payment)
7. [How to Allocate Funds](#how-to-allocate-funds)
8. [How to Track Revenue](#how-to-track-revenue)
9. [How to View Financial Dashboard](#how-to-view-financial-dashboard)
10. [How to Add a System/Product](#how-to-add-a-systemproduct)

---

## HOW TO ADD A PROSPECT

### Overview
A prospect is a potential customer you want to track through your sales pipeline.

### Steps

1. **Navigate to Prospects**
   - Click "Growth" in the sidebar
   - Select "Prospects"

2. **Click "New Prospect"**
   - Look for the "+ New Prospect" button (top right)
   - Click it to open the form

3. **Fill Required Fields**
   - **Prospect Name:** Full name of the person or company
   - **Email OR Phone:** At least one contact method required
   - **Company Name:** (Optional but recommended)
   - **Industry:** Select from dropdown
   - **Source:** How did you find them? (Website, Referral, Cold Call, etc.)

4. **Optional Fields**
   - WhatsApp Number
   - City and Country
   - Address
   - Assigned Sales Agent

5. **Save**
   - Click "Create Prospect"
   - You'll be redirected to the prospect detail page

### What Happens Next
- Prospect appears in your prospect list
- Starts at the first stage of your pipeline
- You can now log activities and schedule follow-ups

### Tips
- ✅ Always add source to track where leads come from
- ✅ Assign prospects to sales agents for accountability
- ✅ Use tags to categorize prospects (e.g., "Hot Lead", "Enterprise")

---

## HOW TO RECORD A FOLLOW-UP

### Overview
Track every interaction with a prospect to maintain relationship history.

### Steps

1. **Open Prospect**
   - Navigate to Prospects list
   - Click on the prospect name

2. **Go to Activities Tab**
   - You'll see the activity log
   - Click "+ Add Activity"

3. **Select Activity Type**
   - **Call:** Phone conversation
   - **Email:** Email correspondence
   - **Meeting:** In-person or virtual meeting
   - **Message:** WhatsApp, SMS, etc.
   - **Note:** General note

4. **Fill Activity Details**
   - **Subject:** Brief title (e.g., "Follow-up call re: pricing")
   - **Description:** Detailed notes
   - **Outcome:** How did it go? (Positive, Neutral, Negative)
   - **Activity Date:** When it happened

5. **Schedule Next Follow-Up (Optional)**
   - Set "Next Follow-Up Date"
   - This will appear in your follow-ups dashboard

6. **Save**
   - Click "Log Activity"

### What Happens Next
- Activity saved to prospect's history
- If follow-up scheduled, appears in Today's Follow-ups
- Prospect's "Last Activity" date updates

### Tips
- ✅ Log activities immediately after calls/meetings
- ✅ Be specific in descriptions for future reference
- ✅ Always schedule next follow-up to maintain momentum
- ✅ Use outcomes to track prospect engagement

---

## HOW TO CONVERT A PROSPECT TO CLIENT

### Overview
When a prospect agrees to do business, convert them to a client.

### Prerequisites
- ✅ Prospect must be qualified (warmed up)
- ✅ Prospect should be in "Ready to Convert" stage

### Steps

1. **Navigate to Conversions**
   - Click "Growth" → "Conversions"
   - OR go to the specific prospect

2. **Click "Convert to Client"**
   - Look for the "Convert" button
   - Click to open conversion form

3. **Verify Information**
   - Client name (auto-filled from prospect)
   - Email and phone
   - Company name
   - Address

4. **Add Notes (Optional)**
   - Document why they converted
   - Record any special agreements

5. **Confirm Conversion**
   - Click "Convert Now"
   - System creates client record

### What Happens Next
- Prospect status changes to "Converted"
- New client record created
- Client appears in Clients list
- Original prospect record preserved (linked via prospect_id)
- Prospect can no longer be edited

### Tips
- ⚠️ **Cannot undo conversion** - Make sure prospect is truly qualified
- ✅ Always verify contact information before converting
- ✅ Conversion logs an activity on the prospect

---

## HOW TO CREATE A DEAL

### Overview
A deal represents a specific sales opportunity for a product/system.

### Prerequisites
- ✅ Must have a client (convert prospect first if needed)
- ✅ Must know which system/product you're selling

### Steps

1. **Navigate to Deals**
   - Click "Investments" → "Deals"

2. **Click "Create Deal" **
   - Look for "+ New Deal" button
   - Click to open form

3. **Fill Required Fields**
   - **Deal Title:** Descriptive name (e.g., "ACME Corp - ERP System")
   - **Client:** Select from dropdown (or prospect if not converted yet)
   - **System:** REQUIRED - What are you selling?
   - **Value Estimate:** Expected deal value
   - **Probability:** % chance of closing (0-100%)
   - **Stage:** Start with "Lead" or "Qualification"

4. **Optional Fields**
   - Expected close date
   - Deal notes
   - Priority level

5. **Save**
   - Click "Create Deal"

### What Happens Next
- Deal appears in deal list
- Deal shows in pipeline view
- Can track progression through stages

### Common Errors
- ❌ **"System is required"** - You must select which product you're selling
- ❌ **"Client or prospect required"** - Select a client from the dropdown

### Tips
- ✅ Always select a system - crucial for revenue tracking
- ✅ Be realistic with probability estimates
- ✅ Update value estimate as deal progresses
- ✅ Deals can link to prospects who aren't clients yet

---

## HOW TO CLOSE A DEAL

### Overview
When you win a deal, mark it as "Won" to auto-create a contract.

### Prerequisites
- ✅ Deal must exist
- ✅ Prospect must be converted to client (happens automatically if needed)
- ✅ Deal must have system_id

### Steps

1. **Open Deal**
   - Navigate to Deals list
   - Click on the deal

2. **Click "Win Deal"**
   - Look for green "Win" or "Mark as Won" button
   - Click it

3. **Review Auto-Contract Creation**
   - System automatically creates contract
   - Contract links to:
     - The client
     - The system (product)
     - The deal itself

4. **Configure Contract (Optional)**
   - Installation fee (defaults to deal value)
   - Recurring billing setup
   - Contract terms

5. **Confirm**
   - Click "Win Deal & Create Contract"

### What Happens Next
- Deal → stage chages to "Won"
- Contract automatically created
- Contract appears in Contracts list
- Ready to record payment

### Automatic Conversions
- 🔄 If deal had prospect (not client), prospect auto-converts to client first
- 🔄 Contract inherits deal's client_id and system_id

### Common Errors
- ❌ **"Prospect must be converted first"** - Convert prospect manually, then try again
- ❌ **"Deal must have system"** - Edit deal to add system, then try winning

### Tips
- ✅ Winning is irreversible - make sure deal is truly closed
- ✅ Review contract details after auto-creation
- ✅ Can manually create contract if you prefer more control

---

## HOW TO RECORD A PAYMENT

### Overview
Track money received from clients.

### Prerequisites
- ✅ Must have an active contract
- ✅ Amount must be greater than 0

### Steps

1. **Navigate to Payments**
   - Click "Investments" → "Payments"

2. **Click "New Payment"**
   - Look for "+ Record Payment" button

3. **Fill Payment Details**
   - **Contract:** Select from dropdown (lists active contracts)
   - **Amount Received:** Enter amount in your currency
   - **Date Received:** When money arrived
   - **Payment Method:** Cash, Bank Transfer, Mobile Money, Card, Crypto, Other
   - **Reference Number:** Transaction ID or check number (optional)

4. **Add Notes (Optional)**
   - Document payment context
   - Special terms or conditions

5. **Save**
   - Click "Record Payment"

### What Happens Next
- Payment appears in payments list
- Payment status starts as "Pending Allocation"
- Financial dashboard updates with new revenue
- Ready to allocate funds

### Tips
- ✅ Always select correct contract for accurate tracking
- ✅ Use reference numbers for audit trail
- ✅ Record payment date as actual receipt date, not invoice date
- ✅ Can record partial payments multiple times for same contract

---

## HOW TO ALLOCATE FUNDS

### Overview
Distribute received payments to different financial categories.

### Prerequisites
- ✅ Payment must exist
- ✅ Total allocations cannot exceed payment amount

### Steps

1. **Open Payment**
   - Navigate to Payments list
   - Click on the payment
   - OR click "Allocate" button directly

2. **Click "Allocate Funds"**
   - Opens allocation modal/form

3. **Choose Allocation Type**
   - **Vault:** Long-term savings/reserves
   - **Operating:** Day-to-day business expenses
   - **Expense:** Direct expense payment (specific)
   - **Investment:** Growth/investment funds
   - **Custom:** Other categories

4. **Enter Amount**
   - Amount to allocate to this category
   - Must be ≤ remaining unallocated amount

5. **Add Multiple Allocations (Optional)**
   - Click "+ Add Another Allocation"
   - Distribute across multiple categories
   - Example: 50% vault, 30% operating, 20% expense

6. **Review Total**
   - Check that allocations don't exceed payment amount
   - Remaining balance shows at bottom

7. **Save**
   - Click "Save Allocations"

### What Happens Next
- Payment allocation_status updates:
  - **Pending:** No allocations yet
  - **Partial:** Some allocated, some remaining
  - **Allocated:** Fully allocated
- Vault balances update automatically
- Financial dashboard reflects new allocation

### Validation Rules
- ✅ Cannot allocate more than payment amount
- ✅ Database trigger validates totals
- ✅ Can update allocations later if needed

### Tips
- ✅ Common distribution: 40% vault, 40% operating, 20% expense
- ✅ Allocate funds immediately after recording payment
- ✅ Use expense allocations for specific known expenses
- ✅ Vault for long-term financial security

---

## HOW TO TRACK REVENUE

### Overview
Monitor revenue by client, by system, and over time.

### Where to View

1. **Financial Dashboard**
   - Navigate to "Finance" → "Finance Dashboard"
   - Shows:
     - Total revenue collected
     - Revenue by system (product)
     - Revenue by client
     - Monthly recurring revenue
     - Revenue trends

2. **System Revenue**
   - "Top Systems by Revenue" section
   - Click system to see details
   - Shows: installation + recurring revenue

3. **Client Revenue**
   - "Top Clients by Revenue" section
   - Shows total collected per client
   - Last payment date

### Metrics Explained

- **Total Revenue:** Sum of all payments received
- **Installation Revenue:** One-time setup fees from contracts
- **Recurring Revenue:** Monthly ongoing revenue from active contracts
- **Annual Projection:** Recurring revenue × 12 months

### Revenue Breakdown
```
Revenue = Installation Fees + Recurring Payments
```

### Tips
- ✅ Check dashboard daily for real-time updates
- ✅ Use system revenue to identify bestsellers
- ✅ Track client revenue to identify top customers
- ✅ Monitor recurring revenue for predictable income

---

## HOW TO VIEW FINANCIAL DASHBOARD

### Overview
Real-time view of your business financial health.

### Steps

1. **Navigate to Finance**
   - Click "Finance" in sidebar
   - Select "Finance Dashboard"

2. **Review Key Metrics**

   **Top Section:**
   - Total Revenue (all-time or filtered)
   - Total Expenses
   - Net Profit (green = profit, red = loss)
   - Profit Margin %

   **Cash Position:**
   - Vault Balance (long-term savings)
   - Operating Balance (working capital)
   - Investment Balance
   - Total Cash Position

   **Recurring Revenue:**
   - Monthly Recurring Revenue (MRR)
   - Annual Projection
   - Active Contracts

   **Performance:**
   - Top Systems by Revenue
   - Top Clients by Revenue
   - Revenue trends

3. **Filter by Date Range**
   - Toggle: This Month / Quarter / Year / All Time
   - Metrics update based on selection

4.**Check Data Integrity**
   - Yellow alerts show if payments need allocation
   - Review and fix any issues

### What Each Metric Means

| Metric | Meaning | Goal |
|--------|---------|------|
| Net Profit | Revenue - Expenses | Stay positive |
| Profit Margin | (Profit / Revenue) × 100 | Target 20%+ |
| Vault Balance | Emergency reserves | Build to 6 months expenses |
| Operating Balance | Available cash | Maintain buffer |
| MRR | Predictable monthly income | Grow over time |

### Tips
- ✅ Check dashboard every morning
- ✅ Set goal: 30% to vault, 50% to operating, 20% to expenses
- ✅ Track profit margin trends monthly
- ✅ Address data integrity alerts immediately

---

## HOW TO ADD A SYSTEM/PRODUCT

### Overview
Systems are the products or services you sell. Every deal must reference a system.

### Prerequisites
- ✅ Know what you're selling

### Steps

1. **Navigate to Systems**
   - Click "Systems" → "IP Portfolio"

2. **Click "New System"**
   - Look for "+ Add System" button

3. **Fill System Details**
   - **System Name:** Product/service name (e.g., "ERP Software", "Consulting Package")
   - **Description:** What it does
   - **Category:** (if applicable)
   - **Status:** Active/Inactive

4. **Save**
   - Click "Create System"

### What Happens Next
- System appears in IP Portfolio
- Available when creating deals
- Available when creating contracts
- Revenue tracked per system

### Tips
- ✅ Create systems before creating deals
- ✅ Use clear, descriptive names
- ✅ Group related products by category
- ✅ Deactivate systems you no longer sell

---

## WORKFLOW SUMMARY

### The Complete Founder Workflow

```
1. ADD PROSPECT
   ↓
2. LOG FOLLOW-UPS
   ↓
3. CONVERT TO CLIENT
   ↓
4. CREATE DEAL (with system)
   ↓
5. WIN DEAL → Auto-creates contract
   ↓
6. RECORD PAYMENT (link to contract)
   ↓
7. ALLOCATE FUNDS (distribute to categories)
   ↓
8. VIEW FINANCIAL DASHBOARD
```

### Daily Routine

**Morning:**
1. Check financial dashboard
2. Review today's follow-ups
3. Update deal pipeline

**Throughout Day:**
4. Log prospect interactions
5. Move deals through stages
6. Record payments as received

**End of Day:**
7. Allocate new payments
8. Schedule tomorrow's follow-ups
9. Review metrics

---

## COMMON QUESTIONS

### Q: Can I delete a prospect?
**A:** Yes, unless they've been converted to a client. Once converted, prospect record is preserved.

### Q: What happens if I try to win a deal without a client?
**A:** If the deal has a prospect_id, the system will auto-convert the prospect to a client first.

### Q: Can I have multiple contracts with the same client?
**A:** Yes! A client can have many contracts (for different systems or recurring agreements).

### Q: How do I handle partial payments?
**A:** Record each payment separately, all linked to the same contract. The system tracks total paid.

### Q: Can I edit an allocation after saving?
**A:** Yes, you can update allocations as long as the totals don't exceed the payment amount.

### Q: What if I allocate funds to the wrong category?
**A:** Edit the allocation and change the category or amount. The financial dashboard updates automatically.

### Q: Why can't I create a deal without a system?
**A:** Every deal must know what you're selling. This ensures accurate revenue tracking per product.

### Q: How do I archive a client?
**A:** Change client status to "Inactive" or "Churned" in the client detail view.

---

## GETTING HELP

### Support Resources
- 📚 **Documentation:** `/docs` (this site)
- 📧 **Email Support:** support@xhaira.system
- 💬 **Chat:** Available in-app (bottom right)

### Reporting Issues
- Navigate to Settings → Report Issue
- Describe what you were trying to do
- Include any error messages

---

**Document Version:** 1.0  
**Last Updated:** March 8, 2026  
**For:** Xhaira Users (Founders, Sales Team, Finance Team)
