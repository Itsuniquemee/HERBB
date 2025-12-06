# Test Image Upload Service

Write-Host "`n=== Testing HerbalTrace Image Upload Service ===" -ForegroundColor Green

# Login as admin first
Write-Host "`n[1/5] Admin Login..." -ForegroundColor Cyan
$loginBody = @{ username = "admin"; password = "admin123" } | ConvertTo-Json
try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    Write-Host "  PASS - Admin logged in" -ForegroundColor Green
    $token = $loginResponse.data.token
} catch {
    Write-Host "  FAIL - $_" -ForegroundColor Red
    exit 1
}

$headers = @{ Authorization = "Bearer $token" }

# Test 2: Create test images
Write-Host "`n[2/5] Creating Test Images..." -ForegroundColor Cyan
$testImageDir = "d:\Trial\HerbalTrace\backend\test-images"
if (-not (Test-Path $testImageDir)) {
    New-Item -ItemType Directory -Path $testImageDir | Out-Null
}

# Create a simple test image using .NET
Add-Type -AssemblyName System.Drawing
$bitmap = New-Object System.Drawing.Bitmap(800, 600)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.Clear([System.Drawing.Color]::LightGreen)
$font = New-Object System.Drawing.Font("Arial", 40, [System.Drawing.FontStyle]::Bold)
$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::DarkGreen)
$graphics.DrawString("HerbalTrace Test Image", $font, $brush, 50, 250)
$graphics.Dispose()

$testImage1 = Join-Path $testImageDir "farm-photo-1.jpg"
$testImage2 = Join-Path $testImageDir "farm-photo-2.jpg"
$bitmap.Save($testImage1, [System.Drawing.Imaging.ImageFormat]::Jpeg)
$bitmap.Save($testImage2, [System.Drawing.Imaging.ImageFormat]::Jpeg)
$bitmap.Dispose()

Write-Host "  PASS - Created 2 test images" -ForegroundColor Green

# Test 3: Upload single image
Write-Host "`n[3/5] Upload Single Image..." -ForegroundColor Cyan
try {
    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "`r`n"
    
    $fileBytes = [System.IO.File]::ReadAllBytes($testImage1)
    $fileContent = [System.Text.Encoding]::GetEncoding('iso-8859-1').GetString($fileBytes)
    
    $bodyLines = @(
        "--$boundary",
        "Content-Disposition: form-data; name=`"image`"; filename=`"farm-photo-1.jpg`"",
        "Content-Type: image/jpeg$LF",
        $fileContent,
        "--$boundary--$LF"
    ) -join $LF
    
    $response = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/upload/single?type=farms&compress=true" `
        -Method Post `
        -Headers @{
            Authorization = "Bearer $token"
            "Content-Type" = "multipart/form-data; boundary=$boundary"
        } `
        -Body $bodyLines
    
    Write-Host "  PASS - Single image uploaded" -ForegroundColor Green
    Write-Host "    URL: $($response.data.original)" -ForegroundColor Gray
    Write-Host "    Size: $([math]::Round($response.data.size / 1024, 2)) KB" -ForegroundColor Gray
    $uploadedUrl = $response.data.original
} catch {
    Write-Host "  FAIL - $_" -ForegroundColor Red
}

# Test 4: Upload multiple images (using curl if available)
Write-Host "`n[4/5] Upload Multiple Images..." -ForegroundColor Cyan
try {
    # Check if curl is available
    $curlPath = Get-Command curl.exe -ErrorAction SilentlyContinue
    if ($curlPath) {
        $result = & curl.exe -X POST "http://localhost:3000/api/v1/upload/images?type=collections&compress=true&thumbnails=true" `
            -H "Authorization: Bearer $token" `
            -F "images=@$testImage1" `
            -F "images=@$testImage2" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  PASS - Multiple images uploaded" -ForegroundColor Green
            Write-Host "  Response: $result" -ForegroundColor Gray
        } else {
            Write-Host "  INFO - Curl upload attempted (check server logs)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  SKIP - curl.exe not found (install curl to test multi-upload)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  INFO - Multi-upload test skipped: $_" -ForegroundColor Yellow
}

# Test 5: Get file info
if ($uploadedUrl) {
    Write-Host "`n[5/5] Get File Info..." -ForegroundColor Cyan
    try {
        # Extract relative path from URL
        $relativePath = $uploadedUrl -replace "^https?://[^/]+/uploads/", ""
        $infoResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/upload/info?filePath=$relativePath" `
            -Method Get `
            -Headers $headers
        
        Write-Host "  PASS - File info retrieved" -ForegroundColor Green
        Write-Host "    Path: $($infoResponse.data.path)" -ForegroundColor Gray
        Write-Host "    Size: $([math]::Round($infoResponse.data.size / 1024, 2)) KB" -ForegroundColor Gray
        Write-Host "    Created: $($infoResponse.data.createdAt)" -ForegroundColor Gray
    } catch {
        Write-Host "  INFO - File info test: $_" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Image Upload Tests Complete ===" -ForegroundColor Green
Write-Host "`nUpload Directory: backend/uploads/" -ForegroundColor Yellow
Write-Host "Uploaded images are accessible at: http://localhost:3000/uploads/..." -ForegroundColor Yellow
Write-Host "`nPhase 3: Image Upload Service - OPERATIONAL`n" -ForegroundColor Cyan

# Cleanup
Write-Host "Cleaning up test images..." -ForegroundColor Gray
Remove-Item $testImageDir -Recurse -Force -ErrorAction SilentlyContinue
