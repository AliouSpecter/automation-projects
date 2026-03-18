<#
.SYNOPSIS
  Enrichissement email batch des prospects Notion via Hunter.io
  Lit les entres Notion sans email, appelle Hunter.io, met  jour Notion.

.USAGE
  .\tools\enrich_emails_hunter.ps1                    # enrichit jusqu' 20 prospects
  .\tools\enrich_emails_hunter.ps1 -Limit 50          # enrichit jusqu' 50 prospects
  .\tools\enrich_emails_hunter.ps1 -DryRun            # simule sans crire dans Notion
  .\tools\enrich_emails_hunter.ps1 -Limit 5 -DryRun   # test sur 5 entres

.NOTES
  Plan Hunter.io Free = 50 searches/mois. Surveiller le quota.
#>

param(
    [int]$Limit = 20,
    [switch]$DryRun
)

#  Charger .env 
$envFile = Join-Path $PSScriptRoot "..\.env"
if (Test-Path $envFile) {
    Get-Content $envFile | Where-Object { $_ -match "^[A-Z_]+=.+" } | ForEach-Object {
        $parts = $_ -split "=", 2
        [System.Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1].Trim())
    }
}

$HUNTER_KEY  = $env:HUNTER_API_KEY
$NOTION_KEY  = $env:NOTION_API_KEY
$NOTION_DB   = $env:NOTION_PROSPECTS_DB_ID

if (-not $HUNTER_KEY -or -not $NOTION_KEY -or -not $NOTION_DB) {
    Write-Host " Variables manquantes dans .env (HUNTER_API_KEY, NOTION_API_KEY, NOTION_PROSPECTS_DB_ID)" -ForegroundColor Red
    exit 1
}

$notionHeaders = @{
    "Authorization"  = "Bearer $NOTION_KEY"
    "Notion-Version" = "2022-06-28"
    "Content-Type"   = "application/json"
}

#  Compteurs 
$stats = @{ total = 0; found = 0; domain_only = 0; not_found = 0; errors = 0 }

#  1. Rcuprer les prospects sans email 
Write-Host ""
Write-Host " Rcupration des prospects sans email (max $Limit)..." -ForegroundColor Cyan

$filterBody = @{
    page_size = [Math]::Min($Limit, 100)
    filter    = @{
        and = @(
            @{ property = "Email";                 email  = @{ is_empty     = $true } },
            @{ property = "Domaine";               url    = @{ is_not_empty = $true } },
            @{ property = "Enrichissement email";  select = @{ equals       = "Enrichir" } }
        )
    }
} | ConvertTo-Json -Depth 10 -Compress

try {
    $notionResp = Invoke-RestMethod `
        -Method POST `
        -Uri "https://api.notion.com/v1/databases/$NOTION_DB/query" `
        -Headers $notionHeaders `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($filterBody))
} catch {
    Write-Host " Erreur Notion query: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$prospects = $notionResp.results
if (-not $prospects -or $prospects.Count -eq 0) {
    Write-Host " Aucun prospect sans email trouv. Tout est dj enrichi !" -ForegroundColor Green
    exit 0
}

Write-Host " $($prospects.Count) prospect(s)  enrichir" -ForegroundColor Yellow
if ($DryRun) { Write-Host "  MODE DRY-RUN  aucune criture dans Notion" -ForegroundColor Magenta }
Write-Host ""

#  2. Boucle d'enrichissement 
foreach ($page in $prospects) {
    $pageId      = $page.id
    $companyName = $page.properties.Entreprise.title[0].plain_text
    $domainUrl   = $page.properties.Domaine.url
    $domain      = $domainUrl -replace "^https?://", "" -replace "/$", ""
    $stats.total++

    Write-Host "[$($stats.total)/$($prospects.Count)] $companyName ($domain)" -NoNewline

    #  Appel Hunter.io par domaine
    $sep = [char]38  # caractre & (ampersand)
    $hunterUrl = "https://api.hunter.io/v2/domain-search?domain=$domain" +
                 "${sep}api_key=$HUNTER_KEY" +
                 "${sep}limit=5" +
                 "${sep}seniority=senior,executive" +
                 "${sep}department=management,executive,sales"

    try {
        $hunterResp = Invoke-RestMethod -Uri $hunterUrl -Method GET -ErrorAction Stop
    } catch {
        Write-Host "  Hunter error: $($_.Exception.Message)" -ForegroundColor Red
        $stats.errors++
        continue
    }

    $emails = $hunterResp.data.emails

    #  Slectionner le meilleur email 
    $bestEmail = $null
    if ($emails -and $emails.Count -gt 0) {
        $deptPriority = @{ management = 0; executive = 1; sales = 2 }
        $sorted = $emails | Sort-Object {
            $dp = if ($deptPriority.ContainsKey($_.department)) { $deptPriority[$_.department] } else { 99 }
            $dp * 1000 - ($_.confidence -as [int])
        }
        $bestEmail = $sorted[0]
    }

    #  Construire le patch Notion 
    if ($bestEmail) {
        $emailVal   = $bestEmail.value
        $confidence = $bestEmail.confidence

        Write-Host "  $emailVal (confiance: $confidence%)" -ForegroundColor Green
        $stats.found++

        $notionPatch = @{
            properties = @{
                "Email"                = @{ email  = $emailVal }
                "Enrichissement email" = @{ select = @{ name = "Enrichi" } }
            }
        }
    } else {
        Write-Host "  aucun email trouve" -ForegroundColor DarkGray
        $stats.not_found++

        $notionPatch = @{
            properties = @{
                "Enrichissement email" = @{ select = @{ name = "Email non trouve" } }
            }
        }
    }

    #  crire dans Notion (sauf DryRun) 
    if (-not $DryRun) {
        $patchBody = $notionPatch | ConvertTo-Json -Depth 10 -Compress
        try {
            Invoke-RestMethod `
                -Method PATCH `
                -Uri "https://api.notion.com/v1/pages/$pageId" `
                -Headers $notionHeaders `
                -Body ([System.Text.Encoding]::UTF8.GetBytes($patchBody)) | Out-Null
        } catch {
            Write-Host "     Erreur Notion PATCH: $($_.Exception.Message)" -ForegroundColor Red
            $stats.errors++
        }
    }

    # Petite pause pour ne pas spammer Hunter (plan Free)
    Start-Sleep -Milliseconds 300
}

#  3. Rsum 
Write-Host ""
Write-Host "" -ForegroundColor Cyan
Write-Host "  RSUM ENRICHISSEMENT EMAIL" -ForegroundColor Cyan
Write-Host "" -ForegroundColor Cyan
Write-Host "  Total traits   : $($stats.total)"
Write-Host "   Email trouv  : $($stats.found)" -ForegroundColor Green
Write-Host "   Domaine only  : $($stats.domain_only)" -ForegroundColor Yellow
Write-Host "   Non trouv    : $($stats.not_found)" -ForegroundColor DarkGray
Write-Host "   Erreurs       : $($stats.errors)" -ForegroundColor Red
if ($DryRun) { Write-Host "    DRY-RUN  rien crit dans Notion" -ForegroundColor Magenta }
Write-Host "" -ForegroundColor Cyan
Write-Host ""

# Vrifier le quota Hunter restant
try {
    $account = Invoke-RestMethod -Uri "https://api.hunter.io/v2/account?api_key=$HUNTER_KEY" -Method GET
    $used      = $account.data.requests.searches.used
    $available = $account.data.requests.searches.available
    Write-Host " Quota Hunter.io : $used/$available searches utilises ce mois" -ForegroundColor Cyan
} catch {}
Write-Host ""
