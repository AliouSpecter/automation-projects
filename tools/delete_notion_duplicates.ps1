# tools/delete_notion_duplicates.ps1
# Supprime les doublons ftJobId dans la base de données Notion
# Usage:
#   powershell.exe -ExecutionPolicy Bypass -File tools/delete_notion_duplicates.ps1

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

Write-Host "=== Suppression des doublons ftJobId dans Notion ===" -ForegroundColor Cyan
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

    Write-Host "Nombre total d'entrees : $($response.results.Count)" -ForegroundColor Green
    Write-Host ""

    # ── Analyse des doublons ftJobId ──────────────────────────────────────────
    $ftJobIds = @{}
    $duplicatesToDelete = @()

    foreach ($page in $response.results) {
        $ftJobId = ""
        
        # Extraire ftJobId
        if ($page.properties.ftJobId -and $page.properties.ftJobId.rich_text) {
            $ftJobId = ($page.properties.ftJobId.rich_text | ForEach-Object { $_.plain_text }) -join ""
        }

        # Si ftJobId existe et n'est pas vide
        if ($ftJobId -and $ftJobId -ne "") {
            if ($ftJobIds.ContainsKey($ftJobId)) {
                # C'est un doublon, on le marque pour suppression
                $duplicatesToDelete += @{
                    id = $page.id
                    ftJobId = $ftJobId
                }
            } else {
                # Premier occurrence, on le garde
                $ftJobIds[$ftJobId] = $page.id
            }
        }
    }

    Write-Host "Doublons ftJobId trouves : $($duplicatesToDelete.Count)" -ForegroundColor Yellow
    Write-Host ""

    if ($duplicatesToDelete.Count -eq 0) {
        Write-Host "Aucun doublon a supprimer !" -ForegroundColor Green
        exit 0
    }

    # ── Suppression des doublons ──────────────────────────────────────────────
    Write-Host "Suppression en cours..." -ForegroundColor Yellow
    $deletedCount = 0
    $failedCount = 0

    foreach ($duplicate in $duplicatesToDelete) {
        try {
            $deleteResponse = Invoke-RestMethod -Method DELETE `
                -Uri "https://api.notion.com/v1/blocks/$($duplicate.id)" `
                -Headers $headers `
                -ErrorAction Stop

            $deletedCount++
            Write-Host "  Supprime : ftJobId=$($duplicate.ftJobId) | ID=$($duplicate.id)" -ForegroundColor Green
        }
        catch {
            $failedCount++
            Write-Host "  Echec : ftJobId=$($duplicate.ftJobId) | ID=$($duplicate.id)" -ForegroundColor Red
            Write-Host "    Erreur : $($_.Exception.Message)" -ForegroundColor Gray
        }
    }

    Write-Host ""
    Write-Host "=== RESULTATS ===" -ForegroundColor Cyan
    Write-Host "Doublons supprimes : $deletedCount" -ForegroundColor Green
    Write-Host "Echecs : $failedCount" -ForegroundColor Red

} catch {
    $errBody = $_.ErrorDetails.Message
    Write-Error "Echec Notion API : $($_.Exception.Message)`n$errBody"
    exit 1
}
