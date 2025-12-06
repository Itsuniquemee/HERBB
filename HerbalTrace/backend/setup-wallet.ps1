# Setup Wallet for HerbalTrace Backend
$ErrorActionPreference = "Stop"
$WALLET_PATH = "..\network\wallet"
$ORG_PATH = "..\network\organizations\peerOrganizations"

Write-Host "Setting up HerbalTrace Fabric wallet..." -ForegroundColor Green

if (!(Test-Path $WALLET_PATH)) {
    New-Item -ItemType Directory -Path $WALLET_PATH -Force | Out-Null
}

$ORGS = @{
    "FarmersCoop" = "farmers.herbaltrace.com"
    "TestingLabs" = "labs.herbaltrace.com"
    "Processors" = "processors.herbaltrace.com"
    "Manufacturers" = "manufacturers.herbaltrace.com"
}

function Create-Identity {
    param ([string]$Org, [string]$Domain)
    
    $userDir = Join-Path $ORG_PATH "$Domain\users\Admin@$Domain"
    if (!(Test-Path $userDir)) {
        Write-Host "Warning: Admin directory not found for $Org" -ForegroundColor Yellow
        return
    }
    
    $certPath = Join-Path $userDir "msp\signcerts\Admin@$Domain-cert.pem"
    $keyDir = Join-Path $userDir "msp\keystore"
    $keyPath = Get-ChildItem -Path $keyDir -Filter "*_sk" | Select-Object -First 1 | ForEach-Object { $_.FullName }
    
    if (!(Test-Path $certPath) -or !(Test-Path $keyPath)) {
        Write-Host "Warning: Certificate or key not found for $Org" -ForegroundColor Yellow
        return
    }
    
    $cert = Get-Content -Path $certPath -Raw
    $key = Get-Content -Path $keyPath -Raw
    $identityFile = Join-Path $WALLET_PATH "admin-$Org.id"
    
    $identity = @{
        credentials = @{
            certificate = $cert
            privateKey = $key
        }
        mspId = "${Org}MSP"
        type = "X.509"
    } | ConvertTo-Json -Depth 10
    
    $identity | Out-File -FilePath $identityFile -Encoding utf8 -NoNewline
    Write-Host "Created identity for admin-$Org" -ForegroundColor Green
}

foreach ($org in $ORGS.Keys) {
    Create-Identity -Org $org -Domain $ORGS[$org]
}

Write-Host "Wallet setup complete!" -ForegroundColor Cyan
