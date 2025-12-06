# HerbalTrace - Stop All Services Script

Write-Host "========================================" -ForegroundColor Red
Write-Host "  Stopping HerbalTrace System" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""

# Stop Node.js processes
Write-Host "[1/3] Stopping Node.js processes..." -ForegroundColor Yellow
Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Write-Host "  ✓ Node.js processes stopped" -ForegroundColor Green
Write-Host ""

# Stop Docker containers
Write-Host "[2/3] Stopping Blockchain Network..." -ForegroundColor Yellow
Set-Location -Path "D:\Trial\HerbalTrace\network"
docker-compose -f docker-compose.yaml down
Write-Host "  ✓ Blockchain network stopped" -ForegroundColor Green
Write-Host ""

# Cleanup
Write-Host "[3/3] Cleanup..." -ForegroundColor Yellow
Write-Host "  Removing stopped containers..." -ForegroundColor Gray
docker container prune -f 2>$null
Write-Host "  ✓ Cleanup complete" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "  All Services Stopped" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "To restart, run: .\start-all-services.ps1" -ForegroundColor Cyan
