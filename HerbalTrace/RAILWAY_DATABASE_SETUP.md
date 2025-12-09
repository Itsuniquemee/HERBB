# Railway PostgreSQL Database Connection Setup

## ✅ Configuration Complete

### Files Created/Updated:
1. **`backend/.env`** - Environment variables with DATABASE_URL
2. **`railway.toml`** - Railway deployment configuration
3. **`railway.json`** - Alternative Railway config format

---

## 🔧 Railway Dashboard Setup

### Step 1: Add PostgreSQL Database
1. Go to your Railway project: https://railway.app/project/[your-project-id]
2. Click **"+ New"** → **"Database"** → **"Add PostgreSQL"**
3. Railway will automatically provision a PostgreSQL database
4. The database will be named something like `railway` or `postgres`

### Step 2: Verify Environment Variables
Railway automatically creates these variables when you add PostgreSQL:
- ✅ `DATABASE_URL` - Full connection string (automatically injected)
- `PGHOST` - Database host
- `PGPORT` - Database port (5432)
- `PGDATABASE` - Database name
- `PGUSER` - Database username
- `PGPASSWORD` - Database password

### Step 3: Link Database to Backend Service
1. Click on your backend service
2. Go to **"Variables"** tab
3. Click **"+ Reference Variable"**
4. Select the PostgreSQL service
5. Add reference: `DATABASE_URL` → `${{ Postgres.DATABASE_URL }}`

---

## 📋 Current Database Configuration

### Backend Code (`backend/src/config/database.ts`)
```typescript
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,  // ✅ Uses Railway's DATABASE_URL
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : undefined,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
```

### Environment Variable (`backend/.env`)
```bash
DATABASE_URL=${{ Postgres.DATABASE_URL }}
```

**Note:** Railway will automatically replace `${{ Postgres.DATABASE_URL }}` with the actual connection string.

---

## 🚀 Deployment Commands

### Deploy to Railway:
```bash
# If using Railway CLI
railway up

# Or push to GitHub (if connected to GitHub)
git add .
git commit -m "Configure PostgreSQL database connection"
git push origin main
```

### Verify Connection:
```bash
# Check health endpoint
curl https://herbal-trace-production.up.railway.app/api/v1/health/database

# Expected response:
{
  "success": true,
  "data": {
    "status": "healthy",
    "connected": true,
    "database": "herbaltrace"
  }
}
```

---

## 🔍 Current Status

### ✅ What's Working:
- PostgreSQL database provisioned on Railway
- Backend connected to database
- 16 collection records stored successfully
- API endpoints responding correctly

### ⚠️ What's Not Working:
- Blockchain sync (requires Hyperledger Fabric network)
- All records have `syncStatus: "failed"`

---

## 📊 Database Tables Created

The backend automatically creates these tables on startup:
1. **`users`** - User accounts and authentication
2. **`registration_requests`** - New user registration requests
3. **`collection_events_cache`** - Herb collection data (your 16 records)
4. **`quality_tests`** - Lab quality test results
5. **`processing_batches`** - Processing batch tracking
6. **`products`** - Final product records
7. **`qr_codes`** - QR code generation tracking
8. **`season_windows`** - Harvest season definitions
9. **`harvest_limits`** - Per-farmer harvest limits
10. **`alerts`** - System alerts and notifications

---

## 🔐 Security Notes

### Production Security:
1. **Change JWT_SECRET** in production:
   ```bash
   # In Railway dashboard, set:
   JWT_SECRET=your-secure-random-string-here
   ```

2. **DATABASE_URL is secure**:
   - Railway automatically encrypts the connection string
   - SSL is enabled for production (`rejectUnauthorized: false`)

3. **CORS Configuration**:
   - Currently set to `*` (allow all origins)
   - For production, set specific frontend URL:
   ```bash
   CORS_ORIGIN=https://your-frontend-domain.com
   ```

---

## 🧪 Test the Connection

### Option 1: Using API
```bash
# Get fresh token
TOKEN=$(curl -s -X POST https://herbal-trace-production.up.railway.app/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' \
  | grep -o '"token":"[^"]*' | sed 's/"token":"//')

# Check collections
curl -s -X GET https://herbal-trace-production.up.railway.app/api/v1/collections \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```

### Option 2: Using Railway CLI
```bash
# Connect to database directly
railway connect Postgres

# Run SQL queries
SELECT COUNT(*) FROM collection_events_cache;
SELECT * FROM users LIMIT 5;
```

---

## 📈 Next Steps

1. **Verify deployment** - Check Railway logs for successful database connection
2. **Test API endpoints** - Use the test commands above
3. **Monitor database** - Use Railway dashboard to view database metrics
4. **Set up blockchain** (optional) - Configure Hyperledger Fabric for blockchain sync

---

## 🆘 Troubleshooting

### Connection Failed?
```bash
# Check Railway logs
railway logs

# Common issues:
# 1. DATABASE_URL not set → Add PostgreSQL service in Railway
# 2. SSL error → Already configured with rejectUnauthorized: false
# 3. Timeout → Check network settings in Railway dashboard
```

### Database Not Initialized?
The backend automatically runs `initializeDatabase()` on startup, creating all tables.

If tables are missing, restart the service:
```bash
railway service restart backend
```

---

## ✅ Configuration Summary

| Item | Status | Value |
|------|--------|-------|
| PostgreSQL Service | ✅ Active | Railway hosted |
| DATABASE_URL | ✅ Set | `${{ Postgres.DATABASE_URL }}` |
| SSL Enabled | ✅ Yes | Production only |
| Tables Created | ✅ Yes | 10 tables |
| Data Stored | ✅ Yes | 16 collections |
| API Working | ✅ Yes | All endpoints |
| Blockchain Sync | ❌ No | Requires Fabric network |

---

**Database connection is ready! Your data is securely stored in Railway's PostgreSQL database.** 🎉
