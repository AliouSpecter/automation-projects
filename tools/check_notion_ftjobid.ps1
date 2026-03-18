# tools/check_notion_ftjobid.ps1
# Vérifie les doublons en fonction de la colonne ftJobId dans la base de données Notion
# Usage:
#   powershell.exe -ExecutionPolicy Bypass -File tools/check_notion_ftjobid.ps1

$ErrorActionPreference = "Stop"

# ── Load .env ─────────────────────────────────────────────────────────────────
$envPath = Join-Path $PSScriptRoot "..\.env"
if (Test-Path $envPath) {
    Get-Content $envPath | Where-Object { $_ -match "^[A-Z_]" } | ForEach-Object {
        $parts = $_ -split "=", 2
        if ($parts.Length -eq 2) {
            [System.Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1].Trim())
        }
    }
}

$notionKey = [System.Environment]::GetEnvironmentVariable("NOTION_API_KEY")
$databaseId = "31e8e6c9f9d4819ca913e50c6e43859c"

Write-Host "=== Vérification des doublons ftJobId dans Notion ===" -ForegroundColor Cyan
Write-Host "Database ID : $databaseId`n" -ForegroundColor Gray

# ── Query Notion Database ─────────────────────────────────────────────────────
$headers = @{
    "Authorization"  = "Bearer $notionKey"
    "Notion-Version" = "2022-06-28"
    "Content-Type"   = "application/json"
}

$body = @{
    page_size = 100
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Method POST `
        -Uri "https://api.notion.com/v1/databases/$databaseId/query" `
        -Headers $headers `
        -Body $body `
        -ErrorAction Stop

    Write-Host "Nombre total d'entrées : $($response.results.Count)" -ForegroundColor Green
    Write-Host ""

    # ── Analyse des données ftJobId ────────────────────────────────────────────
    $ftJobIds = @{}
    $duplicates = @()
    $allEntries = @()

    foreach ($page in $response.results) {
        $entry = @{
            id = $page.id
            ftJobId = ""
            email = ""
            name = ""
            company = ""
        }

        # Extraire ftJobId (propriété rich_text)
        if ($page.properties.ftJobId -and $page.properties.ftJobId.rich_text) {
            $entry.ftJobId = ($page.properties.ftJobId.rich_text | ForEach-Object { $_.plain_text }) -join ""
        }

        # Extraire l'email
        if ($page.properties.Email -and $page.properties.Email.email) {
            $entry.email = $page.properties.Email.email
        }

        # Extraire le nom
        if ($page.properties.Name -and $page.properties.Name.title) {
            $entry.name = ($page.properties.Name.title | ForEach-Object { $_.plain_text }) -join ""
        }

        # Extraire la compagnie
        if ($page.properties.Company -and $page.properties.Company.rich_text) {
            $entry.company = ($page.properties.Company.rich_text | ForEach-Object { $_.plain_text }) -join ""
        }

        $allEntries += $entry

        # Vérifier les doublons ftJobId
        if ($entry.ftJobId -and $entry.ftJobId -ne "") {
            if ($ftJobIds.ContainsKey($entry.ftJobId)) {
                $duplicates += $entry
            } else {
                $ftJobIds[$entry.ftJobId] = $entry
            }
        }
    }

    # ── Affichage des résultats ───────────────────────────────────────────────
    Write-Host "=== RÉSULTATS ftJobId ===" -ForegroundColor Yellow
    Write-Host ""

    # Doublons ftJobId
    if ($duplicates.Count -gt 0) {
        Write-Host "🔴 Doublons ftJobId trouvés : $($duplicates.Count)" -ForegroundColor Red
        foreach ($entry in $duplicates) {
            Write-Host "  - $($entry.ftJobId) | $($entry.email) | $($entry.name) | $($entry.company)" -ForegroundColor Red
            Write-Host "    ID: $($entry.id)" -ForegroundColor Gray
        }
        Write-Host ""
    } else {
        Write-Host "✅ Aucun doublon ftJobId trouvé" -ForegroundColor Green
        Write-Host ""
    }

    # Statistiques
    Write-Host "=== STATISTIQUES ftJobId ===" -ForegroundColor Cyan
    Write-Host "Total d'entrées : $($allEntries.Count)" -ForegroundColor White
    Write-Host "ftJobIds uniques : $($ftJobIds.Count)" -ForegroundColor White
    Write-Host "Doublons : $($duplicates.Count)" -ForegroundColor White

    # Sauvegarder le rapport
    $reportPath = Join-Path $PSScriptRoot "..\notion_ftjobid_report.json"
    $report = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        total_entries = $allEntries.Count
        unique_ftjobids = $ftJobIds.Count
        duplicates = $duplicates
    }
    $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "`nRapport sauvegardé : $reportPath" -ForegroundColor Gray

} catch {
    $errBody = $_.ErrorDetails.Message
    Write-Error "Échec Notion API : $($_.Exception.Message)`n$errBody"
    exit 1
}