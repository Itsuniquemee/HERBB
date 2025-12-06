# Quick Start Script for Windows/WSL2
# Minimal setup - just start the network

Write-Host "🚀 HerbalTrace Quick Start" -ForegroundColor Green
Write-Host "=========================`n" -ForegroundColor Green

$windowsPath = (Get-Location).Path
$wslPath = wsl wslpath -a "'$windowsPath'"

Write-Host "Converting Windows path to WSL..." -ForegroundColor Cyan
Write-Host "Path: $wslPath`n" -ForegroundColor Gray

Write-Host "Making scripts executable..." -ForegroundColor Cyan
wsl bash -c "cd '$wslPath' && find . -name '*.sh' -type f -exec chmod +x {} \;"
Write-Host "✅ Done`n" -ForegroundColor Green

Write-Host "🚀 Starting Hyperledger Fabric network...`n" -ForegroundColor Cyan
Write-Host "This will:" -ForegroundColor Yellow
Write-Host "  1. Generate crypto material" -ForegroundColor Gray
Write-Host "  2. Start Docker containers (14 containers)" -ForegroundColor Gray
Write-Host "  3. Create channel" -ForegroundColor Gray
Write-Host "  4. Deploy chaincode" -ForegroundColor Gray
Write-Host ""
Write-Host "⏱️  Estimated time: 15-20 minutes`n" -ForegroundColor Yellow

wsl bash -c "cd '$wslPath/scripts' && ./setup.sh"

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Network is running!" -ForegroundColor Green
    Write-Host "`nCheck status: wsl docker ps" -ForegroundColor Cyan
} else {
    Write-Host "`n⚠️  Setup completed with some warnings" -ForegroundColor Yellow
}
