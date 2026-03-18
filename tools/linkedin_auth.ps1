<#
LinkedIn OAuth2 - Get access token via local callback server
Usage: .\tools\linkedin_auth.ps1

Steps:
1. Opens browser to LinkedIn authorization page
2. Captures the callback automatically on localhost:8080
3. Exchanges code for access token
4. Saves LINKEDIN_ACCESS_TOKEN to .env
#>

# Load .env
$envFile = Join-Path $PSScriptRoot "../.env"
Get-Content $envFile | Where-Object { $_ -match "^LINKEDIN_" } | ForEach-Object {
    $p = $_ -split "=", 2
    [System.Environment]::SetEnvironmentVariable($p[0].Trim(), $p[1].Trim())
}

$clientId     = $env:LINKEDIN_CLIENT_ID
$clientSecret = $env:LINKEDIN_CLIENT_SECRET
$redirectUri  = "http://localhost:8080/callback"
$scope        = "w_member_social openid profile"
$state        = [System.Guid]::NewGuid().ToString("N")

if (-not $clientId -or -not $clientSecret) {
    Write-Error "LINKEDIN_CLIENT_ID or LINKEDIN_CLIENT_SECRET missing in .env"
    exit 1
}

# ── Step 1: Start local HTTP listener ─────────────────────────────────────────

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:8080/")
$listener.Start()
Write-Host "Listening on http://localhost:8080/callback..."

# ── Step 2: Open browser ───────────────────────────────────────────────────────

$authUrl = "https://www.linkedin.com/oauth/v2/authorization" +
    "?response_type=code" +
    "&client_id=$clientId" +
    "&redirect_uri=$([Uri]::EscapeDataString($redirectUri))" +
    "&scope=$([Uri]::EscapeDataString($scope))" +
    "&state=$state"

Write-Host ""
Write-Host "Opening browser for LinkedIn authorization..."
Write-Host "URL: $authUrl"
Write-Host ""
Start-Process $authUrl

# ── Step 3: Wait for callback ─────────────────────────────────────────────────

Write-Host "Waiting for authorization (approve in your browser)..."
$context = $listener.GetContext()
$request = $context.Request

$code          = $request.QueryString["code"]
$returnedState = $request.QueryString["state"]
$oauthError    = $request.QueryString["error"]

# Send response to browser
$responseHtml = if ($oauthError) {
    "<html><body><h2>Authorization failed: $oauthError</h2><p>You can close this tab.</p></body></html>"
} else {
    "<html><body><h2>Authorization successful!</h2><p>You can close this tab and return to Claude Code.</p></body></html>"
}
$buffer = [Text.Encoding]::UTF8.GetBytes($responseHtml)
$context.Response.ContentLength64 = $buffer.Length
$context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
$context.Response.OutputStream.Close()
$listener.Stop()

if ($oauthError) {
    Write-Error "Authorization denied: $oauthError"
    exit 1
}

if ($returnedState -ne $state) {
    Write-Error "State mismatch - possible CSRF. Aborting."
    exit 1
}

Write-Host "Authorization code received."

# ── Step 4: Exchange code for token ───────────────────────────────────────────

Write-Host "Exchanging code for access token..."

$tokenBody = "grant_type=authorization_code" +
    "&code=$([Uri]::EscapeDataString($code))" +
    "&redirect_uri=$([Uri]::EscapeDataString($redirectUri))" +
    "&client_id=$clientId" +
    "&client_secret=$([Uri]::EscapeDataString($clientSecret))"

try {
    $tokenResponse = Invoke-RestMethod -Method POST `
        -Uri "https://www.linkedin.com/oauth/v2/accessToken" `
        -ContentType "application/x-www-form-urlencoded" `
        -Body $tokenBody -ErrorAction Stop

    $accessToken   = $tokenResponse.access_token
    $refreshToken  = $tokenResponse.refresh_token
    $expiresIn     = $tokenResponse.expires_in
    $expiryDays    = [Math]::Round($expiresIn / 86400)
    $expiryDate    = (Get-Date).AddSeconds($expiresIn).ToString("yyyy-MM-dd")

    Write-Host ""
    Write-Host "Access token obtained! Expires in $expiryDays days ($expiryDate)."

} catch {
    Write-Error "Token exchange failed: $($_.Exception.Message)"
    exit 1
}

# Save to .env
$envContent = Get-Content $envFile -Raw
$envContent = $envContent -replace "LINKEDIN_ACCESS_TOKEN=.*", "LINKEDIN_ACCESS_TOKEN=$accessToken"

if ($refreshToken) {
    if ($envContent -match "LINKEDIN_REFRESH_TOKEN=") {
        $envContent = $envContent -replace "LINKEDIN_REFRESH_TOKEN=.*", "LINKEDIN_REFRESH_TOKEN=$refreshToken"
    } else {
        $envContent = $envContent -replace "LINKEDIN_ACCESS_TOKEN=.*", "LINKEDIN_ACCESS_TOKEN=$accessToken`nLINKEDIN_REFRESH_TOKEN=$refreshToken"
    }
    if ($envContent -match "LINKEDIN_TOKEN_EXPIRY=") {
        $envContent = $envContent -replace "LINKEDIN_TOKEN_EXPIRY=.*", "LINKEDIN_TOKEN_EXPIRY=$expiryDate"
    } else {
        $envContent = $envContent -replace "LINKEDIN_REFRESH_TOKEN=.*", "LINKEDIN_REFRESH_TOKEN=$refreshToken`nLINKEDIN_TOKEN_EXPIRY=$expiryDate"
    }
}

Set-Content $envFile $envContent -NoNewline

Write-Host "LINKEDIN_ACCESS_TOKEN saved to .env"
if ($refreshToken) { Write-Host "LINKEDIN_REFRESH_TOKEN saved to .env" }
Write-Host "Token expires: $expiryDate"
Write-Host ""
Write-Host "Done. You can now use tools/post_linkedin.ps1"
