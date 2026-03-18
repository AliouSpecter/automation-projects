# tools/check_notion_duplicates.ps1
# Vérifie les doublons et e-mails de test dans la base de données Notion
# Usage:
#   powershell.exe -ExecutionPolicy Bypass -File tools/check_notion_duplicates.ps1

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

Write-Host "=== Vérification de la base de données Notion ===" -ForegroundColor Cyan
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

    # ── Analyse des données ───────────────────────────────────────────────────
    $emails = @{}
    $testEmails = @()
    $duplicates = @()
    $allEntries = @()

    foreach ($page in $response.results) {
        $entry = @{
            id = $page.id
            email = ""
            name = ""
            company = ""
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

        # Vérifier les e-mails de test
        if ($entry.email -match "test|example|demo|fake|temp") {
            $testEmails += $entry
        }

        # Vérifier les doublons
        if ($entry.email -and $entry.email -ne "") {
            if ($emails.ContainsKey($entry.email)) {
                $duplicates += $entry
            } else {
                $emails[$entry.email] = $entry
            }
        }
    }

    # ── Affichage des résultats ───────────────────────────────────────────────
    Write-Host "=== RÉSULTATS ===" -ForegroundColor Yellow
    Write-Host ""

    # E-mails de test
    if ($testEmails.Count -gt 0) {
        Write-Host "🔴 E-mails de test trouvés : $($testEmails.Count)" -ForegroundColor Red
        foreach ($entry in $testEmails) {
            Write-Host "  - $($entry.email) | $($entry.name) | $($entry.company)" -ForegroundColor Red
            Write-Host "    ID: $($entry.id)" -ForegroundColor Gray
        }
        Write-Host ""
    } else {
        Write-Host "✅ Aucun e-mail de test trouvé" -ForegroundColor Green
        Write-Host ""
    }

    # Doublons
    if ($duplicates.Count -gt 0) {
        Write-Host "🔴 Doublons trouvés : $($duplicates.Count)" -ForegroundColor Red
        foreach ($entry in $duplicates) {
            Write-Host "  - $($entry.email) | $($entry.name) | $($entry.company)" -ForegroundColor Red
            Write-Host "    ID: $($entry.id)" -ForegroundColor Gray
        }
        Write-Host ""
    } else {
        Write-Host "✅ Aucun doublon trouvé" -ForegroundColor Green
        Write-Host ""
    }

    # Statistiques
    Write-Host "=== STATISTIQUES ===" -ForegroundColor Cyan
    Write-Host "Total d'entrées : $($allEntries.Count)" -ForegroundColor White
    Write-Host "E-mails uniques : $($emails.Count)" -ForegroundColor White
    Write-Host "E-mails de test : $($testEmails.Count)" -ForegroundColor White
    Write-Host "Doublons : $($duplicates.Count)" -ForegroundColor White

    # Sauvegarder le rapport
    $reportPath = Join-Path $PSScriptRoot "..\notion_duplicates_report.json"
    $report = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        total_entries = $allEntries.Count
        unique_emails = $emails.Count
        test_emails = $testEmails
        duplicates = $duplicates
    }
    $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "`nRapport sauvegardé : $reportPath" -ForegroundColor Gray

} catch {
    $errBody = $_.ErrorDetails.Message
    Write-Error "Échec Notion API : $($_.Exception.Message)`n$errBody"
    exit 1
}
