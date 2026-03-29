# Jeton - Production-Grade Next.js + PostgreSQL Setup

## ✅ Setup Complete

Your production-grade Next.js 16 development environment is fully configured and ready for feature development.

### Quick Start

```bash
# Start development server
npm run dev

# Run production build
npm run build

# Start production server
npm start
```

### Live Endpoints

- **Homepage**: http://localhost:3000
- **Health Check API**: http://localhost:3000/api/health
- **Next.js Dev Tools**: http://localhost:3000 (includes HMR)

### API Health Check

Returns real-time database connection status:

```bash
curl http://localhost:3000/api/health
```

Response:
```json
{
  "status": "ok",
  "database": "connected",
  "timestamp": "2025-12-27T17:55:49.323Z",
  "uptime": 400.1
}
```

## 📦 Installed Dependencies

### UI & Styling
- **Tailwind CSS v4** - Utility-first CSS framework
- **shadcn/ui** - High-quality React components
- **Framer Motion** - Animation library (ready for use)
- **Lucide React** - Icon library
- **class-variance-authority** - Component variant management
- **clsx** & **tailwind-merge** - Utility styling

### Backend & Database
- **pg** - PostgreSQL client with connection pooling
- **dotenv** - Environment variable management

### Security & Validation
- **zod** - Schema validation
- **bcryptjs** - Password hashing
- **jsonwebtoken** - JWT authentication

## 🎨 Color Palettes

Three semantic color palettes are integrated into Tailwind:

### Ocean / Trust
- **#03045e** (darkest) → **#caf0f8** (lightest)
- Use for: Primary CTAs, trust-related elements

### Royal Purple
- **#10002b** (darkest) → **#e0aaff** (lightest)
- Use for: Secondary actions, highlights

### Power / Authority
- **#03071e** (darkest) → **#ffba08** (lightest)
- Use for: Warnings, critical actions, status

## 📂 Project Structure

```
jeton/
├── src/
│   ├── app/
│   │   ├── api/
│   │   │   └── health/route.js          # Health check endpoint
│   │   ├── layout.js                    # Global layout
│   │   ├── page.js                      # Dashboard/homepage
│   │   └── globals.css                  # Global styles + color vars
│   │
│   ├── components/
│   │   ├── ui/                          # shadcn/ui components
│   │   ├── layout/                      # Layout components
│   │   └── common/                      # Reusable components
│   │
│   ├── lib/
│   │   ├── db.js                        # PostgreSQL connection
│   │   ├── env.js                       # Environment validation
│   │   └── utils.js                     # Utility functions
│   │
│   └── config/
│       └── (Future theme config)
│
├── .env.local                           # Environment variables
├── tailwind.config.js                   # Tailwind configuration
├── next.config.mjs                      # Next.js configuration
└── package.json                         # Dependencies

```

## 🗄️ Database Connection

The database connection is configured in `src/lib/db.js`:

```javascript
// Usage example
import { query, testConnection } from '@/lib/db.js';

// Run a query
const result = await query('SELECT * FROM users WHERE id = $1', [userId]);

// Test connection
const isConnected = await testConnection();
```

**Connection features:**
- Connection pooling (10 max connections)
- Idle timeout: 30 seconds
- Connection timeout: 5 seconds
- Serverless-ready for Neon
- SSL/TLS support included in Neon URL

## ⚙️ Environment Variables

Located in `.env.local`:

```bash
DATABASE_URL=postgresql://...  # Neon PostgreSQL connection
JWT_SECRET=...                 # For authentication (set this)
NODE_ENV=development          # Development/production
```

Access in code:

```javascript
import { DATABASE_URL, JWT_SECRET, NODE_ENV } from '@/lib/env.js';
```

## 🧪 Development Workflow

### 1. Create Components

Place components in `src/components/`:

```javascript
// src/components/common/Button.js
import { clsx } from 'clsx';

export function Button({ children, variant = 'primary', ...props }) {
  return (
    <button
      className={clsx(
        'px-4 py-2 rounded-lg font-medium transition-colors',
        {
          'bg-primary text-primary-foreground': variant === 'primary',
          'bg-secondary text-secondary-foreground': variant === 'secondary',
        }
      )}
      {...props}
    >
      {children}
    </button>
  );
}
```

### 2. Create API Routes

Place routes in `src/app/api/`:

```javascript
// src/app/api/users/route.js
import { query } from '@/lib/db.js';

export async function GET(request) {
  try {
    const result = await query('SELECT * FROM users');
    return Response.json(result.rows);
  } catch (error) {
    return Response.json({ error: error.message }, { status: 500 });
  }
}
```

### 3. Use Tailwind Colors

All color palettes are available as Tailwind classes:

```javascript
<div className="bg-primary-500 text-primary-100">Primary</div>
<div className="bg-secondary-600 text-secondary-50">Secondary</div>
<div className="bg-accent-500 text-accent-900">Accent</div>
```

## 🚀 Deployment Ready

### Build for Production

```bash
npm run build
npm start
```

### Deploy to Vercel

1. Push to GitHub
2. Connect to Vercel
3. Set environment variables in Vercel dashboard
4. Auto-deploy on push

### Environment Variables for Production

Set these in your deployment platform:
- `DATABASE_URL` - Your Neon database URL
- `JWT_SECRET` - A strong random secret
- `NODE_ENV` - Set to `production`

## 📚 Resources

- [Next.js 16 Docs](https://nextjs.org/docs)
- [Tailwind CSS v4](https://tailwindcss.com)
- [shadcn/ui Components](https://ui.shadcn.com)
- [Framer Motion](https://www.framer.com/motion/)
- [Neon PostgreSQL](https://neon.tech)
- [Lucide Icons](https://lucide.dev)

## ⛔ What's NOT Included (Yet)

- Authentication middleware
- Database schema/migrations
- CRUD operations
- Business logic
- Dashboards
- CMS features

These are intentionally deferred to keep the environment clean and production-ready without unnecessary bloat.

---

**Status**: ✅ Production-ready  
**Last Updated**: December 27, 2025  
**Next Phase**: Feature development
