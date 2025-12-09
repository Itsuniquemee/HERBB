#!/bin/bash
# Alternative: Export using curl from Railway API endpoints

set -e

echo "🚀 Railway Data Export via API"
echo "=============================="

# Get Railway deployment URL
RAILWAY_URL="https://herbal-trace-production.up.railway.app"
BACKUP_DIR="./railway-backup-$(date +%Y%m%d_%H%M%S)"

mkdir -p "$BACKUP_DIR"

echo "📂 Created backup directory: $BACKUP_DIR"
echo ""

# Check if we have a valid token
echo "Step 1: Login to get authentication token..."
echo "Enter admin username (default: admin):"
read -r USERNAME
USERNAME=${USERNAME:-admin}

echo "Enter password:"
read -rs PASSWORD

# Login and get token
echo ""
echo "Logging in..."
TOKEN_RESPONSE=$(curl -s -X POST "$RAILWAY_URL/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}")

TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.token')

if [ "$TOKEN" == "null" ] || [ -z "$TOKEN" ]; then
  echo "❌ Login failed!"
  echo "$TOKEN_RESPONSE"
  exit 1
fi

echo "✅ Logged in successfully!"
echo ""

# Export collections
echo "Step 2: Exporting collection events..."
curl -s -X GET "$RAILWAY_URL/api/v1/collections" \
  -H "Authorization: Bearer $TOKEN" | \
  jq '.data // []' > "$BACKUP_DIR/collections.json"

COLLECTION_COUNT=$(jq 'length' "$BACKUP_DIR/collections.json")
echo "✅ Exported $COLLECTION_COUNT collections"

# Export users (admin endpoint)
echo ""
echo "Step 3: Exporting users..."
curl -s -X GET "$RAILWAY_URL/api/v1/admin/users" \
  -H "Authorization: Bearer $TOKEN" | \
  jq '.data // []' > "$BACKUP_DIR/users.json"

USER_COUNT=$(jq 'length' "$BACKUP_DIR/users.json")
echo "✅ Exported $USER_COUNT users"

# Export quality tests
echo ""
echo "Step 4: Exporting quality tests..."
curl -s -X GET "$RAILWAY_URL/api/v1/quality-tests" \
  -H "Authorization: Bearer $TOKEN" | \
  jq '.data // []' > "$BACKUP_DIR/quality_tests.json"

QC_COUNT=$(jq 'length' "$BACKUP_DIR/quality_tests.json")
echo "✅ Exported $QC_COUNT quality tests"

# Export batches
echo ""
echo "Step 5: Exporting processing batches..."
curl -s -X GET "$RAILWAY_URL/api/v1/batches" \
  -H "Authorization: Bearer $TOKEN" | \
  jq '.data // []' > "$BACKUP_DIR/batches.json"

BATCH_COUNT=$(jq 'length' "$BACKUP_DIR/batches.json")
echo "✅ Exported $BATCH_COUNT batches"

# Export products
echo ""
echo "Step 6: Exporting products..."
curl -s -X GET "$RAILWAY_URL/api/v1/products" \
  -H "Authorization: Bearer $TOKEN" | \
  jq '.data // []' > "$BACKUP_DIR/products.json"

PRODUCT_COUNT=$(jq 'length' "$BACKUP_DIR/products.json")
echo "✅ Exported $PRODUCT_COUNT products"

echo ""
echo "📊 Export Summary:"
echo "=================="
echo "Users: $USER_COUNT"
echo "Collections: $COLLECTION_COUNT"
echo "Quality Tests: $QC_COUNT"
echo "Batches: $BATCH_COUNT"
echo "Products: $PRODUCT_COUNT"
echo ""
echo "📁 Files saved to: $BACKUP_DIR"
echo ""
echo "✅ Export completed!"
echo ""
echo "Next step: Run 'npx ts-node migrate-import-to-local.ts' to import to local blockchain backend"
