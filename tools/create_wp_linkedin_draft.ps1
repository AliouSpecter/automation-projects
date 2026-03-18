<#
Create a WordPress draft post with text and image, tagged for LinkedIn posting
Uses WordPress REST API with Basic Auth
Returns post ID

Usage:
  .\tools\create_wp_linkedin_draft.ps1 -text "Mon contenu" -imagePath ".tmp/posts/image.png"
#>

param(
    [string]$text      = "",
    [string]$imagePath = ""
)

if (-not $text) { Write-Error "Parameter -text is required"; exit 1 }

$envFile = Join-Path $PSScriptRoot "../.env"
Get-Content $envFile | Where-Object { $_ -match "^WP_|^LINKEDIN_" } | ForEach-Object {
    $p = $_ -split "=", 2
    [System.Environment]::SetEnvironmentVariable($p[0].Trim(), $p[1].Trim())
}

$wpUrl = $env:WP_URL
$wpUser = $env:WP_USER
$wpPass = $env:WP_APP_PASSWORD

if (-not $wpUrl -or -not $wpUser -or -not $wpPass) {
    Write-Error "Missing WordPress config in .env (WP_URL, WP_USER, WP_APP_PASSWORD)"
    exit 1
}

$creds = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${wpUser}:${wpPass}"))
$headers = @{
    "Authorization" = "Basic $creds"
    "Content-Type"  = "application/json"
}

# Step 1: Upload image if provided
$imageMediaId = $null
if ($imagePath -and (Test-Path $imagePath)) {
    Write-Host "Uploading image..."
    try {
        $imgBytes = [System.IO.File]::ReadAllBytes((Resolve-Path $imagePath))
        $fileName = Split-Path $imagePath -Leaf

        $uploadHeaders = @{
            "Authorization"       = "Basic $creds"
            "Content-Disposition" = "attachment; filename=`"$fileName`""
            "Content-Type"        = "image/png"
        }

        $imgResp = Invoke-RestMethod -Method POST `
            -Uri "$wpUrl/wp-json/wp/v2/media" `
            -Headers $uploadHeaders -Body $imgBytes -TimeoutSec 30 -ErrorAction Stop

        $imageMediaId = $imgResp.id
        Write-Host "Image uploaded: ID $imageMediaId"
    } catch {
        Write-Error "Image upload failed: $($_.Exception.Message)"
        exit 1
    }
}

# Step 2: Create draft post
Write-Host "Creating draft post..."
$postBody = @{
    title       = [System.DateTime]::Now.ToString("yyyy-MM-dd HH:mm:ss LinkedIn Post")
    content     = $text
    status      = "draft"
    tags        = @()
}

# Tag with pending-linkedin (we'll get the tag ID first)
try {
    $tagResp = Invoke-RestMethod -Method GET `
        -Uri "$wpUrl/wp-json/wp/v2/tags?slug=pending-linkedin&per_page=100" `
        -Headers $headers -TimeoutSec 10 -ErrorAction Stop

    if ($tagResp -and $tagResp.Count -gt 0) {
        $postBody.tags = @($tagResp[0].id)
        Write-Host "Using existing tag: pending-linkedin (ID $($tagResp[0].id))"
    } else {
        # Create tag if it doesn't exist
        $newTag = Invoke-RestMethod -Method POST `
            -Uri "$wpUrl/wp-json/wp/v2/tags" `
            -Headers $headers `
            -Body (@{ name = "pending-linkedin" } | ConvertTo-Json) `
            -TimeoutSec 10 -ErrorAction Stop
        $postBody.tags = @($newTag.id)
        Write-Host "Created new tag: pending-linkedin (ID $($newTag.id))"
    }
} catch {
    Write-Host "Warning: Could not manage tags: $($_.Exception.Message)"
}

# Attach image to post if uploaded
if ($imageMediaId) {
    $postBody.featured_media = $imageMediaId
}

try {
    $postResp = Invoke-RestMethod -Method POST `
        -Uri "$wpUrl/wp-json/wp/v2/posts" `
        -Headers $headers `
        -Body ($postBody | ConvertTo-Json -Depth 3) `
        -TimeoutSec 30 -ErrorAction Stop

    Write-Host "Draft created successfully!"
    Write-Host "Post ID: $($postResp.id)"
    Write-Host "URL: $($postResp.link)"
    Write-Output $postResp.id

} catch {
    Write-Error "Post creation failed: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        try {
            $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
            Write-Error $reader.ReadToEnd()
        } catch {}
    }
    exit 1
}
