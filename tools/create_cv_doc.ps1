<#
Create CV Google Doc — Upload HTML to Google Drive with MIME conversion
Usage: .\tools\create_cv_doc.ps1 -htmlFile ".tmp/cv_content.html" -docName "CV - Traffic Manager - Entreprise - 2026-03-05"

Returns: Google Doc URL

Note: If GOOGLE_ACCESS_TOKEN is expired (1h lifetime), refreshes automatically using GOOGLE_REFRESH_TOKEN.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$htmlFile,

    [Parameter(Mandatory=$true)]
    [string]$docName
)

$ErrorActionPreference = "Stop"

# ── Load .env ──────────────────────────────────────────────────────────────────

$envFile = Join-Path $PSScriptRoot "../.env"
Get-Content $envFile | Where-Object { $_ -match "^GOOGLE_" } | ForEach-Object {
    $p = $_ -split "=", 2
    [System.Environment]::SetEnvironmentVariable($p[0].Trim(), $p[1].Trim())
}

$accessToken  = $env:GOOGLE_ACCESS_TOKEN
$refreshToken = $env:GOOGLE_REFRESH_TOKEN
$tokenExpiry  = $env:GOOGLE_TOKEN_EXPIRY
$clientId     = $env:GOOGLE_CLIENT_ID
$clientSecret = $env:GOOGLE_CLIENT_SECRET

if (-not $accessToken) {
    Write-Error "GOOGLE_ACCESS_TOKEN manquant. Lance d'abord : powershell.exe -ExecutionPolicy Bypass -File tools/google_auth.ps1"
    exit 1
}

# ── Refresh token if expired ───────────────────────────────────────────────────

if ($tokenExpiry) {
    $expiry = [DateTime]::Parse($tokenExpiry)
    $minutesLeft = ($expiry - (Get-Date)).TotalMinutes
    if ($minutesLeft -lt 5) {
        Write-Host "Token expire (reste $([Math]::Round($minutesLeft)) min) — renouvellement..." -ForegroundColor Yellow

        if (-not $refreshToken) {
            Write-Error "GOOGLE_REFRESH_TOKEN manquant. Relance tools/google_auth.ps1 pour re-autoriser."
            exit 1
        }

        $refreshBody = "grant_type=refresh_token" +
            "&refresh_token=$([Uri]::EscapeDataString($refreshToken))" +
            "&client_id=$([Uri]::EscapeDataString($clientId))" +
            "&client_secret=$([Uri]::EscapeDataString($clientSecret))"

        try {
            $refreshResponse = Invoke-RestMethod -Method POST `
                -Uri "https://oauth2.googleapis.com/token" `
                -ContentType "application/x-www-form-urlencoded" `
                -Body $refreshBody -ErrorAction Stop

            $accessToken = $refreshResponse.access_token
            $newExpiry   = (Get-Date).AddSeconds($refreshResponse.expires_in).ToString("yyyy-MM-ddTHH:mm:ss")

            # Update .env
            $envContent = Get-Content $envFile -Raw
            $envContent = $envContent -replace "(?m)^GOOGLE_ACCESS_TOKEN=.*",  "GOOGLE_ACCESS_TOKEN=$accessToken"
            $envContent = $envContent -replace "(?m)^GOOGLE_TOKEN_EXPIRY=.*",  "GOOGLE_TOKEN_EXPIRY=$newExpiry"
            Set-Content $envFile $envContent -Encoding UTF8 -NoNewline

            Write-Host "Token renouvelé. Expire à $newExpiry." -ForegroundColor Green

        } catch {
            Write-Error "Refresh échoué : $($_.Exception.Message). Relance tools/google_auth.ps1"
            exit 1
        }
    }
}

# ── Read HTML file ─────────────────────────────────────────────────────────────

$resolvedHtml = $htmlFile
if (-not [System.IO.Path]::IsPathRooted($htmlFile)) {
    $resolvedHtml = Join-Path (Split-Path $PSScriptRoot -Parent) $htmlFile
}

if (-not (Test-Path $resolvedHtml)) {
    Write-Error "Fichier HTML introuvable : $resolvedHtml"
    exit 1
}

$htmlContent = Get-Content $resolvedHtml -Raw -Encoding UTF8
Write-Host "HTML lu : $resolvedHtml ($($htmlContent.Length) chars)" -ForegroundColor Cyan

# ── Build multipart body ───────────────────────────────────────────────────────

$boundary = "cv_upload_" + [System.Guid]::NewGuid().ToString("N")

$metadataJson = '{"name":"' + $docName + '","mimeType":"application/vnd.google-apps.document"}'

$bodyText  = "--$boundary`r`n"
$bodyText += "Content-Type: application/json; charset=UTF-8`r`n`r`n"
$bodyText += $metadataJson + "`r`n"
$bodyText += "--$boundary`r`n"
$bodyText += "Content-Type: text/html; charset=UTF-8`r`n`r`n"
$bodyText += $htmlContent + "`r`n"
$bodyText += "--$boundary--"

$bodyBytes = [Text.Encoding]::UTF8.GetBytes($bodyText)

# ── Upload to Google Drive ─────────────────────────────────────────────────────

Write-Host "Upload vers Google Drive..." -ForegroundColor Cyan

$uploadUrl = "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart"

try {
    $webRequest = [System.Net.HttpWebRequest]::Create($uploadUrl)
    $webRequest.Method      = "POST"
    $webRequest.ContentType = "multipart/related; boundary=$boundary"
    $webRequest.ContentLength = $bodyBytes.Length
    $webRequest.Headers.Add("Authorization", "Bearer $accessToken")

    $requestStream = $webRequest.GetRequestStream()
    $requestStream.Write($bodyBytes, 0, $bodyBytes.Length)
    $requestStream.Close()

    $webResponse   = $webRequest.GetResponse()
    $responseStream = $webResponse.GetResponseStream()
    $reader        = [System.IO.StreamReader]::new($responseStream, [Text.Encoding]::UTF8)
    $responseBody  = $reader.ReadToEnd()
    $reader.Close()
    $webResponse.Close()

    $responseObj = $responseBody | ConvertFrom-Json
    $fileId      = $responseObj.id

} catch {
    $errStream = $_.Exception.Response.GetResponseStream()
    $errReader = [System.IO.StreamReader]::new($errStream)
    $errBody   = $errReader.ReadToEnd()
    Write-Error "Upload echoue : $($_.Exception.Message)`n$errBody"
    exit 1
}

# ── Return URL ─────────────────────────────────────────────────────────────────

$docUrl = "https://docs.google.com/document/d/$fileId/edit"

Write-Host ""
Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
Write-Host " Google Doc cree avec succes !" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
Write-Host " Nom   : $docName"
Write-Host " ID    : $fileId"
Write-Host " URL   : $docUrl" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Output $docUrl
