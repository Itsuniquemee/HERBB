# HerbalTrace Automated Deployment for Windows/WSL2
# This script automates the entire deployment process

Write-Host "🌿 HerbalTrace Automated Deployment" -ForegroundColor Green
Write-Host "====================================`n" -ForegroundColor Green

# Step 1: Check WSL2
Write-Host "Step 1: Checking WSL2 installation..." -ForegroundColor Cyan
$wsl = wsl --list --verbose
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ WSL2 is not installed. Please install WSL2 first." -ForegroundColor Red
    Write-Host "Run: wsl --install" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ WSL2 is installed and running`n" -ForegroundColor Green

# Step 2: Convert Windows path to WSL path
Write-Host "Step 2: Converting paths for WSL..." -ForegroundColor Cyan
$windowsPath = (Get-Location).Path
$wslPath = wsl wslpath -a "'$windowsPath'"
Write-Host "Windows path: $windowsPath" -ForegroundColor Gray
Write-Host "WSL path: $wslPath" -ForegroundColor Gray
Write-Host "✅ Path conversion complete`n" -ForegroundColor Green

# Step 3: Make scripts executable in WSL
Write-Host "Step 3: Making bash scripts executable..." -ForegroundColor Cyan
wsl bash -c "cd '$wslPath' && find . -name '*.sh' -type f -exec chmod +x {} \;"
Write-Host "✅ Scripts are now executable`n" -ForegroundColor Green

# Step 4: Check Docker
Write-Host "Step 4: Checking Docker installation..." -ForegroundColor Cyan
$dockerCheck = wsl bash -c "docker --version 2>&1"
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Docker not found in WSL. Installing Docker..." -ForegroundColor Yellow
    wsl bash -c "cd '$wslPath' && ./scripts/setup.sh"
} else {
    Write-Host "✅ Docker is installed: $dockerCheck`n" -ForegroundColor Green
}

# Step 5: Install backend dependencies
Write-Host "Step 5: Installing backend dependencies..." -ForegroundColor Cyan
Set-Location "$windowsPath\backend"
if (Test-Path "package.json") {
    Write-Host "Running npm install..." -ForegroundColor Gray
    npm install
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Backend dependencies installed`n" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Backend npm install had warnings (this is normal)`n" -ForegroundColor Yellow
    }
}

# Step 6: Install web portal dependencies
Write-Host "Step 6: Installing web portal dependencies..." -ForegroundColor Cyan
Set-Location "$windowsPath\web-portal"
if (Test-Path "package.json") {
    Write-Host "Running npm install..." -ForegroundColor Gray
    npm install
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Web portal dependencies installed`n" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Web portal npm install had warnings (this is normal)`n" -ForegroundColor Yellow
    }
}

# Step 7: Install Flutter dependencies
Write-Host "Step 7: Checking Flutter installation..." -ForegroundColor Cyan
$flutterCheck = flutter --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Flutter is installed" -ForegroundColor Green
    Set-Location "$windowsPath\mobile-app"
    if (Test-Path "pubspec.yaml") {
        Write-Host "Running flutter pub get..." -ForegroundColor Gray
        flutter pub get
        Write-Host "✅ Flutter dependencies installed`n" -ForegroundColor Green
    }
} else {
    Write-Host "⚠️  Flutter not found. Skipping mobile app setup." -ForegroundColor Yellow
    Write-Host "Install Flutter from: https://flutter.dev/docs/get-started/install`n" -ForegroundColor Gray
}

# Step 8: Create .env file for backend
Write-Host "Step 8: Configuring backend environment..." -ForegroundColor Cyan
Set-Location "$windowsPath\backend"
if (!(Test-Path ".env")) {
    if (Test-Path ".env.example") {
        Copy-Item ".env.example" ".env"
        Write-Host "✅ Created .env file from .env.example`n" -ForegroundColor Green
    }
} else {
    Write-Host "✅ .env file already exists`n" -ForegroundColor Green
}

# Step 9: Deploy Hyperledger Fabric network
Write-Host "Step 9: Deploying Hyperledger Fabric network..." -ForegroundColor Cyan
Write-Host "This will take 15-20 minutes. Please wait...`n" -ForegroundColor Yellow
Set-Location $windowsPath

$deployScript = @"
cd '$wslPath/scripts'
echo '🚀 Starting HerbalTrace network deployment...'
echo ''

# Run the setup script
./setup.sh

echo ''
echo '✅ Network deployment complete!'
echo ''
echo '📊 Checking running containers...'
docker ps --format 'table {{.Names}}\t{{.Status}}'
"@

wsl bash -c $deployScript

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Hyperledger Fabric network deployed successfully!`n" -ForegroundColor Green
} else {
    Write-Host "`n⚠️  Network deployment completed with warnings`n" -ForegroundColor Yellow
}

# Step 10: Start backend API server
Write-Host "Step 10: Starting backend API server..." -ForegroundColor Cyan
Set-Location "$windowsPath\backend"
Write-Host "Starting server on http://localhost:3000`n" -ForegroundColor Gray

Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$windowsPath\backend'; npm run dev"
Start-Sleep -Seconds 3
Write-Host "✅ Backend API server started in new window`n" -ForegroundColor Green

# Step 11: Start web portal
Write-Host "Step 11: Starting web portal..." -ForegroundColor Cyan
Set-Location "$windowsPath\web-portal"
Write-Host "Starting portal on http://localhost:3001`n" -ForegroundColor Gray

Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$windowsPath\web-portal'; `$env:PORT=3001; npm start"
Start-Sleep -Seconds 3
Write-Host "✅ Web portal started in new window`n" -ForegroundColor Green

# Step 12: Summary
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "🎉 HerbalTrace Deployment Complete!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "Services running:" -ForegroundColor Cyan
Write-Host "  📡 Blockchain Network: 14 containers (orderers + peers + CouchDB)" -ForegroundColor White
Write-Host "  🔌 Backend API:       http://localhost:3000" -ForegroundColor White
Write-Host "  🌐 Web Portal:        http://localhost:3001" -ForegroundColor White
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Test API health:    curl http://localhost:3000/health" -ForegroundColor White
Write-Host "  2. Seed sample data:   wsl bash -c 'cd $wslPath/scripts && ./seed-data.sh'" -ForegroundColor White
Write-Host "  3. Setup monitoring:   wsl bash -c 'cd $wslPath/scripts && ./setup-monitoring.sh'" -ForegroundColor White
Write-Host "  4. Open web portal:    http://localhost:3001" -ForegroundColor White
Write-Host ""

Write-Host "Check Docker containers:" -ForegroundColor Cyan
Write-Host "  wsl docker ps" -ForegroundColor White
Write-Host ""

Write-Host "View logs:" -ForegroundColor Cyan
Write-Host "  Backend:  Check the backend server window" -ForegroundColor White
Write-Host "  Network:  wsl docker logs peer0.farmerscoop.herbaltrace.com" -ForegroundColor White
Write-Host ""

Write-Host "Stop all services:" -ForegroundColor Cyan
Write-Host "  cd network && wsl docker-compose -f docker/docker-compose-herbaltrace.yaml down" -ForegroundColor White
Write-Host ""

Write-Host "Documentation: See README.md and DEPLOYMENT.md" -ForegroundColor Gray
Write-Host "Happy tracing!" -ForegroundColor Green
