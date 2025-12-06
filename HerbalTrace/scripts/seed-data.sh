#!/bin/bash

# Sample data seeding script
# Populates the blockchain with realistic herb collection data

set -e

BACKEND_URL="${BACKEND_URL:-http://localhost:3000}"
API_TOKEN=""

echo "🌿 HerbalTrace Sample Data Seeding Script"
echo "=========================================="

# Login as admin to get token
echo "Logging in as admin..."
LOGIN_RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "admin",
    "password": "admin123",
    "organization": "FarmersCoop"
  }')

API_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$API_TOKEN" ]; then
  echo "❌ Failed to authenticate"
  exit 1
fi

echo "✅ Authentication successful"

# Sample collection events
declare -a COLLECTIONS=(
  '{
    "collectionId": "COLL-2024-001",
    "farmerId": "FARMER-001",
    "farmerName": "Ramesh Kumar",
    "species": "Withania somnifera",
    "commonName": "Ashwagandha",
    "quantity": 50,
    "unit": "kg",
    "harvestDate": "2024-01-15T06:30:00Z",
    "location": {
      "latitude": 12.9716,
      "longitude": 77.5946,
      "address": "Kolar District, Karnataka"
    },
    "weatherConditions": {
      "temperature": 28,
      "humidity": 65,
      "rainfall": 0
    },
    "certifications": ["Organic India", "NPOP"],
    "photoHashes": ["QmXYZ123..."]
  }'
  '{
    "collectionId": "COLL-2024-002",
    "farmerId": "FARMER-002",
    "farmerName": "Lakshmi Devi",
    "species": "Bacopa monnieri",
    "commonName": "Brahmi",
    "quantity": 30,
    "unit": "kg",
    "harvestDate": "2024-01-16T07:00:00Z",
    "location": {
      "latitude": 11.0168,
      "longitude": 76.9558,
      "address": "Coimbatore District, Tamil Nadu"
    },
    "weatherConditions": {
      "temperature": 26,
      "humidity": 70,
      "rainfall": 2
    },
    "certifications": ["Organic India"],
    "photoHashes": ["QmABC456..."]
  }'
  '{
    "collectionId": "COLL-2024-003",
    "farmerId": "FARMER-003",
    "farmerName": "Suresh Patil",
    "species": "Tinospora cordifolia",
    "commonName": "Guduchi",
    "quantity": 40,
    "unit": "kg",
    "harvestDate": "2024-01-17T06:45:00Z",
    "location": {
      "latitude": 15.8281,
      "longitude": 74.4997,
      "address": "Belgaum District, Karnataka"
    },
    "weatherConditions": {
      "temperature": 30,
      "humidity": 60,
      "rainfall": 0
    },
    "certifications": ["NPOP", "Fair Trade"],
    "photoHashes": ["QmDEF789..."]
  }'
)

echo ""
echo "Creating sample collection events..."

for i in "${!COLLECTIONS[@]}"; do
  COLLECTION="${COLLECTIONS[$i]}"
  echo "Creating collection $((i+1))/${#COLLECTIONS[@]}..."
  
  RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/collection" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_TOKEN" \
    -d "$COLLECTION")
  
  if echo "$RESPONSE" | grep -q "collectionId"; then
    echo "✅ Collection created successfully"
  else
    echo "❌ Failed to create collection"
    echo "$RESPONSE"
  fi
  
  sleep 1
done

echo ""
echo "=========================================="
echo "✅ Sample data seeding complete!"
echo "📊 Created ${#COLLECTIONS[@]} collection events"
echo ""
echo "View collections:"
echo "  curl $BACKEND_URL/api/collection/farmer/FARMER-001"
echo ""
echo "Query by species:"
echo "  curl $BACKEND_URL/api/collection/species/Withania%20somnifera"
