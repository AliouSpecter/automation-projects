# tools/update_notion_email.ps1
# Met à jour l'email d'une entrée Notion
# Usage:
#   powershell.exe -ExecutionPolicy Bypass -File tools/update_notion_email.ps1 -PageId "ID" -Email "email@example.com"

param(
    [Parameter(Mandatory=$true)]
    [string]$PageId,
    
    [Parameter(Mandatory=$true)]
    [string]$Email
)

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

Write-Host "=== Mise à jour de l'email dans Notion ===" -ForegroundColor Cyan
Write-Host "Page ID : $PageId" -ForegroundColor Gray
Write-Host "Email : $Email`n" -ForegroundColor Gray

# ── Update Notion Page ────────────────────────────────────────────────────────
$headers = @{
    "Authorization"  = "Bearer $notionKey"
    "Notion-Version" = "2022-06-28"
    "Content-Type"   = "application/json"
}

$body = @{
    properties = @{
        Email = @{
            email = $Email
        }
    }
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Method PATCH `
        -Uri "https://api.notion.com/v1/pages/$PageId" `
        -Headers $headers `
        -Body $body `
        -ErrorAction Stop

    Write-Host "✓ Email mis à jour avec succès !" -ForegroundColor Green
    Write-Host "Page ID : $($response.id)" -ForegroundColor Gray
    Write-Host "Email : $($response.properties.Email.email)" -ForegroundColor Green

} catch {
    $errBody = $_.ErrorDetails.Message
    Write-Error "Échec de la mise à jour : $($_.Exception.Message)`n$errBody"
    exit 1
}
