# HerbalTrace - Complete System Startup Script
# This script starts all services needed for final testing

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  HerbalTrace System Startup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Continue"

# Step 1: Stop any existing processes
Write-Host "[1/6] Cleaning up existing processes..." -ForegroundColor Yellow
Write-Host "  Stopping any running Node.js processes..." -ForegroundColor Gray

Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Write-Host "  Done cleanup" -ForegroundColor Green
Write-Host ""

# Step 2: Start Blockchain Network
Write-Host "[2/6] Starting Hyperledger Fabric Blockchain Network..." -ForegroundColor Yellow
Set-Location -Path "D:\Trial\HerbalTrace\network\docker"

Write-Host "  Checking Docker status..." -ForegroundColor Gray
$dockerInfo = docker info 2>$null
if (-not $dockerInfo) {
    Write-Host "  ERROR: Docker is not running! Please start Docker Desktop first." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "  Bringing down existing network..." -ForegroundColor Gray
docker-compose -f docker-compose-herbaltrace.yaml down 2>$null
Start-Sleep -Seconds 3

Write-Host "  Starting blockchain network..." -ForegroundColor Gray
docker-compose -f docker-compose-herbaltrace.yaml up -d

Write-Host "  Waiting for network to initialize (20 seconds)..." -ForegroundColor Gray
Start-Sleep -Seconds 20

Write-Host "  Blockchain network started" -ForegroundColor Green
Write-Host ""

# Step 3: Verify Chaincode
Write-Host "[3/6] Verifying Chaincode..." -ForegroundColor Yellow
Write-Host "  Chaincode verification skipped (will be deployed on first API call)" -ForegroundColor Gray
Write-Host ""

# Step 4: Start Backend API Server
Write-Host "[4/6] Starting Backend API Server..." -ForegroundColor Yellow
Set-Location -Path "D:\Trial\HerbalTrace\backend"

Write-Host "  Verifying npm dependencies..." -ForegroundColor Gray
npm install --silent 2>$null

Write-Host "  Starting API server on port 3000..." -ForegroundColor Gray
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd 'D:\Trial\HerbalTrace\backend'; Write-Host 'Backend API Server' -ForegroundColor Cyan; npm start"

Write-Host "  Waiting for API server to initialize (10 seconds)..." -ForegroundColor Gray
Start-Sleep -Seconds 10

$apiRunning = Test-NetConnection -ComputerName localhost -Port 3000 -InformationLevel Quiet -WarningAction SilentlyContinue
if ($apiRunning) {
    Write-Host "  Backend API server started on http://localhost:3000" -ForegroundColor Green
} else {
    Write-Host "  Warning: API server may still be initializing" -ForegroundColor Yellow
}
Write-Host ""

# Step 5: Start Web Portal
Write-Host "[5/6] Starting Web Portal..." -ForegroundColor Yellow
Set-Location -Path "D:\Trial\HerbalTrace\web-portal"

Write-Host "  Verifying npm dependencies..." -ForegroundColor Gray
npm install --silent 2>$null

Write-Host "  Starting Vite dev server..." -ForegroundColor Gray
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd 'D:\Trial\HerbalTrace\web-portal'; Write-Host 'Web Portal - Vite Dev Server' -ForegroundColor Cyan; npm run dev"

Write-Host "  Waiting for Vite to start (15 seconds)..." -ForegroundColor Gray
Start-Sleep -Seconds 15

Write-Host "  Web portal started" -ForegroundColor Green
Write-Host ""

# Step 6: Final Status
Write-Host "[6/6] System Status..." -ForegroundColor Yellow
Write-Host ""

$containerCount = (docker ps | Measure-Object -Line).Lines - 1
Write-Host "  Docker Containers: $containerCount running" -ForegroundColor Green

$apiCheck = Test-NetConnection -ComputerName localhost -Port 3000 -InformationLevel Quiet -WarningAction SilentlyContinue
if ($apiCheck) {
    Write-Host "  Backend API: http://localhost:3000 [READY]" -ForegroundColor Green
} else {
    Write-Host "  Backend API: Not responding on port 3000" -ForegroundColor Red
}

$webCheck = Test-NetConnection -ComputerName localhost -Port 5173 -InformationLevel Quiet -WarningAction SilentlyContinue
if ($webCheck) {
    Write-Host "  Web Portal: http://localhost:5173 [READY]" -ForegroundColor Green
} else {
    Write-Host "  Web Portal: May be on different port - check terminal" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  System Startup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Access Points:" -ForegroundColor White
Write-Host "  Web Portal: http://localhost:5173" -ForegroundColor Green
Write-Host "  Backend API: http://localhost:3000" -ForegroundColor Green
Write-Host ""
Write-Host "Test Credentials:" -ForegroundColor White
Write-Host "  Admin: admin@herbaltrace.com / admin123" -ForegroundColor Yellow
Write-Host "  Farmer: farmer@example.com / farmer123" -ForegroundColor Yellow
Write-Host "  Lab: lab@example.com / lab123" -ForegroundColor Yellow
Write-Host "  Processor: processor@example.com / processor123" -ForegroundColor Yellow
Write-Host "  Manufacturer: manufacturer@example.com / manufacturer123" -ForegroundColor Yellow
Write-Host ""
Write-Host "Monitoring Commands:" -ForegroundColor White
Write-Host "  docker ps                  - View running containers" -ForegroundColor Gray
Write-Host "  docker logs <container>    - View container logs" -ForegroundColor Gray
Write-Host "  .\stop-all-services.ps1    - Stop all services" -ForegroundColor Gray
Write-Host ""
Write-Host "System is ready for testing!" -ForegroundColor Green
Write-Host ""
