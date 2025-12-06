# Test Authentication API Endpoints

Write-Host "`n=== Testing HerbalTrace Authentication API ===" -ForegroundColor Green

# Test 1: Admin Login
Write-Host "`n1. Testing Admin Login..." -ForegroundColor Cyan
$loginBody = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    Write-Host "✅ Login Successful!" -ForegroundColor Green
    Write-Host "Token: $($loginResponse.data.token.Substring(0, 50))..." -ForegroundColor Yellow
    Write-Host "Refresh Token: $($loginResponse.data.refreshToken.Substring(0, 50))..." -ForegroundColor Yellow
    $token = $loginResponse.data.token
} catch {
    Write-Host "❌ Login Failed: $_" -ForegroundColor Red
    exit 1
}

# Test 2: Get Current User Profile
Write-Host "`n2. Testing Get Profile (/me)..." -ForegroundColor Cyan
$headers = @{
    Authorization = "Bearer $token"
}

try {
    $profileResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/me" -Method Get -Headers $headers
    Write-Host "✅ Profile Retrieved!" -ForegroundColor Green
    Write-Host "User ID: $($profileResponse.data.user_id)" -ForegroundColor Yellow
    Write-Host "Username: $($profileResponse.data.username)" -ForegroundColor Yellow
    Write-Host "Full Name: $($profileResponse.data.full_name)" -ForegroundColor Yellow
    Write-Host "Role: $($profileResponse.data.role)" -ForegroundColor Yellow
} catch {
    Write-Host "❌ Profile Failed: $_" -ForegroundColor Red
}

# Test 3: Create Registration Request
Write-Host "`n3. Testing Registration Request..." -ForegroundColor Cyan
$regBody = @{
    fullName = "Test Farmer"
    phone = "1234567890"
    email = "farmer@test.com"
    address = "Test Farm Location"
    requestType = "farmer"
    farmSize = "5 acres"
    speciesInterest = @("tulsi", "ashwagandha")
    farmPhotos = @("photo1.jpg", "photo2.jpg")
} | ConvertTo-Json

try {
    $regResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/registration-request" -Method Post -Body $regBody -ContentType "application/json"
    Write-Host "✅ Registration Request Created!" -ForegroundColor Green
    Write-Host "Request ID: $($regResponse.data.requestId)" -ForegroundColor Yellow
    Write-Host "Status: $($regResponse.data.status)" -ForegroundColor Yellow
    $requestId = $regResponse.data.requestId
} catch {
    Write-Host "❌ Registration Failed: $_" -ForegroundColor Red
}

# Test 4: List Registration Requests (Admin)
Write-Host "`n4. Testing List Registration Requests (Admin)..." -ForegroundColor Cyan
try {
    $listResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/registration-requests" -Method Get -Headers $headers
    Write-Host "✅ Registration Requests Retrieved!" -ForegroundColor Green
    Write-Host "Total Requests: $($listResponse.count)" -ForegroundColor Yellow
    if ($listResponse.data.Count -gt 0) {
        Write-Host "Latest Request: $($listResponse.data[0].full_name) ($($listResponse.data[0].status))" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ List Requests Failed: $_" -ForegroundColor Red
}

# Test 5: Approve Registration Request
if ($requestId) {
    Write-Host "`n5. Testing Approve Registration Request (Admin)..." -ForegroundColor Cyan
    $approveBody = @{
        role = "Farmer"
        orgName = "FarmerOrg"
    } | ConvertTo-Json
    
    try {
        $approveResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/auth/registration-requests/$requestId/approve" -Method Post -Headers $headers -Body $approveBody -ContentType "application/json"
        Write-Host "✅ Registration Request Approved!" -ForegroundColor Green
        Write-Host "New User ID: $($approveResponse.data.userId)" -ForegroundColor Yellow
        Write-Host "Username: $($approveResponse.data.username)" -ForegroundColor Yellow
        Write-Host "Temporary Password: $($approveResponse.data.temporaryPassword)" -ForegroundColor Yellow
    } catch {
        Write-Host "❌ Approval Failed: $_" -ForegroundColor Red
    }
}

Write-Host "`n=== Authentication API Tests Complete ===" -ForegroundColor Green
Write-Host "`nNote: Keep the server running for further tests.`n" -ForegroundColor Yellow
