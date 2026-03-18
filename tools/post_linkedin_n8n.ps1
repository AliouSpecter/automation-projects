<#
Publish to LinkedIn via n8n (server-side - routes around local firewall).
Sends text + imageBase64 + accessToken to n8n which calls LinkedIn API from the server.
Usage:
  .\tools\post_linkedin_n8n.ps1 -textFile "post.txt" -imagePath ".tmp/posts/image.png"
  .\tools\post_linkedin_n8n.ps1 -text "Mon post sans accents" -imagePath ".tmp/posts/image.png"
NOTE: For text with French accents, use -textFile to avoid subprocess encoding corruption.
#>

param(
    [string]$text      = "",
    [string]$textFile  = "",
    [string]$imagePath = ""
)

# Load text from file if provided (preserves UTF-8 accents)
if ($textFile) {
    if (-not (Test-Path $textFile)) { Write-Error "textFile not found: $textFile"; exit 1 }
    $text = [System.IO.File]::ReadAllText($textFile, [System.Text.Encoding]::UTF8)
}

if (-not $text)      { Write-Error "Parameter -text or -textFile is required"; exit 1 }
if (-not $imagePath) { Write-Error "Parameter -imagePath is required"; exit 1 }
if (-not (Test-Path $imagePath)) { Write-Error "Image not found: $imagePath"; exit 1 }

# Load .env
$envFile = Join-Path $PSScriptRoot "../.env"
Get-Content $envFile | Where-Object { $_ -match "^(LINKEDIN_|N8N_)" } | ForEach-Object {
    $p = $_ -split "=", 2
    [System.Environment]::SetEnvironmentVariable($p[0].Trim(), $p[1].Trim())
}

$n8nBase     = $env:N8N_BASE_URL
$accessToken = $env:LINKEDIN_ACCESS_TOKEN
$personId    = $env:LINKEDIN_PERSON_ID

if (-not $n8nBase)     { Write-Error "N8N_BASE_URL missing in .env"; exit 1 }
if (-not $accessToken) { Write-Error "LINKEDIN_ACCESS_TOKEN missing in .env"; exit 1 }

# Read image as base64
Write-Host "Reading image..."
$imageBytes  = [System.IO.File]::ReadAllBytes((Resolve-Path $imagePath))
$imageBase64 = [Convert]::ToBase64String($imageBytes)
Write-Host "Image: $([math]::Round($imageBytes.Length/1024))KB"

# Escape string to safe JSON — non-ASCII chars become \uXXXX (avoids all encoding issues in transit)
function ConvertTo-JsonString($s) {
    $sb = [System.Text.StringBuilder]::new()
    foreach ($c in $s.ToCharArray()) {
        $code = [int]$c
        if    ($c -eq '"')    { $null = $sb.Append('\"') }
        elseif ($c -eq '\')   { $null = $sb.Append('\\') }
        elseif ($c -eq "`n")  { $null = $sb.Append('\n') }
        elseif ($c -eq "`r")  { } # skip CR
        elseif ($code -gt 127){ $null = $sb.Append('\u{0:x4}' -f $code) }
        else                  { $null = $sb.Append($c) }
    }
    return $sb.ToString()
}

$textEscaped = ConvertTo-JsonString $text
$body = '{"text":"' + $textEscaped + '","imageBase64":"' + $imageBase64 + '","personId":"' + $personId + '","accessToken":"' + $accessToken + '"}'

$webhookUrl = "$n8nBase/webhook/linkedin-publish"
Write-Host "Publishing via n8n..."

try {
    $r = Invoke-RestMethod -Method POST -Uri $webhookUrl `
        -ContentType "application/json" -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) `
        -TimeoutSec 60 -ErrorAction Stop

    Write-Host "Posted successfully!"
    Write-Host "Result: $($r | ConvertTo-Json -Compress)"
    Write-Output "published"

} catch {
    Write-Error "Publish failed: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        try {
            $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
            Write-Error $reader.ReadToEnd()
        } catch {}
    }
    exit 1
}
