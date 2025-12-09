# How to Execute SQL in Railway PostgreSQL

## Method 1: Using Railway CLI (Recommended)

Install Railway CLI if you don't have it:
```bash
npm i -g @railway/cli
```

Then run SQL commands:
```bash
# Login to Railway
railway login

# Link to your project
railway link

# Connect to PostgreSQL
railway run psql $DATABASE_URL
```

Once in psql, paste the SQL scripts.

---

## Method 2: Using psql Directly

Get your DATABASE_URL from Railway:
1. Go to Railway Dashboard → Your Postgres service
2. Click on **Variables** tab
3. Copy the `DATABASE_URL` value

Then run:
```bash
psql "YOUR_DATABASE_URL_HERE"
```

---

## Method 3: Using Railway's Connect Feature

1. In Railway Dashboard → Postgres service
2. Look for **"Connect"** button (top right, purple icon)
3. This opens a connection interface where you can:
   - Copy connection string
   - Use provided connection methods

---

## Method 4: Use a Database Client (Easiest)

Download a free PostgreSQL client like:
- **TablePlus** (https://tableplus.com) - Beautiful UI, free tier
- **DBeaver** (https://dbeaver.io) - Free & open source
- **pgAdmin** (https://www.pgadmin.org) - Official PostgreSQL tool

**Connection Details from Railway:**
- Host: `hopper.proxy.rlwy.net` (or similar)
- Port: Usually `5432`
- Database: Check Variables tab
- Username: Check Variables tab  
- Password: Check Variables tab

---

## SQL Scripts to Run

### Script 1: Fix Alerts Table
```sql
DROP TABLE IF EXISTS alerts CASCADE;

CREATE TABLE alerts (
  id SERIAL PRIMARY KEY,
  alert_type TEXT NOT NULL CHECK (alert_type IN (
    'GEO_FENCE_VIOLATION', 'HARVEST_LIMIT_EXCEEDED', 'SEASONAL_WINDOW_VIOLATION',
    'QUALITY_TEST_FAILED', 'PROCESSING_ALERT', 'EXPIRED_BATCH',
    'RECALL_NOTICE', 'SYSTEM_ALERT', 'BATCH_ASSIGNED', 'BATCH_STATUS_UPDATED'
  )),
  severity TEXT DEFAULT 'MEDIUM' CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL', 'INFO')),
  entity_type TEXT NOT NULL CHECK (entity_type IN ('collection', 'batch', 'test', 'product', 'user', 'system')),
  entity_id TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  details TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'acknowledged', 'resolved', 'dismissed')),
  triggered_by TEXT,
  acknowledged_by TEXT,
  acknowledged_at TIMESTAMP,
  resolved_by TEXT,
  resolved_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_alerts_type ON alerts(alert_type);
CREATE INDEX idx_alerts_entity ON alerts(entity_type, entity_id);
CREATE INDEX idx_alerts_status ON alerts(status);
```

### Script 2: Create Users
```sql
INSERT INTO users (id, user_id, username, email, password_hash, full_name, phone, role, org_name, org_msp, affiliation, location_district, location_state, status, created_at)
VALUES 
('user-admin-001', 'admin-001', 'admin', 'admin@herbaltrace.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'System Administrator', '+919876543210', 'Admin', 'HerbalTrace', 'HerbalTraceMSP', 'admin', 'Dehradun', 'Uttarakhand', 'active', CURRENT_TIMESTAMP),
('user-farmer-001', 'farmer-001', 'farmer1', 'farmer1@herbaltrace.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Rajesh Kumar', '+919876543211', 'Farmer', 'Kumar Herbs Farm', 'Dehradun', 'Uttarakhand', 'active', CURRENT_TIMESTAMP);
```

---

## Quick Option: Use Railway CLI

```bash
# Install Railway CLI
npm i -g @railway/cli

# Login and connect
railway login
cd /Users/manas/Maanas/Herb/HerbalTrace
railway link

# Run the SQL files
railway run psql $DATABASE_URL < fix-alerts-table.sql
railway run psql $DATABASE_URL < create-railway-admin.sql
```
