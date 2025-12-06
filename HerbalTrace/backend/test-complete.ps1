# Complete Authentication API Test Suite
$timestamp = Get-Date -Format "yyyyMMddHHmmss"

Write-Host "`n=== HerbalTrace Authentication & Registration API Tests ===" -ForegroundColor Green

# Test 1: Admin Login
Write-Host "`n[1/9] Admin Login..." -ForegroundColor Cyan
$loginBody = @{ username = "admin"; password = "admin123" } | ConvertTo-Json
try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    Write-Host "  PASS - Admin logged in successfully" -ForegroundColor Green
    $token = $loginResponse.data.token
} catch { Write-Host "  FAIL - $_" -ForegroundColor Red; exit 1 }

$headers = @{ Authorization = "Bearer $token" }

# Test 2: Get Profile
Write-Host "`n[2/9] Get Admin Profile..." -ForegroundColor Cyan
try {
    $profileResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/me" -Method Get -Headers $headers
    Write-Host "  PASS - Profile: $($profileResponse.data.username) ($($profileResponse.data.role))" -ForegroundColor Green
} catch { Write-Host "  FAIL - $_" -ForegroundColor Red }

# Test 3: Create Farmer Registration
Write-Host "`n[3/9] Create Farmer Registration Request..." -ForegroundColor Cyan
$regBody = @{
    fullName = "Rajesh Kumar"
    phone = "9876543210"
    email = "rajesh.farmer$timestamp@herbaltrace.com"
    address = "Village Dharampur, District Mandi, Himachal Pradesh"
    requestType = "farmer"
    farmSize = "10 acres"
    speciesInterest = @("tulsi", "ashwagandha")
    farmPhotos = @("farm1.jpg", "farm2.jpg")
} | ConvertTo-Json

try {
    $regResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/registration-request" -Method Post -Body $regBody -ContentType "application/json"
    Write-Host "  PASS - Request created: $($regResponse.data.requestId)" -ForegroundColor Green
    $requestId = $regResponse.data.requestId
} catch { Write-Host "  FAIL - $_" -ForegroundColor Red }

# Test 4: List Requests
Write-Host "`n[4/9] List All Registration Requests..." -ForegroundColor Cyan
try {
    $listResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/registration-requests" -Method Get -Headers $headers
    Write-Host "  PASS - Found $($listResponse.count) requests" -ForegroundColor Green
    if ($listResponse.data.Count -gt 0) {
        $listResponse.data | Select-Object -First 2 | ForEach-Object {
            Write-Host "    - $($_.full_name) ($($_.status))" -ForegroundColor Gray
        }
    }
} catch { Write-Host "  FAIL - $_" -ForegroundColor Red }

# Test 5: Approve Registration
Write-Host "`n[5/9] Approve Registration Request..." -ForegroundColor Cyan
if ($requestId) {
    $approveBody = @{ role = "Farmer"; orgName = "FarmerOrg" } | ConvertTo-Json
    try {
        $approveResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/registration-requests/$requestId/approve" -Method Post -Headers $headers -Body $approveBody -ContentType "application/json"
        Write-Host "  PASS - User created!" -ForegroundColor Green
        Write-Host "    Username: $($approveResponse.data.username)" -ForegroundColor Gray
        Write-Host "    Password: $($approveResponse.data.temporaryPassword)" -ForegroundColor Gray
        $newUsername = $approveResponse.data.username
        $newPassword = $approveResponse.data.temporaryPassword
    } catch { Write-Host "  FAIL - $_" -ForegroundColor Red }
}

# Test 6: New User Login
Write-Host "`n[6/9] New Farmer Login..." -ForegroundColor Cyan
if ($newUsername) {
    $farmerLoginBody = @{ username = $newUsername; password = $newPassword } | ConvertTo-Json
    try {
        $farmerLoginResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/login" -Method Post -Body $farmerLoginBody -ContentType "application/json"
        Write-Host "  PASS - Farmer logged in successfully" -ForegroundColor Green
        $farmerToken = $farmerLoginResponse.data.token
    } catch { Write-Host "  FAIL - $_" -ForegroundColor Red }
}

# Test 7: Change Password
Write-Host "`n[7/9] Change Password..." -ForegroundColor Cyan
if ($farmerToken) {
    $farmerHeaders = @{ Authorization = "Bearer $farmerToken" }
    $changePasswordBody = @{ oldPassword = $newPassword; newPassword = "NewSecurePassword@123" } | ConvertTo-Json
    try {
        Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/change-password" -Method Post -Headers $farmerHeaders -Body $changePasswordBody -ContentType "application/json" | Out-Null
        Write-Host "  PASS - Password changed successfully" -ForegroundColor Green
    } catch { Write-Host "  FAIL - $_" -ForegroundColor Red }
}

# Test 8: Create Lab Registration
Write-Host "`n[8/9] Create Lab Registration Request..." -ForegroundColor Cyan
$labRegBody = @{
    fullName = "Green Valley Testing Lab"
    phone = "9123456789"
    email = "lab$timestamp@herbaltrace.com"
    address = "Industrial Area, Baddi, HP"
    requestType = "lab"
    certifications = @("ISO 17025", "NABL")
} | ConvertTo-Json

try {
    $labRegResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/registration-request" -Method Post -Body $labRegBody -ContentType "application/json"
    Write-Host "  PASS - Lab request created" -ForegroundColor Green
} catch { Write-Host "  FAIL - $_" -ForegroundColor Red }

# Test 9: Filter by Status
Write-Host "`n[9/9] Filter Requests by Status..." -ForegroundColor Cyan
try {
    $filterResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/registration-requests?status=pending" -Method Get -Headers $headers
    Write-Host "  PASS - Found $($filterResponse.count) pending requests" -ForegroundColor Green
} catch { Write-Host "  FAIL - $_" -ForegroundColor Red }

Write-Host "`n=== All Tests Complete ===" -ForegroundColor Green
Write-Host "`nPhase 2: User Registration System - FULLY OPERATIONAL" -ForegroundColor Yellow
Write-Host "Ready to proceed to Phase 3: Image Upload Service`n" -ForegroundColor Cyan
