<#
Generate LinkedIn post image via htmlcsstoimage.com API
Usage:
  .\tools\generate_image.ps1 -postType "Resultat concret" -metrics "avant1,avant2,avant3,apres1,apres2,apres3"
  .\tools\generate_image.ps1 -postType "Architecture" -title "Mon objectif" -tools "n8n,OpenAI,CRM"
  .\tools\generate_image.ps1 -postType "Optimisation" -metrics "avant,apres,gain"
  .\tools\generate_image.ps1 -postType "Preuve" -metrics "item1,item2,item3"

Post types: "Resultat concret" | "Architecture" | "Optimisation" | "Preuve"
#>

param(
    [string]$postType   = "Resultat concret",
    [string]$metrics    = "",
    [string]$title      = "Automation Impact",
    [string]$tools      = "",
    [string]$outputFile = "",
    [string]$leftBadge  = "Sans automatisation",
    [string]$rightBadge = "Avec automatisation"
)

# No API key needed - uses Edge headless (local)

if (-not $outputFile) {
    $date = Get-Date -Format "yyyy-MM-dd"
    $outputFile = ".tmp/posts/$date-image.png"
}

$mList = @($metrics -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ })
$tList = @($tools   -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ })

function Get-Val($arr, $i) {
    if ($arr.Count -gt $i -and $arr[$i]) { return $arr[$i] }
    return "-"
}

$baseStyle = @"
* { margin:0; padding:0; box-sizing:border-box; }
body {
    font-family: 'Inter', 'Segoe UI', sans-serif;
    width: 1080px; height: 1080px;
    background: #F2FBF5;
    background-image: linear-gradient(rgba(0,0,0,0.03) 1px, transparent 1px), linear-gradient(90deg, rgba(0,0,0,0.03) 1px, transparent 1px);
    background-size: 48px 48px;
    display: flex; flex-direction: column;
    align-items: center; justify-content: center; padding: 40px;
}
.card { background:#fff; border-radius:20px; box-shadow:0 8px 32px rgba(0,0,0,0.08); padding:48px; }
.footer { width:100%; display:flex; justify-content:space-between; align-items:center; margin-top:28px; padding:0 8px; }
.footer-col { font-size:13px; color:#94A3B8; text-align:center; flex:1; }
.footer-brand { font-size:12px; color:#CBD5E1; }
"@

$footerHtml = @"
<div class='footer'>
  <div class='footer-col'>Temps de d&#233;ploiement</div>
  <div class='footer-col'>Z&#233;ro outil ajout&#233;</div>
  <div class='footer-col'>Premiers r&#233;sultats</div>
  <div class='footer-brand'>automationact.com</div>
</div>
"@

if ($postType -eq "Resultat concret") {
    $l0 = Get-Val $mList 0; $l1 = Get-Val $mList 1; $l2 = Get-Val $mList 2
    $r0 = Get-Val $mList 3; $r1 = Get-Val $mList 4; $r2 = Get-Val $mList 5
    $html = @"
<!DOCTYPE html><html><head><style>
$baseStyle
body { padding:0 !important; align-items:stretch !important; justify-content:flex-start !important; }
.cards { display:flex; flex:1; gap:4px; width:100%; }
.card { flex:1; border-radius:0; display:flex; flex-direction:column; justify-content:center; padding:64px 56px; }
.badge { font-size:12px; font-weight:700; letter-spacing:1px; text-transform:uppercase; padding:6px 14px; border-radius:6px; display:inline-block; margin-bottom:40px; }
.badge-l { background:#EEF2FF; color:#0F172A; }
.badge-r { background:#D1FAE5; color:#2F9E6B; }
.row { margin-bottom:32px; }
.val { font-size:56px; font-weight:800; line-height:1.1; }
.vl { color:#0F172A; }
.vr { color:#2F9E6B; }
.footer { padding:20px 40px; border-top:1px solid #E8F5EE; }
</style></head><body>
<div class='cards'>
  <div class='card'>
    <div class='badge badge-l'>$leftBadge</div>
    <div class='row'><div class='val vl'>$l0</div></div>
    <div class='row'><div class='val vl'>$l1</div></div>
    <div class='row'><div class='val vl'>$l2</div></div>
  </div>
  <div class='card'>
    <div class='badge badge-r'>$rightBadge</div>
    <div class='row'><div class='val vr'>$r0</div></div>
    <div class='row'><div class='val vr'>$r1</div></div>
    <div class='row'><div class='val vr'>$r2</div></div>
  </div>
</div>
$footerHtml
</body></html>
"@
}
elseif ($postType -eq "Architecture") {
    $pillsHtml = ""
    for ($i = 0; $i -lt $tList.Count; $i++) {
        if ($i -gt 0) { $pillsHtml += "<span class='arrow'>-></span>" }
        $pillsHtml += "<span class='pill'>$($tList[$i])</span>"
    }
    $html = @"
<!DOCTYPE html><html><head><style>
$baseStyle
.card { width:100%; }
.badge { font-size:12px; font-weight:700; letter-spacing:1px; text-transform:uppercase; padding:6px 14px; border-radius:6px; background:#EEF2FF; color:#0F172A; display:inline-block; margin-bottom:20px; }
h1 { font-size:36px; font-weight:800; color:#0F172A; margin-bottom:40px; line-height:1.2; }
.flow { display:flex; flex-wrap:wrap; gap:12px; align-items:center; margin-bottom:32px; }
.pill { background:#2F9E6B; color:#fff; font-size:16px; font-weight:700; padding:12px 22px; border-radius:10px; }
.arrow { font-size:22px; color:#94A3B8; }
.note { font-size:15px; color:#94A3B8; font-style:italic; border-top:1px solid #F1F5F9; padding-top:20px; }
</style></head><body>
<div class='card'>
  <div class='badge'>Architecture</div>
  <h1>$title</h1>
  <div class='flow'>$pillsHtml</div>
  <div class='note'>Pas d&#39;outil ajout&#233; - orchestration de l&#39;existant</div>
</div>
$footerHtml
</body></html>
"@
}
elseif ($postType -eq "Optimisation") {
    $avant = Get-Val $mList 0
    $apres = Get-Val $mList 1
    $gain  = Get-Val $mList 2
    $html = @"
<!DOCTYPE html><html><head><style>
$baseStyle
.card { width:100%; }
.badge { font-size:12px; font-weight:700; letter-spacing:1px; text-transform:uppercase; padding:6px 14px; border-radius:6px; background:#EEF2FF; color:#0F172A; display:inline-block; margin-bottom:28px; }
.section { margin-bottom:24px; }
.label { font-size:14px; font-weight:600; text-transform:uppercase; letter-spacing:1px; color:#94A3B8; margin-bottom:8px; }
.val { font-size:44px; font-weight:800; color:#0F172A; line-height:1.1; }
.val-green { color:#2F9E6B; }
.sep { height:1px; background:#F1F5F9; margin:24px 0; }
.gain-block { text-align:center; margin-top:8px; }
.gain-val { font-size:72px; font-weight:900; color:#2F9E6B; }
</style></head><body>
<div class='card'>
  <div class='badge'>Optimisation</div>
  <div class='section'><div class='label'>Avant</div><div class='val'>$avant</div></div>
  <div class='sep'></div>
  <div class='section'><div class='label' style='color:#2F9E6B;'>Apr&#232;s</div><div class='val val-green'>$apres</div></div>
  <div class='gain-block'><div class='label'>Gain</div><div class='gain-val'>$gain</div></div>
</div>
$footerHtml
</body></html>
"@
}
else {
    # Preuve
    $itemsHtml = ""
    foreach ($item in $mList) {
        $itemsHtml += "<div class='item'><span class='check'>OK</span><span class='txt'>$item</span></div>"
    }
    $html = @"
<!DOCTYPE html><html><head><style>
$baseStyle
.card { width:100%; }
.badge { font-size:12px; font-weight:700; letter-spacing:1px; text-transform:uppercase; padding:6px 14px; border-radius:6px; background:#D1FAE5; color:#2F9E6B; display:inline-block; margin-bottom:32px; }
.item { display:flex; align-items:flex-start; gap:16px; margin-bottom:24px; }
.check { width:32px; height:32px; background:#2F9E6B; color:#fff; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:13px; font-weight:800; flex-shrink:0; padding-top:2px; }
.txt { font-size:22px; font-weight:700; color:#0F172A; line-height:1.3; }
</style></head><body>
<div class='card'>
  <div class='badge'>R&#233;sultats</div>
  $itemsHtml
</div>
$footerHtml
</body></html>
"@
}

# Generate image using Edge headless (local, no API key needed)
Write-Host "Generating image ($postType) via Edge headless..."

$outPath = Join-Path (Get-Location) $outputFile
$outDir  = Split-Path $outPath -Parent
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

# Save HTML to temp file
$htmlTmp = "$outDir\tmp_image_$([System.Guid]::NewGuid().ToString('N')).html"
[System.IO.File]::WriteAllText($htmlTmp, $html, [System.Text.Encoding]::UTF8)

$edgePaths = @(
    "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
)
$edgePath = $edgePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $edgePath) {
    Remove-Item $htmlTmp -Force
    Write-Error "Microsoft Edge not found."
    exit 1
}

$htmlUri = "file:///" + $htmlTmp.Replace('\', '/')

& $edgePath `
    "--headless=old" `
    --disable-gpu `
    --no-sandbox `
    --hide-scrollbars `
    "--screenshot=$outPath" `
    "--window-size=1080,1080" `
    $htmlUri

Start-Sleep -Seconds 2
Remove-Item $htmlTmp -Force -ErrorAction SilentlyContinue

if (Test-Path $outPath) {
    Write-Host "Saved: $outPath"
    Write-Output $outPath
} else {
    Write-Error "Image generation failed - file not created."
    exit 1
}
