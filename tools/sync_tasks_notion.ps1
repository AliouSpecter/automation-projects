# tools/sync_tasks_notion.ps1
# Archive les tâches réalisées ([x]) de TASKS.md vers une page Notion
# Crée une page dans la DB parent avec toutes les réalisations groupées par date
#
# Usage:
#   powershell.exe -ExecutionPolicy Bypass -File tools/sync_tasks_notion.ps1

$ErrorActionPreference = "Stop"

# ── Load .env ─────────────────────────────────────────────────────────────────
$envPath = Join-Path $PSScriptRoot "..\.env"
Get-Content $envPath | Where-Object { $_ -match "^[A-Z_]" } | ForEach-Object {
    $parts = $_ -split "=", 2
    if ($parts.Length -eq 2) {
        [System.Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1].Trim())
    }
}

$notionKey = [System.Environment]::GetEnvironmentVariable("NOTION_API_KEY")
$parentId  = [System.Environment]::GetEnvironmentVariable("NOTION_PARENT_PAGE_ID")

# ── Read TASKS.md ─────────────────────────────────────────────────────────────
$tasksFile = Join-Path $PSScriptRoot "..\TASKS.md"
$lines = [System.IO.File]::ReadAllLines($tasksFile, [System.Text.Encoding]::UTF8)

# Extraire la section "## Réalisations"
$inRealisations = $false
$realisationLines = @()
foreach ($line in $lines) {
    if ($line -match "^## R\u00e9alisations") {
        $inRealisations = $true
        continue
    }
    if ($inRealisations -and $line -match "^## ") { break }
    if ($inRealisations) { $realisationLines += $line }
}

if ($realisationLines.Count -eq 0) {
    Write-Host "Aucune réalisation trouvée dans TASKS.md" -ForegroundColor Yellow
    exit 0
}

# ── Helpers ───────────────────────────────────────────────────────────────────
function EscapeJson($str) {
    return $str -replace '\\', '\\\\' -replace '"', '\"' -replace "`t", '\t' `
                -replace "`n", '\n' -replace "`r", ''
}

function EncodeNonAscii($str) {
    $sb = New-Object System.Text.StringBuilder
    foreach ($c in $str.ToCharArray()) {
        if ([int]$c -gt 127) {
            $sb.Append('\u{0:x4}' -f [int]$c) | Out-Null
        } else {
            $sb.Append($c) | Out-Null
        }
    }
    return $sb.ToString()
}

# ── Build Notion blocks ────────────────────────────────────────────────────────
$blocks = @()

foreach ($line in $realisationLines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }

    # ### Date → heading_3
    if ($line -match "^### (.+)") {
        $text = EncodeNonAscii (EscapeJson $Matches[1])
        $blocks += '{"type":"heading_3","heading_3":{"rich_text":[{"type":"text","text":{"content":"' + $text + '"}}]}}'
        continue
    }

    # - [x] tâche terminée (tous niveaux d'indentation)
    if ($line -match "^\s*- \[x\] (.+)") {
        $text = EncodeNonAscii (EscapeJson $Matches[1])
        $blocks += '{"type":"bulleted_list_item","bulleted_list_item":{"rich_text":[{"type":"text","text":{"content":"' + $text + '"}}]}}'
    }
}

if ($blocks.Count -eq 0) {
    Write-Host "Aucun bloc [x] à archiver" -ForegroundColor Yellow
    exit 0
}

Write-Host "Blocs à archiver : $($blocks.Count)" -ForegroundColor Cyan

# Notion limite à 100 blocs par requête
$maxBlocks = [Math]::Min($blocks.Count, 100)
$blocksJson = "[" + ($blocks[0..($maxBlocks - 1)] -join ",") + "]"

# ── Build payload ──────────────────────────────────────────────────────────────
$today = Get-Date -Format "yyyy-MM-dd"
$title = "R\u00e9alisations archiv\u00e9es - $today"

$payload = '{"parent":{"database_id":"' + $parentId + '"},' +
           '"icon":{"emoji":"\u2705"},' +
           '"properties":{' +
             '"Nom de la t\u00e2che":{"title":[{"type":"text","text":{"content":"' + $title + '"}}]}' +
           '},' +
           '"children":' + $blocksJson + '}'

# ── Write payload UTF-8 NoBOM ──────────────────────────────────────────────────
$tmpFile = Join-Path $PSScriptRoot "..\.tmp\sync_tasks_payload.json"
[System.IO.File]::WriteAllText($tmpFile, $payload, (New-Object System.Text.UTF8Encoding $false))

# ── POST to Notion API ─────────────────────────────────────────────────────────
$headers = @{
    "Authorization"  = "Bearer $notionKey"
    "Notion-Version" = "2022-06-28"
    "Content-Type"   = "application/json; charset=utf-8"
}

$bytes = [System.IO.File]::ReadAllBytes($tmpFile)

try {
    $response = Invoke-RestMethod -Method POST `
        -Uri "https://api.notion.com/v1/pages" `
        -Headers $headers `
        -Body $bytes `
        -ErrorAction Stop

    $cleanId = $response.id -replace "-", ""
    $pageUrl  = "https://www.notion.so/$cleanId"

    Write-Host "`nPage créée !" -ForegroundColor Green
    Write-Host "  Blocs archivés : $($blocks.Count)" -ForegroundColor Gray
    Write-Host "  URL : $pageUrl" -ForegroundColor Cyan
    Write-Host "`nTu peux maintenant vider la section Réalisations de TASKS.md" -ForegroundColor Yellow

} catch {
    $errBody = $_.ErrorDetails.Message
    Write-Error "Échec Notion API : $($_.Exception.Message)`n$errBody"
    exit 1
}
