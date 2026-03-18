# Generate image via n8n /webhook/linkedin-generate (Gemini)
# Usage: powershell.exe -ExecutionPolicy Bypass -File tools/generate_image_gemini.ps1 -postFile ".tmp/posts/YYYY-MM-DD-slug.md" [-outputFile ".tmp/posts/YYYY-MM-DD-slug.png"]

param(
    [string]$postFile   = "",
    [string]$outputFile = ""
)

$N8N_URL = "https://n8n.srv1105514.hstgr.cloud"

if (-not $postFile -or -not (Test-Path $postFile)) {
    Write-Host "ERROR: -postFile required and must exist"
    exit 1
}

# Read post content
$postContent = [System.IO.File]::ReadAllText(
    (Resolve-Path $postFile).Path,
    [System.Text.Encoding]::UTF8
)

# Extract the ## Post section
$postMatch = [regex]::Match($postContent, '## Post\s*\r?\n([\s\S]*?)(?:\r?\n## |\z)')
if (-not $postMatch.Success) {
    Write-Host "ERROR: Could not find ## Post section in file"
    exit 1
}
$postText = $postMatch.Groups[1].Value.Trim()
Write-Host "Post text: $($postText.Length) chars"

# Derive output file from input if not specified
if (-not $outputFile) {
    $outputFile = $postFile -replace '\.md$', '.png'
}

# Build JSON payload via ConvertTo-Json (handles all escaping correctly)
$payloadObj = @{ text = $postText }
$payloadJson = $payloadObj | ConvertTo-Json -Compress -Depth 2

# Write to temp file (avoids shell escaping issues with curl)
$payloadFile = ".tmp/_gemini_img_payload.json"
[System.IO.File]::WriteAllText(
    (Join-Path (Get-Location) $payloadFile),
    $payloadJson,
    [System.Text.UTF8Encoding]::new($false)
)

# POST to webhook
$respFile = ".tmp/_gemini_img_resp.json"
Write-Host "Calling /webhook/linkedin-generate..."
$status = & curl.exe -s -o $respFile -w "%{http_code}" `
    -X POST `
    -H "Content-Type: application/json" `
    --data-binary "@$payloadFile" `
    "$N8N_URL/webhook/linkedin-generate"

Write-Host "HTTP: $status"

if ($status -ne "200") {
    Write-Host "ERROR response:"
    Get-Content $respFile -Raw | Select-String "." | Select-Object -First 5
    exit 1
}

$respRaw = [System.IO.File]::ReadAllText(
    (Resolve-Path $respFile).Path,
    [System.Text.Encoding]::UTF8
)

# Extract imageBase64 field
$imgMatch = [regex]::Match($respRaw, '"imageBase64"\s*:\s*"([^"]+)"')
if (-not $imgMatch.Success) {
    Write-Host "ERROR: imageBase64 not found in response"
    Write-Host "Response: $($respRaw.Substring(0, [Math]::Min(500, $respRaw.Length)))"
    exit 1
}
$b64 = $imgMatch.Groups[1].Value

# Decode base64 → PNG
$bytes = [Convert]::FromBase64String($b64)
[System.IO.File]::WriteAllBytes((Join-Path (Get-Location) $outputFile), $bytes)

Write-Host "Image saved: $outputFile ($($bytes.Length) bytes)"

# Extract postType for info
$typeMatch = [regex]::Match($respRaw, '"postType"\s*:\s*"([^"]+)"')
if ($typeMatch.Success) { Write-Host "Post type: $($typeMatch.Groups[1].Value)" }

# Cleanup
Remove-Item $respFile -ErrorAction SilentlyContinue
Remove-Item $payloadFile -ErrorAction SilentlyContinue
