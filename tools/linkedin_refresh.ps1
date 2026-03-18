<#
Refresh LinkedIn access token using refresh token
Usage: .\tools\linkedin_refresh.ps1
Run this before the token expires (60 days). The refresh token lasts 1 year.
#>

$envFile = Join-Path $PSScriptRoot "../.env"
Get-Content $envFile | Where-Object { $_ -match "^LINKEDIN_" } | ForEach-Object {
    $p = $_ -split "=", 2
    [System.Environment]::SetEnvironmentVariable($p[0].Trim(), $p[1].Trim())
}

$clientId     = $env:LINKEDIN_CLIENT_ID
$clientSecret = $env:LINKEDIN_CLIENT_SECRET
$refreshToken = $env:LINKEDIN_REFRESH_TOKEN
$expiryDate   = $env:LINKEDIN_TOKEN_EXPIRY

if (-not $refreshToken) {
    Write-Host "No refresh token found. Run linkedin_auth.ps1 to get a new token."
    exit 1
}

# Check if refresh is needed
if ($expiryDate) {
    $expiry = [DateTime]::Parse($expiryDate)
    $daysLeft = ($expiry - (Get-Date)).Days
    Write-Host "Current token expires: $expiryDate ($daysLeft days left)"
    if ($daysLeft -gt 7) {
        Write-Host "Token still valid. No refresh needed."
        exit 0
    }
    Write-Host "Token expiring soon. Refreshing..."
}

$body = "grant_type=refresh_token" +
    "&refresh_token=$([Uri]::EscapeDataString($refreshToken))" +
    "&client_id=$clientId" +
    "&client_secret=$([Uri]::EscapeDataString($clientSecret))"

try {
    $r = Invoke-RestMethod -Method POST `
        -Uri "https://www.linkedin.com/oauth/v2/accessToken" `
        -ContentType "application/x-www-form-urlencoded" `
        -Body $body -ErrorAction Stop

    $newToken      = $r.access_token
    $newRefresh    = $r.refresh_token
    $expiryDays    = [Math]::Round($r.expires_in / 86400)
    $newExpiry     = (Get-Date).AddSeconds($r.expires_in).ToString("yyyy-MM-dd")

    $envContent = Get-Content $envFile -Raw
    $envContent = $envContent -replace "LINKEDIN_ACCESS_TOKEN=.*",  "LINKEDIN_ACCESS_TOKEN=$newToken"
    $envContent = $envContent -replace "LINKEDIN_TOKEN_EXPIRY=.*",  "LINKEDIN_TOKEN_EXPIRY=$newExpiry"
    if ($newRefresh) {
        $envContent = $envContent -replace "LINKEDIN_REFRESH_TOKEN=.*", "LINKEDIN_REFRESH_TOKEN=$newRefresh"
    }
    Set-Content $envFile $envContent -NoNewline

    Write-Host "Token refreshed! New expiry: $newExpiry ($expiryDays days)"

} catch {
    Write-Error "Refresh failed: $($_.Exception.Message)"
    Write-Host "Run linkedin_auth.ps1 to re-authorize manually."
    exit 1
}
