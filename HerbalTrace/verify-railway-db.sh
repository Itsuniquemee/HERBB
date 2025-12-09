#!/bin/bash

# Quick verification script after adding DATABASE_URL to Railway

echo "🔍 Checking if DATABASE_URL was applied..."
echo ""

# Wait a bit for deployment
echo "⏳ Waiting 5 seconds for deployment..."
sleep 5

# Check database health
echo "📊 Testing database connection..."
curl -s https://herbal-trace-production.up.railway.app/api/v1/health/database | python3 -m json.tool

echo ""
echo "✅ If you see a different host (not 'localhost'), DATABASE_URL is working!"
echo "❌ If you still see 'localhost', the variable isn't set yet - wait for redeploy to complete"
