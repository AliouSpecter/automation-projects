<#
Generate LinkedIn image via n8n (Gemini) from a prompt and save as PNG.
Usage:
  .\tools\get_linkedin_image.ps1 -prompt "1080x1080px image..." -outputPath ".tmp/posts/2026-03-08-image.png"
Returns the output path on success.
#>

param(
    [string]$prompt     = "",
    [string]$outputPath = ""
)

if (-not $prompt)     { Write-Error "Parameter -prompt is required"; exit 1 }
if (-not $outputPath) { Write-Error "Parameter -outputPath is required"; exit 1 }

# Load .env
$envFile = Join-Path $PSScriptRoot "../.env"
Get-Content $envFile | Where-Object { $_ -match "^N8N_" } | ForEach-Object {
    $p = $_ -split "=", 2
    [System.Environment]::SetEnvironmentVariable($p[0].Trim(), $p[1].Trim())
}

$n8nBase = $env:N8N_BASE_URL
if (-not $n8nBase) { Write-Error "N8N_BASE_URL missing in .env"; exit 1 }

$webhookUrl = "$n8nBase/webhook/linkedin-post"

Write-Host "Generating image via Gemini..."

try {
    # Build JSON manually to avoid PS5 ConvertTo-Json accent corruption
    $escaped = $prompt -replace '\\', '\\' -replace '"', '\"' -replace "`r`n", '\n' -replace "`n", '\n'
    $body = '{"prompt":"' + $escaped + '"}'
    $r = Invoke-RestMethod -Method POST -Uri $webhookUrl `
        -ContentType "application/json" -Body $body `
        -TimeoutSec 120 -ErrorAction Stop

    $b64 = $r.imageBase64
    if (-not $b64) { Write-Error "No imageBase64 in response"; exit 1 }

    # Ensure output directory exists
    $dir = Split-Path $outputPath -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    # Decode and save
    $absPath = (Resolve-Path $dir).Path + "\" + (Split-Path $outputPath -Leaf)
    $bytes = [Convert]::FromBase64String($b64)
    [System.IO.File]::WriteAllBytes($absPath, $bytes)

    Write-Host "Image saved: $outputPath ($([math]::Round($bytes.Length/1024))KB)"
    Write-Output $outputPath

} catch {
    Write-Error "Image generation failed: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        try {
            $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
            Write-Error $reader.ReadToEnd()
        } catch {}
    }
    exit 1
}
