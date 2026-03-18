<#
Scrape Job Offer — Extract text content from a job posting URL
Usage: .\tools\scrape_job_offer.ps1 -url "https://..."

Supported: Welcome to the Jungle, Indeed, page carriere directe
Note: LinkedIn Jobs requires authentication — will return error, user must paste manually.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$url
)

$ErrorActionPreference = "Stop"

# ── Fetch page ─────────────────────────────────────────────────────────────────

Write-Host "Fetching: $url" -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Uri $url `
        -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" `
        -TimeoutSec 15 `
        -UseBasicParsing `
        -ErrorAction Stop

    $html = $response.Content
} catch {
    $statusCode = $_.Exception.Response.StatusCode.Value__
    if ($statusCode -eq 999 -or $url -match "linkedin\.com") {
        Write-Error "LinkedIn bloque le scraping non-authentifie. Colle le texte de l'offre directement dans le chat."
        exit 1
    }
    Write-Error "Impossible d'acceder a l'URL ($statusCode) : $($_.Exception.Message)"
    exit 1
}

# ── Strip HTML ─────────────────────────────────────────────────────────────────

# Remove <script>, <style>, <nav>, <footer>, <header> blocks entirely
$cleaned = $html -replace '(?is)<script[^>]*>.*?</script>', ''
$cleaned = $cleaned -replace '(?is)<style[^>]*>.*?</style>', ''
$cleaned = $cleaned -replace '(?is)<nav[^>]*>.*?</nav>', ''
$cleaned = $cleaned -replace '(?is)<footer[^>]*>.*?</footer>', ''
$cleaned = $cleaned -replace '(?is)<header[^>]*>.*?</header>', ''

# Convert block-level tags to newlines before stripping
$cleaned = $cleaned -replace '</?(p|div|li|h[1-6]|br|tr|section|article)[^>]*>', "`n"

# Strip remaining HTML tags
$cleaned = $cleaned -replace '<[^>]+>', ''

# Decode common HTML entities
$cleaned = $cleaned -replace '&amp;',  '&'
$cleaned = $cleaned -replace '&lt;',   '<'
$cleaned = $cleaned -replace '&gt;',   '>'
$cleaned = $cleaned -replace '&nbsp;', ' '
$cleaned = $cleaned -replace '&#39;',  "'"
$cleaned = $cleaned -replace '&quot;', '"'
$cleaned = $cleaned -replace '&#8217;', "'"
$cleaned = $cleaned -replace '&#8220;', '"'
$cleaned = $cleaned -replace '&#8221;', '"'

# Collapse whitespace — multiple blank lines to one
$cleaned = $cleaned -replace '[ \t]+', ' '
$cleaned = $cleaned -replace '(\r?\n){3,}', "`n`n"
$cleaned = $cleaned.Trim()

# ── Basic quality check ────────────────────────────────────────────────────────

if ($cleaned.Length -lt 200) {
    Write-Warning "Contenu extrait tres court ($($cleaned.Length) chars) — la page est peut-etre protegee ou dynamique."
    Write-Warning "Essaie de coller le texte de l'offre directement."
}

# ── Output ─────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
Write-Host " TEXTE EXTRAIT ($($cleaned.Length) caracteres)" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Output $cleaned
