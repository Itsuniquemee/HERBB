#!/bin/bash

# Complete HerbalTrace Network Restart Script
# This fixes configuration issues and restarts the network

echo "==========================================="
echo "🔄 HerbalTrace Network Complete Restart"
echo "==========================================="
echo ""

cd /mnt/d/Trial/HerbalTrace/network

# Step 1: Stop all containers
echo "1. Stopping all HerbalTrace containers..."
docker-compose -f docker/docker-compose-herbaltrace.yaml down
echo "✅ Containers stopped"
echo ""

# Step 2: Ensure peercfg exists
echo "2. Creating peer configuration..."
mkdir -p peercfg

if [ ! -f "peercfg/core.yaml" ]; then
    cat > peercfg/core.yaml << 'EOF'
peer:
  fileSystemPath: /var/hyperledger/production
  mspConfigPath: /etc/hyperledger/fabric/msp
  tls:
    enabled: true
    cert:
      file: /etc/hyperledger/fabric/tls/server.crt
    key:
      file: /etc/hyperledger/fabric/tls/server.key
    rootcert:
      file: /etc/hyperledger/fabric/tls/ca.crt
vm:
  endpoint: unix:///host/var/run/docker.sock
chaincode:
  startuptimeout: 300s
  executetimeout: 30s
ledger:
  state:
    stateDatabase: GoLevelDB
EOF
fi
echo "✅ Configuration ready"
echo ""

# Step 3: Start network
echo "3. Starting HerbalTrace network..."
docker-compose -f docker/docker-compose-herbaltrace.yaml up -d

echo "Waiting for network to initialize (15 seconds)..."
sleep 15
echo ""

# Step 4: Check status
echo "4. Network Status:"
echo "===================="
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "herbaltrace|NAMES"
echo ""

# Step 5: Check peer logs
echo "5. Checking peer0.farmers log..."
docker logs peer0.farmers.herbaltrace.com --tail 10 2>&1 | tail -5
echo ""

echo "==========================================="
echo "✅ Network restart complete!"
echo "==========================================="
echo ""
echo "To verify:"
echo "  docker ps | grep herbaltrace"
echo "  docker logs peer0.farmers.herbaltrace.com"
echo ""
