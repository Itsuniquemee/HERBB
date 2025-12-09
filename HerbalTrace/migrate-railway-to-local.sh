#!/bin/bash
# Migrate data from Railway PostgreSQL to local blockchain backend

set -e

echo "🚀 Railway to Local Migration Script"
echo "===================================="

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
RAILWAY_BACKUP_DIR="./railway-backup-$(date +%Y%m%d_%H%M%S)"
LOCAL_DB_PATH="./backend/database/herbal_trace.db"
EXPORT_SQL="$RAILWAY_BACKUP_DIR/railway_export.sql"

echo -e "${BLUE}Step 1: Creating backup directory...${NC}"
mkdir -p "$RAILWAY_BACKUP_DIR"

echo -e "${BLUE}Step 2: Exporting individual tables as JSON...${NC}"

# Export users
echo "Exporting users..."
railway run --service Postgres psql -t -A -c "SELECT row_to_json(users) FROM users" | \
  jq -s '.' > "$RAILWAY_BACKUP_DIR/users.json" 2>/dev/null || echo "[]" > "$RAILWAY_BACKUP_DIR/users.json"

# Export collection events
echo "Exporting collection events..."
railway run --service Postgres psql -t -A -c "SELECT row_to_json(collection_events_cache) FROM collection_events_cache" | \
  jq -s '.' > "$RAILWAY_BACKUP_DIR/collections.json" 2>/dev/null || echo "[]" > "$RAILWAY_BACKUP_DIR/collections.json"

# Export quality tests
echo "Exporting quality tests..."
railway run --service Postgres psql -t -A -c "SELECT row_to_json(quality_tests_cache) FROM quality_tests_cache" | \
  jq -s '.' > "$RAILWAY_BACKUP_DIR/quality_tests.json" 2>/dev/null || echo "[]" > "$RAILWAY_BACKUP_DIR/quality_tests.json"

# Export processing batches
echo "Exporting processing batches..."
railway run --service Postgres psql -t -A -c "SELECT row_to_json(processing_batches_cache) FROM processing_batches_cache" | \
  jq -s '.' > "$RAILWAY_BACKUP_DIR/batches.json" 2>/dev/null || echo "[]" > "$RAILWAY_BACKUP_DIR/batches.json"

# Export products
echo "Exporting products..."
railway run --service Postgres psql -t -A -c "SELECT row_to_json(products_cache) FROM products_cache" | \
  jq -s '.' > "$RAILWAY_BACKUP_DIR/products.json" 2>/dev/null || echo "[]" > "$RAILWAY_BACKUP_DIR/products.json"

# Export QR codes
echo "Exporting QR codes..."
railway run --service Postgres psql -t -A -c "SELECT row_to_json(qr_codes) FROM qr_codes" | \
  jq -s '.' > "$RAILWAY_BACKUP_DIR/qr_codes.json" 2>/dev/null || echo "[]" > "$RAILWAY_BACKUP_DIR/qr_codes.json"

echo -e "${GREEN}✅ JSON exports completed${NC}"

echo -e "${BLUE}Step 3: Summary of exported data...${NC}"
echo ""
echo "📊 Data Export Summary:"
echo "======================"
echo "Users: $(jq length $RAILWAY_BACKUP_DIR/users.json 2>/dev/null || echo 0)"
echo "Collection Events: $(jq length $RAILWAY_BACKUP_DIR/collections.json 2>/dev/null || echo 0)"
echo "Quality Tests: $(jq length $RAILWAY_BACKUP_DIR/quality_tests.json 2>/dev/null || echo 0)"
echo "Processing Batches: $(jq length $RAILWAY_BACKUP_DIR/batches.json 2>/dev/null || echo 0)"
echo "Products: $(jq length $RAILWAY_BACKUP_DIR/products.json 2>/dev/null || echo 0)"
echo "QR Codes: $(jq length $RAILWAY_BACKUP_DIR/qr_codes.json 2>/dev/null || echo 0)"
echo ""

echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Review exported data in: $RAILWAY_BACKUP_DIR"
echo "2. Run the import script: node migrate-import-to-local.js"
echo "3. This will import data to local SQLite AND register on blockchain"
echo ""
echo -e "${GREEN}✅ Export completed successfully!${NC}"
