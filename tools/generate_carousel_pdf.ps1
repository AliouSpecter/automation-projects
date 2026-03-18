# tools/generate_carousel_pdf.ps1
# Genere un PDF carrousel LinkedIn depuis un fichier HTML
#
# Usage:
#   powershell.exe -ExecutionPolicy Bypass -File tools/generate_carousel_pdf.ps1 -HtmlFile ".tmp/slides.html" -OutputPdf ".tmp/carousel.pdf"

param(
    [string]$HtmlFile  = ".tmp\carousel-brief-2026-03-09.html",
    [string]$OutputPdf = ".tmp\carousel-brief-2026-03-09.pdf"
)

$ErrorActionPreference = "Stop"

$root    = Split-Path $PSScriptRoot -Parent
$htmlAbs = Join-Path $root $HtmlFile
$pdfAbs  = Join-Path $root $OutputPdf

if (-not (Test-Path $htmlAbs)) {
    Write-Error "Fichier HTML introuvable : $htmlAbs"
    exit 1
}

# Trouver Edge
$edgePaths = @(
    "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
)
$edge = $edgePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $edge) {
    Write-Error "Microsoft Edge introuvable."
    exit 1
}

Write-Host "HTML  : $htmlAbs" -ForegroundColor Cyan
Write-Host "PDF   : $pdfAbs"  -ForegroundColor Cyan
Write-Host "Edge  : $edge"    -ForegroundColor Gray

# Generer le PDF
$fileUrl = "file:///" + ($htmlAbs -replace "\\", "/")
Write-Host "`nGeneration PDF..." -ForegroundColor Yellow

& $edge `
    "--headless=old" `
    --disable-gpu `
    --no-sandbox `
    --hide-scrollbars `
    "--print-to-pdf=$pdfAbs" `
    "--no-pdf-header-footer" `
    "--window-size=1080,8100" `
    $fileUrl

Start-Sleep -Seconds 4

if (Test-Path $pdfAbs) {
    $size = [math]::Round((Get-Item $pdfAbs).Length / 1KB, 1)
    Write-Host "PDF genere : $pdfAbs ($size KB)" -ForegroundColor Green
} else {
    Write-Error "Le PDF n'a pas ete genere."
    exit 1
}
