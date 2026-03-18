# tools/post_notion_planning.ps1
# Cree une page Planning dans la DB Notion "Automation Act"
# Contenu dans .tmp/notion_planning_blocks.json (UTF-8)
#
# Usage:
#   powershell.exe -ExecutionPolicy Bypass -File tools/post_notion_planning.ps1

$ErrorActionPreference = "Stop"

# Load .env
$envPath = Join-Path $PSScriptRoot "..\\.env"
Get-Content $envPath | Where-Object { $_ -match "^[A-Z_]" } | ForEach-Object {
    $parts = $_ -split "=", 2
    if ($parts.Length -eq 2) {
        [System.Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1].Trim())
    }
}

$notionKey = [System.Environment]::GetEnvironmentVariable("NOTION_API_KEY")
$parentId  = [System.Environment]::GetEnvironmentVariable("NOTION_PARENT_PAGE_ID")

Write-Host "Parent ID : $parentId" -ForegroundColor Cyan

# Read blocks JSON (UTF-8)
$blocksFile = Join-Path $PSScriptRoot "..\\.tmp\\notion_planning_blocks.json"
$blocksJson = [System.IO.File]::ReadAllText($blocksFile, [System.Text.Encoding]::UTF8).Trim()

# Build payload
$title = "Planning - Automation Act - Semaine du 2026-03-09"

$payload = '{"parent":{"database_id":"' + $parentId + '"},' +
           '"icon":{"emoji":"\ud83d\udcc5"},' +
           '"properties":{' +
             '"Nom de la t\u00e2che":{"title":[{"type":"text","text":{"content":"' + $title + '"}}]},' +
             '"\u00c9tat":{"status":{"name":"En cours"}},' +
             '"Priorit\u00e9":{"select":{"name":"Haute"}}' +
           '},' +
           '"children":' + $blocksJson + '}'

# Write payload UTF-8 NoBOM
$tmpFile = Join-Path $PSScriptRoot "..\\.tmp\\notion_planning_payload.json"
[System.IO.File]::WriteAllText($tmpFile, $payload, (New-Object System.Text.UTF8Encoding $false))
Write-Host "Payload : $($payload.Length) chars" -ForegroundColor Gray

# POST to Notion API
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

    Write-Host "`nPage creee !" -ForegroundColor Green
    Write-Host "  ID  : $($response.id)" -ForegroundColor Gray
    Write-Host "  URL : $pageUrl" -ForegroundColor Cyan

} catch {
    $errBody = $_.ErrorDetails.Message
    Write-Error "Echec Notion API : $($_.Exception.Message)`n$errBody"
    exit 1
}
