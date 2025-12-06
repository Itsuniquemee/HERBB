# Phase 7: Analytics & Reporting System Test Script
# Tests all analytics endpoints

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Phase 7: Analytics System Tests" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:3000/api/v1"
$token = ""

# Test counter
$testsPassed = 0
$testsFailed = 0

# Helper function to make API calls
function Invoke-ApiTest {
    param(
        [string]$Method,
        [string]$Endpoint,
        [string]$Description,
        [hashtable]$Body = @{},
        [bool]$RequiresAuth = $true
    )
    
    Write-Host "[$($testsPassed + $testsFailed + 1)] $Description..." -ForegroundColor Yellow
    
    try {
        $headers = @{
            "Content-Type" = "application/json"
        }
        
        if ($RequiresAuth -and $token) {
            $headers["Authorization"] = "Bearer $token"
        }
        
        $params = @{
            Uri = "$baseUrl$Endpoint"
            Method = $Method
            Headers = $headers
            UseBasicParsing = $true
            TimeoutSec = 10
        }
        
        if ($Body.Count -gt 0) {
            $params.Body = ($Body | ConvertTo-Json -Depth 10)
        }
        
        $response = Invoke-RestMethod @params
        
        if ($response.success) {
            Write-Host "   ✅ PASS" -ForegroundColor Green
            $script:testsPassed++
            return $response
        } else {
            Write-Host "   ❌ FAIL: $($response.message)" -ForegroundColor Red
            $script:testsFailed++
            return $null
        }
    } catch {
        Write-Host "   ❌ FAIL: $($_.Exception.Message)" -ForegroundColor Red
        $script:testsFailed++
        return $null
    }
}

# Step 1: Login
Write-Host "[1/10] Logging in as admin..." -ForegroundColor Yellow
try {
    $loginBody = @{
        username = "admin"
        password = "Admin@123"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginBody -ContentType "application/json" -UseBasicParsing
    $token = $loginResponse.data.token
    Write-Host "   ✅ Login successful" -ForegroundColor Green
    $testsPassed++
} catch {
    Write-Host "   ❌ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Cannot proceed without authentication" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 2: Test Dashboard Endpoint
$dashboardResponse = Invoke-ApiTest -Method GET -Endpoint "/analytics/dashboard" -Description "Get dashboard data"
if ($dashboardResponse) {
    Write-Host "   Dashboard stats:" -ForegroundColor Gray
    Write-Host "   - From cache: $($dashboardResponse.data.from_cache)" -ForegroundColor Gray
    Write-Host "   - Total tests: $($dashboardResponse.data.qc_metrics.total_tests)" -ForegroundColor Gray
    Write-Host "   - Success rate: $($dashboardResponse.data.qc_metrics.success_rate)%" -ForegroundColor Gray
}

Write-Host ""

# Step 3: Test QC Metrics
$qcMetricsResponse = Invoke-ApiTest -Method GET -Endpoint "/analytics/qc-metrics" -Description "Get QC metrics"
if ($qcMetricsResponse) {
    Write-Host "   QC Metrics:" -ForegroundColor Gray
    Write-Host "   - Total tests: $($qcMetricsResponse.data.total_tests)" -ForegroundColor Gray
    Write-Host "   - Completed: $($qcMetricsResponse.data.completed_tests)" -ForegroundColor Gray
    Write-Host "   - Success rate: $($qcMetricsResponse.data.success_rate)%" -ForegroundColor Gray
    Write-Host "   - Avg completion time: $($qcMetricsResponse.data.avg_completion_time) hours" -ForegroundColor Gray
}

Write-Host ""

# Step 4: Test Lab Performance
$labPerfResponse = Invoke-ApiTest -Method GET -Endpoint "/analytics/lab-performance" -Description "Get lab performance"
if ($labPerfResponse) {
    Write-Host "   Lab Performance:" -ForegroundColor Gray
    Write-Host "   - Total labs: $($labPerfResponse.data.Count)" -ForegroundColor Gray
    if ($labPerfResponse.data.Count -gt 0) {
        Write-Host "   - Top lab: $($labPerfResponse.data[0].lab_name)" -ForegroundColor Gray
        Write-Host "   - Success rate: $($labPerfResponse.data[0].success_rate)%" -ForegroundColor Gray
    }
}

Write-Host ""

# Step 5: Test Batch Quality Scores
$batchQualityResponse = Invoke-ApiTest -Method GET -Endpoint "/analytics/batch-quality" -Description "Get batch quality scores"
if ($batchQualityResponse) {
    Write-Host "   Batch Quality:" -ForegroundColor Gray
    Write-Host "   - Total batches: $($batchQualityResponse.data.Count)" -ForegroundColor Gray
    if ($batchQualityResponse.data.Count -gt 0) {
        Write-Host "   - First batch score: $($batchQualityResponse.data[0].quality_score)" -ForegroundColor Gray
        Write-Host "   - Compliance: $($batchQualityResponse.data[0].compliance_status)" -ForegroundColor Gray
    }
}

Write-Host ""

# Step 6: Test Trend Data
$trendResponse = Invoke-ApiTest -Method GET -Endpoint "/analytics/trends/QC_SUCCESS_RATE?period=WEEK" -Description "Get trend data for QC success rate"
if ($trendResponse) {
    Write-Host "   Trend Data:" -ForegroundColor Gray
    Write-Host "   - Metric: $($trendResponse.data.metric_type)" -ForegroundColor Gray
    Write-Host "   - Period: $($trendResponse.data.period)" -ForegroundColor Gray
    Write-Host "   - Data points: $($trendResponse.data.trends.Count)" -ForegroundColor Gray
}

Write-Host ""

# Step 7: Test Cost Analysis
$costAnalysisResponse = Invoke-ApiTest -Method GET -Endpoint "/analytics/cost-analysis" -Description "Get cost analysis"
if ($costAnalysisResponse) {
    Write-Host "   Cost Analysis:" -ForegroundColor Gray
    Write-Host "   - Total tests: $($costAnalysisResponse.data.total_tests)" -ForegroundColor Gray
    Write-Host "   - Total cost: `$$($costAnalysisResponse.data.total_cost)" -ForegroundColor Gray
    Write-Host "   - Avg per test: `$$($costAnalysisResponse.data.avg_cost_per_test)" -ForegroundColor Gray
    Write-Host "   - Breakdown items: $($costAnalysisResponse.data.breakdown.Count)" -ForegroundColor Gray
}

Write-Host ""

# Step 8: Test Metrics Storage
$metricsResponse = Invoke-ApiTest -Method GET -Endpoint "/analytics/metrics?limit=10" -Description "Get stored metrics"
if ($metricsResponse) {
    Write-Host "   Stored Metrics:" -ForegroundColor Gray
    Write-Host "   - Total: $($metricsResponse.pagination.total)" -ForegroundColor Gray
    Write-Host "   - Retrieved: $($metricsResponse.data.Count)" -ForegroundColor Gray
}

Write-Host ""

# Step 9: Test Cache Cleaning
$cacheCleanResponse = Invoke-ApiTest -Method POST -Endpoint "/analytics/cache/clean" -Description "Clean expired cache"
if ($cacheCleanResponse) {
    Write-Host "   Cache Cleanup:" -ForegroundColor Gray
    Write-Host "   - Entries deleted: $($cacheCleanResponse.data.deleted)" -ForegroundColor Gray
}

Write-Host ""

# Step 10: Test Export (JSON)
$exportResponse = Invoke-ApiTest -Method GET -Endpoint "/analytics/export/json?type=qc-metrics" -Description "Export analytics data as JSON"
if ($exportResponse) {
    Write-Host "   Export Data:" -ForegroundColor Gray
    Write-Host "   - Format: JSON" -ForegroundColor Gray
    Write-Host "   - Type: QC Metrics" -ForegroundColor Gray
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Phase 7 Tests Complete!" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Summary
Write-Host "Test Results:" -ForegroundColor White
Write-Host "✅ Passed: $testsPassed" -ForegroundColor Green
Write-Host "❌ Failed: $testsFailed" -ForegroundColor Red
Write-Host ""

if ($testsFailed -eq 0) {
    Write-Host "🎉 All tests passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Analytics Features:" -ForegroundColor Cyan
    Write-Host "  - Dashboard with comprehensive metrics" -ForegroundColor White
    Write-Host "  - QC success rate tracking" -ForegroundColor White
    Write-Host "  - Lab performance analytics" -ForegroundColor White
    Write-Host "  - Batch quality scoring" -ForegroundColor White
    Write-Host "  - Trend analysis (daily/weekly/monthly/quarterly)" -ForegroundColor White
    Write-Host "  - Cost analysis and reporting" -ForegroundColor White
    Write-Host "  - Metric storage and retrieval" -ForegroundColor White
    Write-Host "  - Dashboard caching for performance" -ForegroundColor White
    Write-Host "  - Data export (JSON/CSV)" -ForegroundColor White
    Write-Host ""
    Write-Host "Ready for Phase 8: Blockchain Integration" -ForegroundColor Yellow
} else {
    Write-Host "⚠️  Some tests failed. Please review the errors above." -ForegroundColor Yellow
}
