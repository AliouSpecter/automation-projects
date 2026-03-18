<#
Generate CV PDF — Convert HTML to PDF via Edge headless (local, no API)
Usage: .\tools\generate_cv_pdf.ps1 -htmlFile ".tmp/cv_content.html" -outputName "CV - Traffic Manager - Entreprise - 2026-03-05"

Output: cv/generated/[outputName].pdf
Returns: full path to the generated PDF
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$htmlFile,

    [string]$outputName = ""
)

$ErrorActionPreference = "Stop"

# ── Resolve paths ──────────────────────────────────────────────────────────────

$projectRoot = Split-Path $PSScriptRoot -Parent

$resolvedHtml = if ([System.IO.Path]::IsPathRooted($htmlFile)) {
    $htmlFile
} else {
    Join-Path $projectRoot $htmlFile
}

if (-not (Test-Path $resolvedHtml)) {
    Write-Error "Fichier HTML introuvable : $resolvedHtml"
    exit 1
}

# ── Output path ────────────────────────────────────────────────────────────────

$outputDir = Join-Path $projectRoot "cv\generated"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

if (-not $outputName) {
    $outputName = "CV - " + (Get-Date -Format "yyyy-MM-dd")
}

# Sanitize filename (remove chars invalid in Windows paths)
$safeName = $outputName -replace '[\\/:*?"<>|]', '-'
$pdfPath  = Join-Path $outputDir "$safeName.pdf"

# ── Find Edge ──────────────────────────────────────────────────────────────────

$edgePaths = @(
    "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
)
$edgePath = $edgePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $edgePath) {
    Write-Error "Microsoft Edge introuvable. Verifie l'installation."
    exit 1
}

# ── Convert to PDF ─────────────────────────────────────────────────────────────

$htmlUri = "file:///" + $resolvedHtml.Replace('\', '/')

Write-Host "Generation du PDF via Edge headless..." -ForegroundColor Cyan
Write-Host "  Source : $resolvedHtml"
Write-Host "  Output : $pdfPath"

& $edgePath `
    "--headless=old" `
    --disable-gpu `
    --no-sandbox `
    "--print-to-pdf=$pdfPath" `
    --no-pdf-header-footer `
    $htmlUri

# ── Wait for file to be written (Edge can delay a few seconds) ─────────────────

$waited = 0
while (-not (Test-Path $pdfPath) -and $waited -lt 12) {
    Start-Sleep -Seconds 1
    $waited++
}

if (-not (Test-Path $pdfPath)) {
    Write-Error "PDF non genere. Edge a peut-etre rencontre une erreur."
    exit 1
}

$sizeKb = [Math]::Round((Get-Item $pdfPath).Length / 1KB)

Write-Host ""
Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
Write-Host " PDF genere avec succes !" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
Write-Host " Fichier : $safeName.pdf"
Write-Host " Taille  : $sizeKb KB"
Write-Host " Chemin  : $pdfPath" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Output $pdfPath
