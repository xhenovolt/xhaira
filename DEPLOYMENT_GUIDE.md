# Jeton - Deployment Guide

## Quick Start Deployment

Your system is ready to deploy! Choose your preferred platform below:

---

## 🚀 Option 1: VERCEL (Recommended for Next.js)

**Best for:** Easiest deployment, automatic CI/CD, free tier available

### Steps:
1. Go to https://vercel.com
2. Sign in or create account
3. Click "Import Project"
4. Paste GitHub repo URL: `https://github.com/xhenovolt/jeton.git`
5. Configure environment variables:
   ```
   DATABASE_URL=your_neon_postgres_connection_string
   NODE_ENV=production
   NEXT_PUBLIC_CURRENCY_API_KEY=your_currency_api_key
   ```
6. Click "Deploy"

**Deployment time:** 2-5 minutes  
**Cost:** Free tier available (500GB bandwidth/month)  
**Auto-deploys:** Yes (on push to main)

---

## 🚀 Option 2: RAILWAY

**Best for:** Full-stack apps, includes database hosting, simple pricing

### Steps:
1. Go to https://railway.app
2. Sign in with GitHub
3. Click "New Project"
4. Select "Deploy from GitHub repo"
5. Choose your repository
6. Add PostgreSQL database:
   - Click "Add"
   - Select "PostgreSQL"
7. Set environment variables:
   ```
   DATABASE_URL=${{Postgres.DATABASE_URL}}
   NODE_ENV=production
   ```
8. Click "Deploy"

**Deployment time:** 5-10 minutes  
**Cost:** $5/month starter plan  
**Includes:** PostgreSQL database hosting

---

## 🚀 Option 3: AWS (Elastic Beanstalk)

**Best for:** Enterprise, scalability, full control

### Steps:
1. Install AWS CLI
2. Create Elastic Beanstalk app
3. Deploy with:
   ```bash
   eb create jeton-production
   eb deploy
   ```
4. Set up RDS PostgreSQL database
5. Configure environment variables in Elastic Beanstalk console

**Deployment time:** 10-15 minutes  
**Cost:** ~$20-50/month  
**Includes:** Full AWS infrastructure

---

## 🚀 Option 4: HEROKU

**Best for:** Quick deployment, includes buildpacks

### Steps:
1. Install Heroku CLI
2. Run:
   ```bash
   heroku login
   heroku create jeton-app
   heroku addons:create heroku-postgresql:hobby-dev
   git push heroku main
   ```
3. Set environment variables:
   ```bash
   heroku config:set DATABASE_URL=your_db_url
   heroku config:set NODE_ENV=production
   ```

**Deployment time:** 5-10 minutes  
**Cost:** $7-50/month (PostgreSQL add-on required)

---

## 📋 Pre-Deployment Checklist

### Environment Variables Needed:
- [ ] `DATABASE_URL` - Your PostgreSQL connection string
- [ ] `NODE_ENV=production`
- [ ] `NEXT_PUBLIC_API_URL` - Your production domain (optional)
- [ ] Any API keys your system uses

### Database Setup:
- [ ] PostgreSQL database created
- [ ] All migrations have run
- [ ] Initial user account created (optional)

### Code Quality:
- [ ] ✅ npm run build passes
- [ ] ✅ npm run lint passes (if configured)
- [ ] ✅ All tests pass
- [ ] ✅ Code pushed to main branch

---

## 🔐 Security Checklist

- [ ] Use strong database password
- [ ] Enable HTTPS/SSL (automatic on Vercel, Railway, Heroku)
- [ ] Set secure environment variables (use platform's secret management)
- [ ] Enable database backups
- [ ] Set up monitoring/logging
- [ ] Configure firewall rules
- [ ] Regular security updates

---

## 📊 Production Configuration

### Recommended Settings:

**Database Pooling:**
```javascript
// Already configured in src/lib/db.js
const pool = new Pool({
  max: 10,              // Max connections
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
```

**Next.js Optimization:**
```javascript
// next.config.mjs already includes:
- Image optimization
- Compression
- Caching headers
```

**Performance:**
- Automatic static generation for landing page
- API route caching
- Database connection pooling
- Session cleanup (can add cron job)

---

## 🚀 One-Click Deployment Links

### Vercel
[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https%3A%2F%2Fgithub.com%2Fxhenovolt%2Fjeton&project-name=jeton&repo-name=jeton)

### Railway
[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app?referralCode=ZvKDZx)

---

## 📝 Post-Deployment Steps

After deployment, run:

```bash
# Run migrations (if not automatic)
npm run migrate

# Create initial admin user (optional)
npm run seed

# Check health
curl https://your-domain.com/api/health
```

---

## 🆘 Troubleshooting

### Database Connection Error
```
Error: connect ECONNREFUSED
```
**Solution:** Verify DATABASE_URL is correct and database is accessible

### Build Failing
```
ERROR in /src/app/app/layout.js
```
**Solution:** Ensure Node 18+ is used. Check .nvmrc file.

### Static Page Generation Fails
```
Error: Route X couldn't be rendered statically
```
**Solution:** This is normal - dynamic routes use server-side rendering. Not an error.

### Authentication Not Working
```
Unauthorized on protected routes
```
**Solution:** Ensure DATABASE_URL points to same database where sessions are stored

---

## 📞 Support Resources

- **Vercel Docs:** https://vercel.com/docs
- **Next.js Docs:** https://nextjs.org/docs
- **Railway Docs:** https://docs.railway.app
- **PostgreSQL Connection:** https://www.postgresql.org/docs/current/

---

## Current Status

✅ Code: Committed and pushed to GitHub  
✅ Build: Verified (npm run build successful)  
✅ Security: Authentication system secured  
✅ Database: Ready to connect  
✅ Ready for production deployment  

**Next Step:** Choose a deployment platform above and follow the steps!

---

*Last Updated: February 12, 2026*
