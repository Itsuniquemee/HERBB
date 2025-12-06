# Quick Fix for HerbalTrace Network
# Run this in PowerShell to fix and restart the network

Write-Host "🔧 Fixing HerbalTrace Network..." -ForegroundColor Yellow
Write-Host ""

# Stop all containers
Write-Host "Stopping containers..." -ForegroundColor Cyan
wsl docker-compose -f /mnt/d/Trial/HerbalTrace/network/docker/docker-compose-herbaltrace.yaml down
Write-Host "✅ Containers stopped" -ForegroundColor Green
Write-Host ""

# Create core.yaml for peers
Write-Host "Creating peer configuration..." -ForegroundColor Cyan
wsl bash -c @"
mkdir -p /mnt/d/Trial/HerbalTrace/network/peercfg
cat > /mnt/d/Trial/HerbalTrace/network/peercfg/core.yaml << 'EOF'
peer:
  id: peer0
  networkId: herbaltrace
  listenAddress: 0.0.0.0:7051
  address: 0.0.0.0:7051
  addressAutoDetect: false
  
  fileSystemPath: /var/hyperledger/production
  
  mspConfigPath: /etc/hyperledger/fabric/msp
  localMspId: FarmersMSP
  
  tls:
    enabled: true
    cert:
      file: /etc/hyperledger/fabric/tls/server.crt
    key:
      file: /etc/hyperledger/fabric/tls/server.key
    rootcert:
      file: /etc/hyperledger/fabric/tls/ca.crt
EOF
"@

Write-Host "✅ Configuration created" -ForegroundColor Green
Write-Host ""

# Restart network
Write-Host "Starting network..." -ForegroundColor Cyan
wsl docker-compose -f /mnt/d/Trial/HerbalTrace/network/docker/docker-compose-herbaltrace.yaml up -d
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "Checking status..." -ForegroundColor Cyan
wsl docker ps --format "table {{.Names}}\t{{.Status}}" | Select-String -Pattern "herbaltrace|NAMES"

Write-Host ""
Write-Host "✅ Network restarted" -ForegroundColor Green
Write-Host "Run: wsl docker logs peer0.farmers.herbaltrace.com" -ForegroundColor Gray
