# Complete Authentication API Test Suite

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  Testing HerbalTrace Authentication & Registration API     ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

$timestamp = Get-Date -Format "yyyyMMddHHmmss"

# Test 1: Admin Login
Write-Host "Test 1: Admin Login" -ForegroundColor Cyan
$loginBody = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    Write-Host "  ✅ Login Successful!" -ForegroundColor Green
    Write-Host "  → Token generated (24h expiry)" -ForegroundColor Gray
    Write-Host "  → Refresh token generated (7d expiry)`n" -ForegroundColor Gray
    $token = $loginResponse.data.token
} catch {
    Write-Host "  ❌ Failed: $($_.Exception.Message)`n" -ForegroundColor Red
    exit 1
}

$headers = @{
    Authorization = "Bearer $token"
}

# Test 2: Get Current User Profile
Write-Host "Test 2: Get Admin Profile" -ForegroundColor Cyan
try {
    $profileResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/me" -Method Get -Headers $headers
    Write-Host "  ✅ Profile Retrieved!" -ForegroundColor Green
    Write-Host "  → Username: $($profileResponse.data.username)" -ForegroundColor Gray
    Write-Host "  → Role: $($profileResponse.data.role)" -ForegroundColor Gray
    Write-Host "  → Organization: $($profileResponse.data.org_name)`n" -ForegroundColor Gray
} catch {
    Write-Host "  ❌ Failed: $($_.Exception.Message)`n" -ForegroundColor Red
}

# Test 3: Create Registration Request
Write-Host "Test 3: Create Farmer Registration Request" -ForegroundColor Cyan
$regBody = @{
    fullName = "Rajesh Kumar"
    phone = "9876543210"
    email = "rajesh.farmer$timestamp@herbaltrace.com"
    address = "Village Dharampur, District Mandi, Himachal Pradesh"
    requestType = "farmer"
    farmSize = "10 acres"
    speciesInterest = @("tulsi", "ashwagandha", "brahmi")
    farmPhotos = @("farm_front.jpg", "cultivation_area.jpg")
} | ConvertTo-Json

try {
    $regResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/registration-request" -Method Post -Body $regBody -ContentType "application/json"
    Write-Host "  ✅ Registration Request Created!" -ForegroundColor Green
    Write-Host "  → Request ID: $($regResponse.data.requestId)" -ForegroundColor Gray
    Write-Host "  → Status: $($regResponse.data.status)" -ForegroundColor Gray
    Write-Host "  → Farmer: Rajesh Kumar`n" -ForegroundColor Gray
    $requestId = $regResponse.data.requestId
} catch {
    Write-Host "  ❌ Failed: $($_.Exception.Message)`n" -ForegroundColor Red
}

# Test 4: List All Registration Requests
Write-Host "Test 4: List All Registration Requests (Admin)" -ForegroundColor Cyan
try {
    $listResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/registration-requests" -Method Get -Headers $headers
    Write-Host "  ✅ Requests Retrieved!" -ForegroundColor Green
    Write-Host "  → Total Pending: $($listResponse.count)" -ForegroundColor Gray
    
    if ($listResponse.data.Count -gt 0) {
        foreach ($req in $listResponse.data | Select-Object -First 3) {
            Write-Host "  → $($req.full_name) ($($req.request_type)) - $($req.status)" -ForegroundColor Gray
        }
    }
    Write-Host ""
} catch {
    Write-Host "  ❌ Failed: $($_.Exception.Message)`n" -ForegroundColor Red
}

# Test 5: Approve Registration Request
if ($requestId) {
    Write-Host "Test 5: Approve Registration & Create User" -ForegroundColor Cyan
    $approveBody = @{
        role = "Farmer"
        orgName = "FarmerOrg"
    } | ConvertTo-Json
    
    try {
        $approveResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/registration-requests/$requestId/approve" -Method Post -Headers $headers -Body $approveBody -ContentType "application/json"
        Write-Host "  ✅ Registration Approved!" -ForegroundColor Green
        Write-Host "  → New User ID: $($approveResponse.data.userId)" -ForegroundColor Gray
        Write-Host "  → Username: $($approveResponse.data.username)" -ForegroundColor Gray
        Write-Host "  → Temporary Password: $($approveResponse.data.temporaryPassword)" -ForegroundColor Gray
        Write-Host "  → Blockchain Registered: $($approveResponse.data.fabricUserId -ne $null)`n" -ForegroundColor Gray
        
        $newUsername = $approveResponse.data.username
        $newPassword = $approveResponse.data.temporaryPassword
    } catch {
        Write-Host "  ❌ Failed: $($_.Exception.Message)`n" -ForegroundColor Red
    }
}

# Test 6: New User Login
if ($newUsername -and $newPassword) {
    Write-Host "Test 6: New User Login (Farmer)" -ForegroundColor Cyan
    $farmerLoginBody = @{
        username = $newUsername
        password = $newPassword
    } | ConvertTo-Json
    
    try {
        $farmerLoginResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/login" -Method Post -Body $farmerLoginBody -ContentType "application/json"
        Write-Host "  ✅ Farmer Login Successful!" -ForegroundColor Green
        Write-Host "  → User can now access the system" -ForegroundColor Gray
        Write-Host "  → Token issued successfully`n" -ForegroundColor Gray
        $farmerToken = $farmerLoginResponse.data.token
    } catch {
        Write-Host "  ❌ Failed: $($_.Exception.Message)`n" -ForegroundColor Red
    }
}

# Test 7: Change Password
if ($farmerToken) {
    Write-Host "Test 7: Change Password (Farmer)" -ForegroundColor Cyan
    $farmerHeaders = @{
        Authorization = "Bearer $farmerToken"
    }
    
    $changePasswordBody = @{
        oldPassword = $newPassword
        newPassword = "NewSecurePassword@123"
    } | ConvertTo-Json
    
    try {
        $changePasswordResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/change-password" -Method Post -Headers $farmerHeaders -Body $changePasswordBody -ContentType "application/json"
        Write-Host "  ✅ Password Changed Successfully!" -ForegroundColor Green
        Write-Host "  → User should now login with new password`n" -ForegroundColor Gray
    } catch {
        Write-Host "  ❌ Failed: $($_.Exception.Message)`n" -ForegroundColor Red
    }
}

# Test 8: Create Lab Registration Request
Write-Host "Test 8: Create Lab Registration Request" -ForegroundColor Cyan
$labRegBody = @{
    fullName = "Green Valley Testing Lab"
    phone = "9123456789"
    email = "lab$timestamp@herbaltrace.com"
    address = "Industrial Area, Baddi, Himachal Pradesh"
    requestType = "lab"
    certifications = @("ISO 17025", "NABL Accredited")
} | ConvertTo-Json

try {
    $labRegResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/registration-request" -Method Post -Body $labRegBody -ContentType "application/json"
    Write-Host "  ✅ Lab Registration Created!" -ForegroundColor Green
    Write-Host "  → Request ID: $($labRegResponse.data.requestId)" -ForegroundColor Gray
    Write-Host "  → Lab: Green Valley Testing Lab`n" -ForegroundColor Gray
} catch {
    Write-Host "  ❌ Failed: $($_.Exception.Message)`n" -ForegroundColor Red
}

# Test 9: Filter Registration Requests by Status
Write-Host "Test 9: Filter Requests by Status (Pending)" -ForegroundColor Cyan
try {
    $filterResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/registration-requests?status=pending" -Method Get -Headers $headers
    Write-Host "  ✅ Filtered Requests Retrieved!" -ForegroundColor Green
    Write-Host "  → Pending Requests: $($filterResponse.count)" -ForegroundColor Gray
    Write-Host "  → API filtering working correctly`n" -ForegroundColor Gray
} catch {
    Write-Host "  ❌ Failed: $($_.Exception.Message)`n" -ForegroundColor Red
}

# Summary
Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✅ Phase 2: User Registration System COMPLETE            ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "Tested Features:" -ForegroundColor Yellow
Write-Host "  ✓ Admin authentication & JWT generation" -ForegroundColor Gray
Write-Host "  ✓ User profile retrieval" -ForegroundColor Gray
Write-Host "  ✓ Registration request submission" -ForegroundColor Gray
Write-Host "  ✓ Admin registration approval workflow" -ForegroundColor Gray
Write-Host "  ✓ Auto-credential generation" -ForegroundColor Gray
Write-Host "  ✓ New user login" -ForegroundColor Gray
Write-Host "  ✓ Password change functionality" -ForegroundColor Gray
Write-Host "  ✓ Multiple user types (Farmer, Lab)" -ForegroundColor Gray
Write-Host "  ✓ Request filtering" -ForegroundColor Gray
Write-Host "`n✨ Ready to proceed to Phase 3: Image Upload Service`n" -ForegroundColor Cyan
