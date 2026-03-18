<#
Google OAuth2 — Get access + refresh token for Google Docs & Drive API
Usage: .\tools\google_auth.ps1

Prerequisites:
1. Google Cloud Console -> Enable "Google Docs API" and "Google Drive API"
2. Create OAuth2 credentials (type: Desktop app)
3. Add to .env: GOOGLE_CLIENT_ID=... and GOOGLE_CLIENT_SECRET=...

Steps:
1. Opens browser to Google authorization page
2. Captures callback on localhost:8080
3. Exchanges code for access + refresh token
4. Saves GOOGLE_ACCESS_TOKEN, GOOGLE_REFRESH_TOKEN, GOOGLE_TOKEN_EXPIRY to .env
#>

$ErrorActionPreference = "Stop"

# ── Load .env ──────────────────────────────────────────────────────────────────

$envFile = Join-Path $PSScriptRoot "../.env"
Get-Content $envFile | Where-Object { $_ -match "^GOOGLE_" } | ForEach-Object {
    $p = $_ -split "=", 2
    [System.Environment]::SetEnvironmentVariable($p[0].Trim(), $p[1].Trim())
}

$clientId     = $env:GOOGLE_CLIENT_ID
$clientSecret = $env:GOOGLE_CLIENT_SECRET
$redirectUri  = "http://localhost:8080/callback"
$scope        = "https://www.googleapis.com/auth/documents https://www.googleapis.com/auth/drive"
$state        = [System.Guid]::NewGuid().ToString("N")

if (-not $clientId -or -not $clientSecret) {
    Write-Error "GOOGLE_CLIENT_ID ou GOOGLE_CLIENT_SECRET manquant dans .env"
    Write-Host ""
    Write-Host "Pour obtenir ces credentials :" -ForegroundColor Yellow
    Write-Host "  1. Aller sur console.cloud.google.com"
    Write-Host "  2. Activer Google Docs API + Google Drive API"
    Write-Host "  3. APIs & Services -> Identifiants -> Creer des identifiants -> ID client OAuth 2.0"
    Write-Host "  4. Type : Application de bureau"
    Write-Host "  5. Copier client_id et client_secret dans .env"
    exit 1
}

# ── Step 1: Start local HTTP listener ─────────────────────────────────────────

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:8080/")
$listener.Start()
Write-Host "Listener demarre sur http://localhost:8080/callback..."

# ── Step 2: Open browser ───────────────────────────────────────────────────────

$authUrl = "https://accounts.google.com/o/oauth2/v2/auth" +
    "?response_type=code" +
    "&client_id=$([Uri]::EscapeDataString($clientId))" +
    "&redirect_uri=$([Uri]::EscapeDataString($redirectUri))" +
    "&scope=$([Uri]::EscapeDataString($scope))" +
    "&state=$state" +
    "&access_type=offline" +
    "&prompt=consent"

Write-Host ""
Write-Host "Ouverture du navigateur pour autorisation Google..." -ForegroundColor Cyan
Start-Process $authUrl

# ── Step 3: Wait for callback ─────────────────────────────────────────────────

Write-Host "En attente de l'autorisation (approuve dans ton navigateur)..."
$context = $listener.GetContext()
$request = $context.Request

$code          = $request.QueryString["code"]
$returnedState = $request.QueryString["state"]
$oauthError    = $request.QueryString["error"]

# Respond to browser
$responseHtml = if ($oauthError) {
    "<html><body><h2>Autorisation echouee : $oauthError</h2><p>Tu peux fermer cet onglet.</p></body></html>"
} else {
    "<html><body><h2>Autorisation reussie !</h2><p>Tu peux fermer cet onglet et revenir dans Claude Code.</p></body></html>"
}
$buffer = [Text.Encoding]::UTF8.GetBytes($responseHtml)
$context.Response.ContentLength64 = $buffer.Length
$context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
$context.Response.OutputStream.Close()
$listener.Stop()

if ($oauthError) {
    Write-Error "Autorisation refusee : $oauthError"
    exit 1
}
if ($returnedState -ne $state) {
    Write-Error "State mismatch — possible CSRF. Abandon."
    exit 1
}

Write-Host "Code d'autorisation recu."

# ── Step 4: Exchange code for tokens ──────────────────────────────────────────

Write-Host "Echange du code contre les tokens..."

$tokenBody = "code=$([Uri]::EscapeDataString($code))" +
    "&client_id=$([Uri]::EscapeDataString($clientId))" +
    "&client_secret=$([Uri]::EscapeDataString($clientSecret))" +
    "&redirect_uri=$([Uri]::EscapeDataString($redirectUri))" +
    "&grant_type=authorization_code"

try {
    $tokenResponse = Invoke-RestMethod -Method POST `
        -Uri "https://oauth2.googleapis.com/token" `
        -ContentType "application/x-www-form-urlencoded" `
        -Body $tokenBody -ErrorAction Stop

    $accessToken  = $tokenResponse.access_token
    $refreshToken = $tokenResponse.refresh_token
    $expiresIn    = $tokenResponse.expires_in   # typically 3600 (1 hour)
    $expiryTime   = (Get-Date).AddSeconds($expiresIn).ToString("yyyy-MM-ddTHH:mm:ss")

    Write-Host ""
    Write-Host "Tokens obtenus ! Access token expire dans $([Math]::Round($expiresIn/60)) minutes." -ForegroundColor Green

} catch {
    $errBody = $_.ErrorDetails.Message
    Write-Error "Echange de token echoue : $($_.Exception.Message)`n$errBody"
    exit 1
}

# ── Save to .env ───────────────────────────────────────────────────────────────

$envContent = Get-Content $envFile -Raw

# Replace or append each variable
function Set-EnvVar($content, $key, $value) {
    if ($content -match "^$key=") {
        return $content -replace "(?m)^$key=.*", "$key=$value"
    } else {
        return $content.TrimEnd() + "`n$key=$value"
    }
}

$envContent = Set-EnvVar $envContent "GOOGLE_ACCESS_TOKEN"  $accessToken
$envContent = Set-EnvVar $envContent "GOOGLE_REFRESH_TOKEN" $refreshToken
$envContent = Set-EnvVar $envContent "GOOGLE_TOKEN_EXPIRY"  $expiryTime

Set-Content $envFile $envContent -Encoding UTF8 -NoNewline

Write-Host "GOOGLE_ACCESS_TOKEN  -> .env" -ForegroundColor Green
Write-Host "GOOGLE_REFRESH_TOKEN -> .env" -ForegroundColor Green
Write-Host "GOOGLE_TOKEN_EXPIRY  -> .env ($expiryTime)" -ForegroundColor Green
Write-Host ""
Write-Host "Done. Tu peux maintenant utiliser tools/create_cv_doc.ps1"
