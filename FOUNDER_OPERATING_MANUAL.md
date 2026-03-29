# JETON FOUNDER OPERATING MANUAL
**Your Daily Playbook for Running Jet on**

---

## WHO THIS IS FOR

This manual is for **you**, the founder. It's your daily guide to using Jeton to run your business operations without getting lost in complexity.

Jeton is designed to handle the full revenue cycle: from finding prospects to collecting money and tracking profit.

This manual shows you **exactly what to do every day**.

---

## THE FOUNDER WORKFLOW

### The Big Picture

```
PROSPECT
You find a lead
    ↓
FOLLOW-UP
You nurture them
    ↓
CONVERT
They become a client
    ↓
DEAL
You pitch a product/system
    ↓
CONTRACT
They agree to buy
    ↓
PAYMENT
Money arrives
    ↓
ALLOCATION
You distribute the funds
    ↓
FINANCIAL DASHBOARD
You see the profit
```

**This is the only workflow you need to master.**

---

## YOUR DAILY ROUTINE

### MORNING (10 minutes)

#### 1. Check Financial Dashboard
- Route: `/app/finance`
- **Look at:**
  - Total revenue (yesterday vs. all-time)
  - Net profit (are you making money?)
  - Vault balance (your safety net)
  - Outstanding payments (pending allocations)

**Action:** If profit is negative or vault is low, prioritize closing deals today.

#### 2. Review Today's Follow-Ups
- Route: `/app/prospecting/followups`
- **See:** Prospects you promised to call/email today
- **Action:** Reach out to each one. Log the interaction

#### 3. Check Pipeline
- Route: `/app/pipeline` or `/app/deals`
- **See:** Where your deals are (stages)
- **Action:** Identify which deals can move forward today

---

### THROUGHOUT THE DAY

#### When a New Lead Comes In

1. **Add Prospect**
   - Route: `/app/prospecting/new`
   - Fields: Name, Email/Phone, Source (where they came from)
   - Save

2. **Log Initial Contact**
   - Open the prospect
   - Add Activity → Type: Call or Email
   - Note: What did you discuss?
   - Schedule next follow-up date

**Why:** You now have a record. You won't forget this lead.

#### When You  Talk to a Prospect

1. **Log the Activity**
   - Route: `/app/prospecting` → Click prospect
   - Add Activity: Call, Email, Meeting
   - Outcome: Positive, Neutral, or Negative
   - Schedule next follow-up

**Why:** This builds a history. If a deal closes 6 months from now, you can see the entire relationship.

#### When Someone is Ready to Buy

1. **Convert Prospect to Client**
   - Route: Prospect detail page → "Convert to Client" button
   - Verify details
   - Click Convert

2. **Create a Deal**
   - Route: `/app/deals/create`
   - Title: Descriptive (e.g., "ACME Corp - CRM System")
   - Client: Select the client you just created
   - **System:** CRITICAL - Select which product/service you're selling
   - Value Estimate: How much do you expect to earn?
   - Save

**Why:** The system enforces that every deal links to a product. No phantom revenue.

#### When You Close a Deal

1. **Win the Deal**
   - Route: `/app/deals` → Click the deal
   - Click "Win Deal"
   - System auto-creates a contract

2. **Review the Contract**
   - Route: `/app/contracts`
   - Find the new contract
   - Verify: Client, System, Installation Fee, Recurring (if any)

**Why:** Contract is your legal/financial record. Payment will link to this.

#### When Money Arrives

1. **Record Payment**
   - Route: `/app/payments`
   - Click "Record Payment"
   - Select Contract (from dropdown)
   - Amount Received: Enter exact amount
   - Date Received: When money hit your account
   - Payment Method: Bank Transfer, Mobile Money, Cash, etc.
   - Save

2. **Allocate Funds Immediately**
   - Click "Allocate" on the payment
   - Distribution:
     - **40% → Vault** (long-term savings)
     - **40% → Operating** (day-to-day expenses)
     - **20% → Expense** (if specific expense exists)
   - Save Allocations

**Why:** Allocating funds prevents you from spending revenue recklessly. Vault builds financial security.

---

### END OF DAY (5 minutes)

#### 1. Update Deal Pipeline
- Move deals to next stage if they progressed today
- Mark lost deals as "Lost" (don't leave them hanging)

#### 2. Schedule Tomorrow's Follow-Ups
- Review today's calls/meetings  
- Schedule next steps for tomorrow

#### 3. Check Unallocated Payments
- Route: `/app/finance`
- Look for yellow alerts ("unallocated payments")
- Allocate any pending funds

**Why:** Clean slate for tomorrow. No tasks left behind.

---

## WEEKLY ROUTINE (Monday Morning)

### 1. Review Last Week's Performance
- Route: `/app/finance`
- Filter: "This Week" or "Last Week"
- **Check:**
  - Revenue collected
  - Expenses incurred
  - Net profit
  - Top systems by revenue
  - Top clients by revenue

**Action:** Identify which products are selling. Double down on winners.

### 2. Pipeline Health
- Route: `/app/pipeline`
- **Check:**
  - How many deals in each stage?
  - Any deals stuck for >2 weeks?
  - Projected value of open deals

**Action:** For stuck deals, schedule calls to move them forward or mark them lost.

### 3. Prospect Pipeline
- Route: `/app/prospecting/dashboard`
- **Check:**
  - Prospects in each stage
  - Conversion rate (prospects → clients)
  - Average time to convert

**Action:** If conversion rate < 20%, improve your pitch or qualify leads better.

### 4. Financial Goals
- Check vault balance
- **Goal:** Vault should be 6 months of operating expenses
- If below target, increase allocation % to vault

---

## MONTHLY ROUTINE

### 1. Financial Review Meeting (with yourself or team)
- Route: `/app/reports` (if available) or `/app/finance`
- Print or export monthly summary
- **Analyze:**
  - Total revenue (month-over-month growth)
  - Total expenses (are costs increasing)
  - Profit margin (revenue - expenses) / revenue
  - Recurring revenue (predictable income)

**Action:** Set revenue target for next month. Plan to hit it.

### 2. Client Review
- Route: `/app/clients`
- **Check:**
  - Which clients paid this month?
  - Which clients are inactive?
  - Which clients have highest lifetime value?

**Action:** Reach out to top clients for testimonials or referrals. Check in with inactive clients.

### 3. System Performance
- Route: `/app/finance` → Top Systems by Revenue
- **Check:**
  - Which products sold most?
  - Which products have lowest sales?

**Action:** Consider retiring underperforming products. Invest marketing in top sellers.

### 4. Expense Review
- Route: `/app/finance` → "Expenses by Category"
- **Check:**
  - Are expenses growing faster than revenue?
  - Any unnecessary subscriptions or costs?

**Action:** Cut costs that don't contribute to revenue. Invest in growth expenses (marketing, sales tools).

---

## KEY METRICS TO TRACK

### Primary Metrics (Check Daily)

| Metric | Where to Find | What It Means | Target |
|--------|--------------|---------------|--------|
| **Net Profit** | /app/finance | Revenue - Expenses | Positive (green) |
| **Vault Balance** | /app/finance → Cash Position | Long-term savings | 6 months operating expenses |
| **Profit Margin** | /app/finance | (Profit / Revenue) × 100 | 20%+ |
| **Active Deals** | /app/pipeline | Deals not Won/Lost | Keep pipeline full | ###  Secondary Metrics (Check Weekly)

| Metric | Where to Find | What It Means | Target |
|--------|--------------|---------------|--------|
| **MRR** | /app/finance → Recurring Revenue | Monthly predictable income | Grow 10% month-over-month |
| **Conversion Rate** | /app/prospecting/dashboard | Prospects → Clients % | 20%+ |
| **Average Deal Value** | /app/deals | Total value / # deals | Increase over time |
| **Client Count** | /app/clients | Total active clients | Grow steadily |

---

## COMMON SCENARIOS

### Scenario 1: Deal is Stuck
**Situation:** A deal has been in "Proposal" stage for 3 weeks.

**Action:**
1. Open the deal
2. Review notes - what was the last conversation?
3. Call the client
   - Ask: "What's blocking us from moving forward?"
   - Offer: Discount, payment plan, or demo
4. Log the activity
5. Either move to "Negotiation" or "Lost"

**Why:** Deals don't close themselves. Follow up aggressively.

### Scenario 2: Prospect Goes Cold
**Situation:** Prospect hasn't responded to 3 emails.

**Action:**
1. Open prospect
2. Check activity log - what was the last touchpoint?
3. Try different channel:
   - If emailed, call them
   - If called, send WhatsApp
4. If still no response after 7 days, mark as "Archived" or "Disqualified"
5. Move on to warmer leads

**Why:** Don't waste time on unresponsive leads. Focus energy on engaged prospects.

### Scenario 3: Client Hasn't Paid
**Situation:** Contract is active but no payment recorded.

**Action:**
1. Check contract: `/app/contracts` → Find contract
2. Review terms - was payment due yet?
3. Send reminder:
   - Email client with invoice (if available)
   - Or call to confirm payment timeline
4. Log activity on client record
5. If overdue >30 days, escalate or pause service

**Why:** Cash flow is critical. Don't let unpaid invoices accumulate.

### Scenario 4: Vault is Low
**Situation:** Vault balance < 1 month of expenses.

**Action:**
1. Immediately increase vault allocation to 50%
2. Defer non-critical expenses
3. Focus on closing deals this week
4. Review monthly burn rate - reduce if possible

**Why:** Vault is your safety net. Without it, one bad month can sink you.

---

## RULES TO LIVE BY

### ✅ ALWAYS
- **Log every prospect interaction** - If it's not logged, it didn't happen
- **Allocate payments immediately** - Don't leave funds unallocated
- **Link deals to systems** - Every deal must have a product
- **Follow up on scheduled dates** - Today's follow-ups can't wait
- **Check financial dashboard daily** - Know your numbers

### ❌ NEVER
- **Create deals without systems** - System enforces this, don't try to bypass
- **Forget to convert prospects** - Client conversion unlocks contracts
- **Spend from vault** - Vault is for emergencies only
- **Ignore unallocated payments** - Allocate within 24 hours
- **Let deals sit for >2 weeks** - Move them or lose them

---

## SCALING BEYOND YOURSELF

### When to Hire

**Sales Person:**
- When you have >50 prospects to manage
- When follow-ups take >3 hours/day
- **How they'll use Jeton:**
  - Add prospects
  - Log activities
  - Move deals through pipeline
  - Convert prospects to clients
  - You still win deals and handle contracts

**Finance Person:**
- When you have >10 payments/month to allocate
- When expense tracking becomes overwhelming
- **How they'll use Jeton:**
  - Record payments
  - Allocate funds according to rules
  - Track expenses
  - Generate reports
  - You still review financial dashboard

**Admin:**
- When team >5 people
- **How they'll use Jeton:**
  - User management (`/app/admin`)
  - Role assignment
  - Audit log monitoring

### Onboarding New Team Members

1. **Give them access:** `/app/admin/users` → Create account → Assign role
2. **Show them this manual:** They should read relevant sections
3. **Train on workflow:** Walk through their specific tasks
4. **Set expectations:** Daily tasks, metrics to track
5. **Review weekly:** Check their usage (via activity logs)

---

## WHEN THINGS GO WRONG

### Error: "Deal must have a system"
**Cause:** You tried to create a deal without selecting a product.  
**Fix:** Edit deal → Select System → Save

### Error: "Prospect already converted"
**Cause:** You tried to convert a prospect that's already a client.  
**Fix:** Go to `/app/clients` to find the existing client record

### Error: "Cannot allocate more than payment amount"
**Cause:** Your allocations exceed the payment.  
**Fix:** Reduce allocation amounts so total ≤ payment amount

### Payment Status Stuck on "Pending"
**Cause:** No allocations recorded yet.  
**Fix:** Click "Allocate" → Distribute funds → Save

### Financial Dashboard Shows Negative Profit
**Cause:** Expenses > Revenue.  
**Fix:**
1. Review expenses - cut non-essentials
2. Close more deals (increase revenue)
3. Check if expenses were recorded incorrectly

---

## YOUR JETON DASHBOARD AT A GLANCE

### What You Should See Every Morning

**Finance Dashboard (`/app/finance`):**
```
✅ Total Revenue: $125,000 (▲ 15% this month)
✅ Net Profit: $45,000 (36% margin)
✅ Vault Balance: $80,000 (strong)
⚠️ 2 payments pending allocation (fix immediately)
```

**Today's Follow-Ups (`/app/prospecting/followups`):**
```
- John Doe (Acme Corp) - Follow-up call
- Jane Smith (TechCo) - Send proposal
- Bob Johnson (StartupX) - Demo meeting
```

**Pipeline (`/app/pipeline`):**
```
Lead: 5 deals ($50,000)
Qualification: 3 deals ($30,000)
Proposal: 2 deals ($20,000)
Won: 1 deal this week ($10,000)
```

**This tells you:**
- Business is healthy (profit is positive)
- Need to allocate 2 payments today
- 3 follow-ups to complete
- Pipeline is active with potential revenue

---

## FINAL WORDS

### The Founder Mindset

**Jeton is your co-pilot, not your replacement.**

It won't find prospects for you. It won't close deals for you. It won't allocate your money without your input.

But it **will**:
- Remember every lead so you don't
- Enforce business rules so you don't make costly mistakes
- Track your money so you know exactly where you stand
- Show you the truth about your business (profit, not vanity metrics)

**Use it every day. Trust the workflow. Let it scale with you.**

When you're managing 10 deals, Jeton handles it.  
When you're managing 100 deals, Jeton still handles it.  
When you hire a sales team, Jeton keeps everyone aligned.

**Your job as founder:**
1. Find prospects
2. Close deals
3. Allocate wisely
4. Review the dashboard

**Jeton's job:**
1. Track everything
2. Enforce rules
3. Show you the truth
4. Scale with your growth

---

**Now go build your business.**  
**Jeton has your back.**

---

**Document Version:** 1.0  
**Last Updated:** March 8, 2026  
**For:** Founders using Jeton daily
