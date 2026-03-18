# tools/check_notion_valid_emails.ps1
# Vérifie les entrées avec des vrais e-mails dans la base de données Notion
# Usage:
#   powershell.exe -ExecutionPolicy Bypass -File tools/check_notion_valid_emails.ps1

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

Write-Host "=== Vérification des e-mails valides dans Notion ===" -ForegroundColor Cyan
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
    $validEmails = @()
    $invalidEmails = @()
    $noEmails = @()
    $testEmails = @()

    foreach ($page in $response.results) {
        $entry = @{
            id = $page.id
            email = ""
            name = ""
            company = ""
            ftJobId = ""
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

        # Extraire ftJobId
        if ($page.properties.ftJobId -and $page.properties.ftJobId.rich_text) {
            $entry.ftJobId = ($page.properties.ftJobId.rich_text | ForEach-Object { $_.plain_text }) -join ""
        }

        # Catégoriser les e-mails
        if ($entry.email -eq "") {
            $noEmails += $entry
        }
        elseif ($entry.email -match "test|example|demo|fake|temp|noreply|no-reply") {
            $testEmails += $entry
        }
        elseif ($entry.email -match "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$") {
            $validEmails += $entry
        }
        else {
            $invalidEmails += $entry
        }
    }

    # ── Affichage des résultats ───────────────────────────────────────────────
    Write-Host "=== RÉSULTATS ===" -ForegroundColor Yellow
    Write-Host ""

    # E-mails valides
    Write-Host "E-mails valides : $($validEmails.Count)" -ForegroundColor Green
    if ($validEmails.Count -gt 0) {
        Write-Host "Exemples :" -ForegroundColor Gray
        $validEmails | Select-Object -First 5 | ForEach-Object {
            $emailStr = $_.email
            $nameStr = $_.name
            $companyStr = $_.company
            Write-Host "  - $emailStr - $nameStr - $companyStr" -ForegroundColor Green
        }
        Write-Host ""
    }

    # E-mails de test
    Write-Host "E-mails de test : $($testEmails.Count)" -ForegroundColor Red
    if ($testEmails.Count -gt 0) {
        foreach ($entry in $testEmails) {
            $emailStr = $entry.email
            $nameStr = $entry.name
            $companyStr = $entry.company
            Write-Host "  - $emailStr - $nameStr - $companyStr" -ForegroundColor Red
        }
        Write-Host ""
    }

    # Pas d'e-mail
    Write-Host "Pas d'e-mail : $($noEmails.Count)" -ForegroundColor Yellow
    if ($noEmails.Count -gt 0) {
        Write-Host "Exemples :" -ForegroundColor Gray
        $noEmails | Select-Object -First 5 | ForEach-Object {
            $nameStr = $_.name
            $companyStr = $_.company
            $ftJobIdStr = $_.ftJobId
            Write-Host "  - $nameStr - $companyStr - ftJobId: $ftJobIdStr" -ForegroundColor Yellow
        }
        Write-Host ""
    }

    # E-mails invalides
    if ($invalidEmails.Count -gt 0) {
        Write-Host "E-mails invalides : $($invalidEmails.Count)" -ForegroundColor Magenta
        foreach ($entry in $invalidEmails) {
            $emailStr = $entry.email
            $nameStr = $entry.name
            $companyStr = $entry.company
            Write-Host "  - $emailStr - $nameStr - $companyStr" -ForegroundColor Magenta
        }
        Write-Host ""
    }

    # Statistiques
    Write-Host "=== STATISTIQUES ===" -ForegroundColor Cyan
    Write-Host "Total d'entrées : $($response.results.Count)" -ForegroundColor White
    Write-Host "E-mails valides : $($validEmails.Count)" -ForegroundColor Green
    Write-Host "E-mails de test : $($testEmails.Count)" -ForegroundColor Red
    Write-Host "Pas d'e-mail : $($noEmails.Count)" -ForegroundColor Yellow
    Write-Host "E-mails invalides : $($invalidEmails.Count)" -ForegroundColor Magenta

    # Sauvegarder le rapport
    $reportPath = Join-Path $PSScriptRoot "..\notion_valid_emails_report.json"
    $report = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        total_entries = $response.results.Count
        valid_emails = $validEmails
        test_emails = $testEmails
        no_emails = $noEmails
        invalid_emails = $invalidEmails
        stats = @{
            valid_count = $validEmails.Count
            test_count = $testEmails.Count
            no_email_count = $noEmails.Count
            invalid_count = $invalidEmails.Count
        }
    }
    $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "`nRapport sauvegardé : $reportPath" -ForegroundColor Gray

} catch {
    $errBody = $_.ErrorDetails.Message
    Write-Error "Échec Notion API : $($_.Exception.Message)`n$errBody"
    exit 1
}
