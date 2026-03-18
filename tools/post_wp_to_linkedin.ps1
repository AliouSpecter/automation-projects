<#
Monitor WordPress drafts tagged pending-linkedin, post to LinkedIn, publish post
Run as: .\tools\post_wp_to_linkedin.ps1
#>

$envFile = Join-Path $PSScriptRoot "../.env"
Get-Content $envFile | Where-Object { $_ -match "^(WP_|LINKEDIN_)" } | ForEach-Object {
    $p = $_ -split "=", 2
    [System.Environment]::SetEnvironmentVariable($p[0].Trim(), $p[1].Trim())
}

$WP_URL = $env:WP_URL
$WP_USER = $env:WP_USER
$WP_PASS = $env:WP_APP_PASSWORD
$LI_TOKEN = $env:LINKEDIN_ACCESS_TOKEN
$LI_PID = $env:LINKEDIN_PERSON_ID

function Write-Log {
    param([string]$msg)
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "[$ts] $msg"
}

function Get-WPDrafts {
    Write-Log "Fetching WordPress drafts..."
    $creds = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("${WP_USER}:${WP_PASS}"))
    $headers = @{ "Authorization" = "Basic $creds" }

    try {
        $r = Invoke-RestMethod -Uri "$WP_URL/wp-json/wp/v2/posts?status=draft&tags=32&per_page=10" `
            -Headers $headers -TimeoutSec 10 -ErrorAction Stop

        if ($r -is [array]) {
            Write-Log "Found $($r.Count) draft(s)"
            return $r
        } else {
            Write-Log "Found 1 draft"
            return @($r)
        }
    } catch {
        Write-Log "Error fetching drafts: $_"
        return @()
    }
}

function Get-FeaturedImage {
    param([int]$mediaId)

    if (-not $mediaId) { return $null }

    $creds = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("${WP_USER}:${WP_PASS}"))
    $headers = @{ "Authorization" = "Basic $creds" }

    try {
        $r = Invoke-RestMethod -Uri "$WP_URL/wp-json/wp/v2/media/$mediaId" `
            -Headers $headers -TimeoutSec 10 -ErrorAction Stop

        if ($r.source_url) {
            Write-Log "  Downloading image from: $($r.source_url)"
            $imgResp = Invoke-WebRequest -Uri $r.source_url -TimeoutSec 10
            return $imgResp.Content
        }
    } catch {
        Write-Log "  Error getting image: $_"
    }
    return $null
}

function Init-LinkedInImage {
    $url = "https://api.linkedin.com/rest/images?action=initializeUpload"
    $headers = @{
        "Authorization" = "Bearer $LI_TOKEN"
        "LinkedIn-Version" = "202306"
        "X-Restli-Protocol-Version" = "2.0.0"
    }
    $payload = @{ initializeUploadRequest = @{ owner = "urn:li:person:$LI_PID" } }

    try {
        $r = Invoke-RestMethod -Method POST -Uri $url -Headers $headers `
            -Body ($payload | ConvertTo-Json -Depth 10) -TimeoutSec 15 -ErrorAction Stop

        return @{
            uploadUrl = $r.value.uploadUrl
            imageUrn  = $r.value.image
        }
    } catch {
        Write-Log "  Error initializing LinkedIn image: $_"
    }
    return $null
}

function Upload-ImageToLinkedIn {
    param([string]$uploadUrl, [byte[]]$imageData)

    $headers = @{ "Authorization" = "Bearer $LI_TOKEN" }

    try {
        Invoke-WebRequest -Method PUT -Uri $uploadUrl -Headers $headers -Body $imageData `
            -ContentType "image/png" -TimeoutSec 30 -ErrorAction Stop | Out-Null
        return $true
    } catch {
        Write-Log "  Error uploading image: $_"
    }
    return $false
}

function Post-ToLinkedIn {
    param([string]$text, [string]$imageUrn = "")

    $url = "https://api.linkedin.com/rest/posts"
    $headers = @{
        "Authorization" = "Bearer $LI_TOKEN"
        "LinkedIn-Version" = "202306"
        "X-Restli-Protocol-Version" = "2.0.0"
    }

    $payload = @{
        author  = "urn:li:person:$LI_PID"
        commentary = $text
        visibility = "PUBLIC"
        distribution = @{
            feedDistribution = "MAIN_FEED"
            targetEntities = @()
            thirdPartyDistributionChannels = @()
        }
        lifecycleState = "PUBLISHED"
        isReshareDisabledByAuthor = $false
    }

    if ($imageUrn) {
        $payload.content = @{ media = @{ id = $imageUrn } }
    }

    try {
        $r = Invoke-RestMethod -Method POST -Uri $url -Headers $headers `
            -Body ($payload | ConvertTo-Json -Depth 10) -TimeoutSec 15 -ErrorAction Stop

        return $r.id
    } catch {
        Write-Log "  Error posting to LinkedIn: $_"
    }
    return $null
}

function Publish-WPPost {
    param([int]$postId)

    $creds = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("${WP_USER}:${WP_PASS}"))
    $headers = @{ "Authorization" = "Basic $creds" }

    try {
        Invoke-RestMethod -Method POST -Uri "$WP_URL/wp-json/wp/v2/posts/$postId" `
            -Headers $headers -Body (@{ status = "publish" } | ConvertTo-Json) `
            -TimeoutSec 10 -ErrorAction Stop | Out-Null
        return $true
    } catch {
        Write-Log "  Error publishing post: $_"
    }
    return $false
}

# Main
Write-Log "=== WordPress to LinkedIn Processor ==="

$drafts = Get-WPDrafts
if ($drafts.Count -eq 0) {
    Write-Log "No drafts to process"
    exit 0
}

foreach ($post in $drafts) {
    Write-Log "Processing post ID: $($post.id)"

    $text = $post.content.rendered
    if ($text -match '<') {
        $text = $text -replace '<[^>]+>', ''
    }
    $text = $text.Trim()

    if (-not $text) {
        Write-Log "  Skipping: empty content"
        continue
    }

    $linkedInPostId = $null

    # Try with image if available
    if ($post.featured_media) {
        Write-Log "  Processing image: $($post.featured_media)"

        $imgData = Get-FeaturedImage -mediaId $post.featured_media
        if ($imgData) {
            Write-Log "  Initializing LinkedIn image upload..."
            $imgInit = Init-LinkedInImage

            if ($imgInit) {
                Write-Log "  Uploading image to LinkedIn..."
                if (Upload-ImageToLinkedIn -uploadUrl $imgInit.uploadUrl -imageData $imgData) {
                    Write-Log "  Posting to LinkedIn with image..."
                    $linkedInPostId = Post-ToLinkedIn -text $text -imageUrn $imgInit.imageUrn
                }
            }
        }
    }

    # Fallback to text-only
    if (-not $linkedInPostId) {
        Write-Log "  Posting text-only to LinkedIn..."
        $linkedInPostId = Post-ToLinkedIn -text $text
    }

    if ($linkedInPostId) {
        Write-Log "  ✓ Posted to LinkedIn: $linkedInPostId"

        Write-Log "  Publishing WordPress post..."
        if (Publish-WPPost -postId $post.id) {
            Write-Log "  ✓ Post published"
        } else {
            Write-Log "  ⚠ Failed to publish (LinkedIn post succeeded)"
        }
    } else {
        Write-Log "  ✗ Failed to post to LinkedIn"
    }
}

Write-Log "Done"
