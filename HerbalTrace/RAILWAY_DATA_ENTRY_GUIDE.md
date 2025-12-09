# Railway PostgreSQL Data Entry Guide

## 🎯 Goal
Create an Ashwagandha collection event (5kg, 55% moisture) in the Railway deployment.

## 📋 Steps to Add Data

### Step 1: Create Users in Railway PostgreSQL

1. Go to **[Railway Dashboard](https://railway.app/dashboard)**
2. Select your **Herbal-Trace** project
3. Click on the **PostgreSQL** service
4. Navigate to **Data** tab
5. Click the **Query** button
6. Copy and paste the SQL from `create-railway-admin.sql`:

```sql
-- Create admin user
INSERT INTO users (
  id, user_id, username, email, password_hash, full_name, 
  phone, role, org_name, org_msp, affiliation, 
  location_district, location_state, status, created_at
) VALUES (
  'user-admin-001',
  'admin-001',
  'admin',
  'admin@herbaltrace.com',
  '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
  'System Administrator',
  '+919876543210',
  'Admin',
  'HerbalTrace',
  'HerbalTraceMSP',
  'admin',
  'Dehradun',
  'Uttarakhand',
  'active',
  CURRENT_TIMESTAMP
);

-- Create farmer user
INSERT INTO users (
  id, user_id, username, email, password_hash, full_name, 
  phone, role, org_name, location_district, location_state, 
  status, created_at
) VALUES (
  'user-farmer-001',
  'farmer-001',
  'farmer1',
  'farmer1@herbaltrace.com',
  '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
  'Rajesh Kumar',
  '+919876543211',
  'Farmer',
  'Kumar Herbs Farm',
  'Dehradun',
  'Uttarakhand',
  'active',
  CURRENT_TIMESTAMP
);
```

7. Click **Run Query**
8. ✅ You should see "2 rows inserted"

---

### Step 2: Login to Get JWT Token

Use the farmer account to create collection events:

```bash
curl -X POST https://herbal-trace-production.up.railway.app/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "farmer1",
    "password": "farmer123"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "userId": "farmer-001",
    "username": "farmer1",
    "role": "Farmer"
  }
}
```

📝 **Copy the `token` value** - you'll need it for the next step!

---

### Step 3: Create Ashwagandha Collection Event

Replace `YOUR_JWT_TOKEN_HERE` with the token from Step 2:

```bash
curl -X POST https://herbal-trace-production.up.railway.app/api/v1/collections \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE" \
  -d '{
    "species": "Ashwagandha",
    "commonName": "Indian Ginseng",
    "scientificName": "Withania somnifera",
    "quantity": 5,
    "unit": "kg",
    "latitude": 30.3165,
    "longitude": 78.0322,
    "altitude": 450,
    "accuracy": 10,
    "harvestDate": "2025-12-09",
    "harvestMethod": "Manual Harvesting",
    "partCollected": "Roots",
    "weatherConditions": "Sunny, 22°C, Low Humidity",
    "soilType": "Sandy Loam",
    "moistureContent": "55%",
    "conservationStatus": "Least Concern",
    "certificationIds": ["ORG-CERT-2025"],
    "images": []
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Collection event created successfully",
  "data": {
    "collectionId": "COLL-XXXXXXXXXX",
    "species": "Ashwagandha",
    "quantity": 5,
    "unit": "kg",
    "moistureContent": "55%",
    ...
  }
}
```

---

### Step 4: Verify in Railway PostgreSQL

Back in Railway Dashboard → PostgreSQL → Data → Query:

```sql
-- View all users
SELECT id, username, role, full_name, status FROM users;

-- View all collection events
SELECT * FROM collection_events_cache ORDER BY created_at DESC;
```

---

## 🔐 User Credentials

| Username | Password | Role | Email |
|----------|----------|------|-------|
| `admin` | `admin123` | Admin | admin@herbaltrace.com |
| `farmer1` | `farmer123` | Farmer | farmer1@herbaltrace.com |

---

## 📊 Collection Event Details

- **Species**: Ashwagandha (Withania somnifera)
- **Quantity**: 5 kg
- **Moisture Content**: 55%
- **Part Collected**: Roots
- **Harvest Method**: Manual Harvesting
- **Location**: Dehradun, Uttarakhand (30.3165°N, 78.0322°E)
- **Date**: December 9, 2025
- **Weather**: Sunny, 22°C, Low Humidity
- **Soil Type**: Sandy Loam

---

## ✅ Success Indicators

After completing all steps, you should have:

- ✅ 2 users visible in Railway PostgreSQL `users` table
- ✅ 1 collection event in `collection_events_cache` table
- ✅ JWT token authentication working
- ✅ API responding with success messages
- ✅ Data visible in Railway dashboard

---

## 🆘 Troubleshooting

**Problem**: Login fails with "Invalid credentials"
- **Solution**: Make sure you ran the SQL INSERT statements correctly. Check if users exist:
  ```sql
  SELECT username, role FROM users;
  ```

**Problem**: "No authorization token provided"
- **Solution**: Make sure you include the `-H "Authorization: Bearer YOUR_TOKEN"` header

**Problem**: "Route not found"
- **Solution**: Check the deployment is active at https://herbal-trace-production.up.railway.app/api/v1/health

---

## 📁 Files Created

1. `create-railway-admin.sql` - SQL to create admin and farmer users
2. `create-ashwagandha-collection.json` - JSON payload for collection event
3. `RAILWAY_DATA_ENTRY_GUIDE.md` - This guide

---

## 🔗 Quick Links

- **Deployment**: https://herbal-trace-production.up.railway.app
- **Health Check**: https://herbal-trace-production.up.railway.app/api/v1/health
- **Railway Dashboard**: https://railway.app/dashboard

---

**Note**: The password hash `$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy` corresponds to both `admin123` and `farmer123`.
