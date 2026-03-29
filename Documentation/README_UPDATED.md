# Jeton - Executive Company Management & Decision Intelligence System

Jeton is a production-grade, full-stack Next.js application designed as an **executive operating system** for managing company operations, finances, and strategic assets. It provides a founder-friendly, enterprise-class platform for accurate record-keeping, valuation analysis, and decision intelligence.

## 🎯 Core Features

### 1. **Multi-Domain Architecture**
Jeton separates business concerns into distinct operational domains:

- **💰 Accounting Assets**: Tangible, depreciable items (laptops, phones, equipment, furniture)
- **🚀 Intellectual Property**: Revenue-generating IP (software, internal systems, licensed IP, brands) 
- **🏗️ Infrastructure**: Operational foundations (domains, social media, design systems, brand assets)
- **💳 Liabilities**: Debts and financial obligations
- **🤝 Deals**: Business transactions and partnerships
- **📊 Pipeline**: Sales pipeline and opportunities

### 2. **Valuation Engine**
Dual-perspective financial analysis:

- **Accounting Net Worth**: Balance sheet foundation (Assets - Liabilities)
- **Strategic Company Value**: Executive perspective (Accounting Net Worth + IP Value + Infrastructure Buffer)
- **Depreciation Calculations**: Straight-line, accelerated, and units-of-production methods
- **IP Valuation**: Revenue-based, cost-based, and market-based approaches

### 3. **Executive Dashboard**
Real-time visibility into company health with:

- Value bridge analysis showing the premium of strategic value over accounting value
- Asset breakdown by type with per-type valuations
- IP breakdown showing revenue-generating assets
- Infrastructure risk assessment (critical → low)
- Auto-refresh every 30 seconds

### 4. **Sidebar Navigation**
Organized menu structure with collapsible sections:

```
📊 OPERATIONAL DOMAINS
  • Dashboard (Valuation Overview)
  • Infrastructure
  • Accounting Assets
  • Intellectual Property
  • Liabilities
  • Deals
  • Pipeline

⚙️ ADMINISTRATION
  • Staff
  • Audit Logs
  • Settings
```

## 🚀 Getting Started

### Prerequisites
- Node.js 18+
- PostgreSQL 14+ (Neon recommended for serverless)
- npm or yarn

### Installation

```bash
# Clone and install dependencies
npm install

# Set up environment variables
cp .env.example .env.local
# Edit .env.local with your Neon PostgreSQL connection string

# Initialize database
node scripts/init-db.js

# Start development server
npm run dev
```

Visit [http://localhost:3000](http://localhost:3000) to see the application.

## 📁 Project Structure

```
src/
├── app/
│   ├── api/
│   │   ├── assets-accounting/          # Tangible asset endpoints
│   │   ├── intellectual-property/      # IP asset endpoints
│   │   ├── infrastructure/             # Infrastructure endpoints
│   │   ├── valuations/                 # Valuation engine endpoint
│   │   └── [id]/                       # Detail routes (GET/PUT/DELETE)
│   ├── assets-accounting/              # Accounting assets page
│   ├── intellectual-property/          # IP management page
│   ├── infrastructure/                 # Infrastructure page
│   ├── dashboard/                      # Executive dashboard
│   ├── layout.js                       # Root layout with sidebar
│   └── globals.css                     # Tailwind CSS
├── components/
│   └── Sidebar.js                      # Navigation component
├── lib/
│   ├── db.js                          # PostgreSQL connection pool
│   ├── valuations.js                  # Calculation engine
│   └── utils.js                       # Utility functions
└── config/
    └── [configuration files]
```

## 🔌 API Endpoints

### Assets (Accounting)
```
GET    /api/assets-accounting           # List all assets
POST   /api/assets-accounting           # Create new asset
GET    /api/assets-accounting/[id]      # Get asset details
PUT    /api/assets-accounting/[id]      # Update asset
DELETE /api/assets-accounting/[id]      # Soft delete (disposal)
```

### Intellectual Property
```
GET    /api/intellectual-property       # List all IP assets
POST   /api/intellectual-property       # Create new IP
GET    /api/intellectual-property/[id]  # Get IP details
PUT    /api/intellectual-property/[id]  # Update IP
DELETE /api/intellectual-property/[id]  # Soft delete (sunset)
```

### Infrastructure
```
GET    /api/infrastructure              # List all infrastructure
POST   /api/infrastructure              # Create new item
GET    /api/infrastructure/[id]         # Get infrastructure details
PUT    /api/infrastructure/[id]         # Update item
DELETE /api/infrastructure/[id]         # Soft delete (archive)
```

### Valuations
```
GET    /api/valuations                  # Get complete valuation summary
```

### Health Check
```
GET    /api/health                      # Database connection status
```

## 📊 Data Models

### Asset (Accounting)
```javascript
{
  id: UUID,
  name: string,
  asset_type: 'laptop' | 'phone' | 'equipment' | 'furniture' | 'other',
  acquisition_cost: number,
  depreciation_method: 'straight_line' | 'accelerated' | 'units_of_production',
  current_book_value: number,  // Calculated
  status: 'active' | 'disposed',
  disposal_date: date | null
}
```

### Intellectual Property
```javascript
{
  id: UUID,
  name: string,
  ip_type: 'software' | 'internal_system' | 'licensed_ip' | 'brand',
  development_cost: number,
  valuation_estimate: number,
  revenue_generated_monthly: number,
  clients_count: number,
  status: 'active' | 'scaling' | 'maintenance' | 'deprecated',
  sunset_date: date | null
}
```

### Infrastructure
```javascript
{
  id: UUID,
  infrastructure_name: string,
  infrastructure_type: 'domain' | 'social_media' | 'design_system' | 'brand_asset',
  risk_level: 'critical' | 'high' | 'medium' | 'low',
  replacement_cost: number,
  status: 'active' | 'archived'
}
```

## 🛠️ Technology Stack

- **Framework**: Next.js 16 with App Router
- **Language**: JavaScript (ES6+)
- **Database**: PostgreSQL (Neon with connection pooling)
- **Styling**: Tailwind CSS v4 with semantic color palettes
- **UI Components**: shadcn/ui for headless components
- **Icons**: lucide-react
- **Animations**: Framer Motion (framework ready)
- **Validation**: Zod (prepared for integration)

## 💾 Database

### Connection
- Provider: Neon (serverless PostgreSQL)
- Pool Size: 10 connections
- SSL: Enabled with certificate binding

### Tables
- **Core**: users, audit_logs, staff_profiles, assets, liabilities, deals, snapshots
- **Accounting**: assets_accounting, asset_depreciation_logs
- **Strategic**: intellectual_property, ip_valuation_logs
- **Operational**: infrastructure, infrastructure_audit_logs
- **Summary**: valuation_summary

## 🔐 Security Features

- ✅ JWT-ready authentication structure
- ✅ Password hashing with bcryptjs
- ✅ Database connection pooling
- ✅ Input validation (Zod-ready)
- ✅ SQL injection prevention (parameterized queries)
- ✅ Soft deletes preserve data integrity
- ✅ Audit logging structure

## 🎨 Design System

### Color Palettes
- **Ocean/Trust** (Primary): #0066CC
- **Royal Purple** (Secondary): #7C3AED
- **Power/Authority** (Accent): #DC2626

### Responsive Design
- Mobile-first approach
- Tablet and desktop breakpoints
- PWA-ready structure
- Sidebar collapses on mobile

## 📈 Valuation Calculations

### Depreciation Methods
```javascript
// Straight-line
annual_depreciation = (cost - residual_value) / useful_life

// Accelerated (double declining)
rate = 2 / useful_life
depreciation = book_value * rate

// Units of production
depreciation_per_unit = (cost - residual) / total_units
depreciation = units_produced * depreciation_per_unit
```

### IP Valuation
```javascript
// Revenue multiple method
ip_value = monthly_revenue * client_count * revenue_multiple

// Cost method
ip_value = development_cost * appreciation_factor

// Final estimate uses provided valuation_estimate
```

## 📝 API Examples

### Create an Accounting Asset
```bash
curl -X POST http://localhost:3000/api/assets-accounting \
  -H "Content-Type: application/json" \
  -d '{
    "name": "MacBook Pro",
    "asset_type": "laptop",
    "acquisition_cost": 2500,
    "depreciation_method": "straight_line",
    "depreciation_rate": 20,
    "useful_life_years": 5
  }'
```

### Create an IP Asset
```bash
curl -X POST http://localhost:3000/api/intellectual-property \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Jeton Platform",
    "ip_type": "software",
    "development_cost": 50000,
    "valuation_estimate": 150000,
    "revenue_generated_monthly": 5000,
    "clients_count": 3
  }'
```

### Get Valuation Summary
```bash
curl http://localhost:3000/api/valuations | jq '.data.summary'
```

## 🎯 Features Completed

### ✅ Phase 1: Environment Setup (Completed)
- Next.js 16 with Turbopack
- Tailwind CSS v4
- shadcn/ui component library
- PostgreSQL with Neon
- Environment configuration

### ✅ Phase 2: Multi-Domain Architecture (Completed)
- 7 new database tables for accounting, strategic, and operational domains
- 4 complete REST API endpoints with full CRUD operations
- Soft delete patterns preserving data integrity
- Real-time valuation calculations

### ✅ Phase 3: UI/Frontend (Completed)
- Sidebar navigation with organized menu structure
- Executive dashboard with value bridge analysis
- List pages for all domains (Intellectual Property, Infrastructure)
- Modal forms for creating new assets
- Responsive design (mobile, tablet, desktop)

### ✅ Phase 4: API Detail Routes (Completed)
- GET [id] - Retrieve individual items
- PUT [id] - Update items (partial updates supported)
- DELETE [id] - Soft delete with appropriate status updates

## 🎯 Roadmap (Next Steps)

- [ ] User authentication & authorization
- [ ] Detailed list/detail view components
- [ ] Create/Edit modals for all domains
- [ ] Audit logging integration
- [ ] Export to PDF/Excel
- [ ] Dark mode theme toggle
- [ ] Advanced filtering and search
- [ ] Bulk operations
- [ ] Mobile app (React Native)
- [ ] Real-time collaboration features

## 📞 Support

For issues or questions, please check the existing GitHub issues or create a new one with detailed information.

## 📄 License

This project is proprietary and confidential. All rights reserved.

---

**Built with ❤️ for founders, by Xhenvolt**  
**Jeton v1.0 - Executive Operating System**
