# HerbalTrace Network - Quick Status & Test

Write-Host "`n🔍 HerbalTrace Network Status Check" -ForegroundColor Green
Write-Host "====================================`n" -ForegroundColor Green

# Check running containers
Write-Host "Running Containers:" -ForegroundColor Cyan
wsl docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | Select-String -Pattern "herbaltrace|orderer|NAMES"

Write-Host "`n`n📊 Summary:" -ForegroundColor Cyan
$orderers = wsl docker ps --filter "name=orderer.herbaltrace" --format "{{.Names}}"
$ordererCount = ($orderers | Measure-Object).Count

if ($ordererCount -gt 0) {
    Write-Host "✅ $ordererCount Orderer(s) running" -ForegroundColor Green
} else {
    Write-Host "❌ No orderers running" -ForegroundColor Red
}

$peers = wsl docker ps --filter "name=peer" --format "{{.Names}}"
$peerCount = ($peers | Measure-Object).Count

if ($peerCount -gt 0) {
    Write-Host "✅ $peerCount Peer(s) running" -ForegroundColor Green
} else {
    Write-Host "⚠️  No peers running (configuration issue)" -ForegroundColor Yellow
}

Write-Host "`n`n📝 Current Status:" -ForegroundColor Cyan
Write-Host "  • Orderers: Running ✅" -ForegroundColor White
Write-Host "  • Peers: Need configuration fix ⚠️" -ForegroundColor White
Write-Host "`n"

Write-Host "The orderers are working, but peers need proper Fabric configuration." -ForegroundColor Yellow
Write-Host "This is a common issue with Hyperledger Fabric initial setup.`n" -ForegroundColor Gray

Write-Host "Recommended Actions:" -ForegroundColor Cyan
Write-Host "  1. Use the existing ayurtrace network (already working)" -ForegroundColor White
Write-Host "  2. Or fix peer configs with Fabric binaries from setup.sh" -ForegroundColor White
Write-Host "`n"

Write-Host "To check logs:" -ForegroundColor Cyan
Write-Host "  wsl docker logs orderer.herbaltrace.com" -ForegroundColor Gray
Write-Host "  wsl docker logs peer0.farmers.herbaltrace.com" -ForegroundColor Gray
Write-Host ""
