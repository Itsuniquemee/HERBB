# Railway to Local Migration Guide

## Overview

This guide helps you transfer all data from Railway PostgreSQL deployment to your local blockchain-based backend.

## What Gets Migrated

- ✅ **Users** (farmers, processors, admins, etc.)
- ✅ **Collection Events** (harvest records)
- ✅ **Quality Tests** (QC records)
- ✅ **Processing Batches** (processing records)
- ✅ **Products** (final products)
- ✅ **QR Codes** (generated QR codes)
- ✅ **Blockchain Registration** (automatic re-registration on local Fabric network)

## Prerequisites

1. **Railway CLI installed** ✅ (already done)
2. **Railway project linked** ✅ (already done)
3. **Local Hyperledger Fabric network running**
4. **Local backend configured with SQLite**
5. **jq installed** for JSON processing

Install jq if needed:
```bash
brew install jq
```

## Step-by-Step Migration

### Step 1: Export Data from Railway

```bash
cd /Users/manas/Maanas/Herb/HerbalTrace
chmod +x migrate-railway-to-local.sh
./migrate-railway-to-local.sh
```

**This will:**
- Create a timestamped backup directory (e.g., `railway-backup-20251209_120000`)
- Export all data from Railway PostgreSQL as JSON files
- Show a summary of exported records

**Expected Output:**
```
📊 Data Export Summary:
======================
Users: 2
Collection Events: 5
Quality Tests: 3
Processing Batches: 1
Products: 0
QR Codes: 2
```

### Step 2: Start Local Blockchain Network

Make sure your Hyperledger Fabric network is running:

```bash
cd /Users/manas/Maanas/Herb/HerbalTrace/fabric-network
./start-network.sh
```

Wait for confirmation that all containers are running.

### Step 3: Start Local Backend

In a separate terminal:

```bash
cd /Users/manas/Maanas/Herb/HerbalTrace/backend
npm run dev
```

### Step 4: Import Data to Local System

```bash
cd /Users/manas/Maanas/Herb/HerbalTrace
npx ts-node migrate-import-to-local.ts
```

**This will:**
- Read the exported JSON files
- Import data into local SQLite database
- Register transactions on local Hyperledger Fabric blockchain
- Show detailed progress for each record

**Expected Output:**
```
📥 Importing users...
✅ Imported user: admin (Admin)
✅ Imported user: farmer1 (Farmer)

📥 Importing collection events...
✅ Imported collection: COLL-XXXXXXXXXX (Ashwagandha)
  🔗 Registered on blockchain: TX-YYYYYYYY

📊 Migration Summary
===================
Users:
  ✅ Imported: 2
Collections:
  ✅ Imported: 5
  🔗 Blockchain: 5
```

### Step 5: Verify Migration

Check local database:
```bash
sqlite3 backend/database/herbal_trace.db "SELECT COUNT(*) FROM users;"
sqlite3 backend/database/herbal_trace.db "SELECT COUNT(*) FROM collection_events_cache;"
```

Check blockchain:
```bash
curl http://localhost:3000/api/v1/blockchain/collections
```

## Troubleshooting

### Error: "No backup directory found"
**Solution:** Run `migrate-railway-to-local.sh` first to export data.

### Error: "Blockchain registration failed"
**Solution:** Ensure Hyperledger Fabric network is running:
```bash
docker ps | grep hyperledger
```

### Error: "UNIQUE constraint failed"
**Solution:** Data already exists in local DB. The script automatically skips duplicates.

### Error: "jq: command not found"
**Solution:** Install jq:
```bash
brew install jq
```

## What Happens During Migration

### 1. Export Phase (`migrate-railway-to-local.sh`)
- Connects to Railway PostgreSQL via `railway run`
- Uses `pg_dump` for SQL export
- Uses `psql` with `row_to_json` for JSON exports
- Creates timestamped backup directory
- Preserves all data relationships

### 2. Import Phase (`migrate-import-to-local.ts`)
- Reads JSON files from backup directory
- Inserts data into local SQLite database
- **Smart duplicate detection** - skips existing records
- **Blockchain registration** - registers unregistered transactions
- **Progress tracking** - shows detailed statistics

### 3. Blockchain Registration
For each record without a `blockchain_tx_id`:
- Calls Hyperledger Fabric SDK
- Submits transaction to blockchain
- Updates local DB with transaction ID
- Continues even if blockchain fails (records still imported)

## Data Integrity

- ✅ **No data loss** - All Railway data is preserved
- ✅ **Duplicate protection** - Existing local data is not overwritten
- ✅ **Blockchain sync** - Automatically registers missing blockchain transactions
- ✅ **Rollback safe** - Can be run multiple times safely

## Post-Migration

### Option 1: Keep Both Systems Running
- Railway: Production deployment (PostgreSQL)
- Local: Development with blockchain (SQLite + Fabric)
- Manual sync as needed

### Option 2: Migrate Fully to Local
- Export all Railway data
- Import to local system
- Shut down Railway deployment
- Save costs

### Option 3: Use Railway for Blockchain Too
- Deploy Hyperledger Fabric to Railway
- Use PostgreSQL adapter (already configured)
- Full production setup on Railway

## Backup Files Created

After migration, you'll have:

```
railway-backup-20251209_120000/
├── railway_export.sql          # Full SQL dump
├── users.json                  # User accounts
├── collections.json            # Collection events
├── quality_tests.json          # QC test results
├── batches.json               # Processing batches
├── products.json              # Final products
└── qr_codes.json              # Generated QR codes
```

**Keep these files safe** - they're your backup!

## Quick Commands

```bash
# Export from Railway
./migrate-railway-to-local.sh

# Import to local + blockchain
npx ts-node migrate-import-to-local.ts

# Check local database
sqlite3 backend/database/herbal_trace.db ".tables"

# Check blockchain
curl http://localhost:3000/api/v1/blockchain/health
```

## Support

If you encounter issues:
1. Check logs in `backend/logs/`
2. Verify Fabric network: `docker ps`
3. Test Railway connection: `railway status`
4. Review backup files in `railway-backup-*/`
