# Simple Wallet Setup - Just copy crypto materials
$ErrorActionPreference = "Stop"

$walletPath = "d:\Trial\HerbalTrace\network\wallet"
$orgPath = "d:\Trial\HerbalTrace\network\organizations\peerOrganizations"

Write-Host "Creating wallet directory..." -ForegroundColor Green
New-Item -ItemType Directory -Path $walletPath -Force | Out-Null

$orgs = @{
    "FarmersCoop" = "farmers.herbaltrace.com"
    "TestingLabs" = "labs.herbaltrace.com"  
    "Processors" = "processors.herbaltrace.com"
    "Manufacturers" = "manufacturers.herbaltrace.com"
}

foreach ($org in $orgs.Keys) {
    Write-Host "Processing $org..." -ForegroundColor Yellow
    
    $domain = $orgs[$org]
    $adminPath = Join-Path $orgPath "$domain\users\Admin@$domain"
    
    if (!(Test-Path $adminPath)) {
        Write-Host "  Skipping - not found" -ForegroundColor Red
        continue
    }
    
    $certFile = Join-Path $adminPath "msp\signcerts\Admin@$domain-cert.pem"
    $keyFiles = Get-ChildItem -Path (Join-Path $adminPath "msp\keystore") -Filter "*_sk"
    
    if ($keyFiles.Count -eq 0) {
        Write-Host "  Skipping - no key found" -ForegroundColor Red
        continue
    }
    
    $keyFile = $keyFiles[0].FullName
    
    # Read files
    $cert = [System.IO.File]::ReadAllText($certFile)
    $key = [System.IO.File]::ReadAllText($keyFile)
    
    # Create simple JSON manually
    $json = "{`n"
    $json += '  "credentials": {' + "`n"
    $json += '    "certificate": ' + (ConvertTo-Json $cert) + ",`n"
    $json += '    "privateKey": ' + (ConvertTo-Json $key) + "`n"
    $json += "  },`n"
    $json += '  "mspId": "' + $org + 'MSP",' + "`n"
    $json += '  "type": "X.509"' + "`n"
    $json += "}`n"
    
    # Save
    $outFile = Join-Path $walletPath "admin-$org.id"
    [System.IO.File]::WriteAllText($outFile, $json)
    
    Write-Host "  Created admin-$org.id" -ForegroundColor Green
}

Write-Host "`nWallet setup complete!" -ForegroundColor Cyan
Write-Host "Location: $walletPath" -ForegroundColor Cyan
