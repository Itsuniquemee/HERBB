# Quick Wallet Setup for HerbalTrace Backend
# Should complete in under 10 seconds

$ErrorActionPreference = "Stop"

Write-Host "Setting up wallet..." -ForegroundColor Green

# Create wallet directory
$walletPath = "..\network\wallet"
New-Item -ItemType Directory -Path $walletPath -Force | Out-Null

# Copy admin certificates directly
$orgs = @{
    "farmers" = "FarmersCoopMSP"
    "labs" = "TestingLabsMSP"
    "processors" = "ProcessorsMSP"
    "manufacturers" = "ManufacturersMSP"
}

foreach ($org in $orgs.Keys) {
    $mspId = $orgs[$org]
    $orgPath = "..\network\organizations\peerOrganizations\$org.herbaltrace.com"
    $adminPath = "$orgPath\users\Admin@$org.herbaltrace.com\msp"
    
    Write-Host "Processing $org..." -NoNewline
    
    if (Test-Path $adminPath) {
        # Get certificate
        $certFile = Get-ChildItem "$adminPath\signcerts\*.pem" | Select-Object -First 1
        $cert = Get-Content $certFile.FullName -Raw
        
        # Get private key
        $keyFile = Get-ChildItem "$adminPath\keystore\*_sk" | Select-Object -First 1
        $key = Get-Content $keyFile.FullName -Raw
        
        # Create simple identity file (Node.js Fabric SDK format)
        $identity = @{
            credentials = @{
                certificate = $cert
                privateKey = $key
            }
            mspId = $mspId
            type = "X.509"
        }
        
        $identityJson = $identity | ConvertTo-Json -Depth 10
        $identityFile = "$walletPath\admin-$org.id"
        $identityJson | Out-File -FilePath $identityFile -Encoding utf8
        
        Write-Host " Done" -ForegroundColor Green
    } else {
        Write-Host " Not found" -ForegroundColor Yellow
    }
}

Write-Host "`nWallet setup complete! Location: $walletPath" -ForegroundColor Cyan
Write-Host "Starting backend server now..." -ForegroundColor Yellow
