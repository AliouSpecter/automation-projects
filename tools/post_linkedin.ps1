<#
Post to LinkedIn with optional image
Usage:
  .\tools\post_linkedin.ps1 -text "Mon post LinkedIn" -imagePath ".tmp/posts/image.png"
  .\tools\post_linkedin.ps1 -text "Mon post LinkedIn"   # texte seul, sans image
#>

param(
    [string]$text      = "",
    [string]$imagePath = ""
)

if (-not $text) { Write-Error "Parameter -text is required"; exit 1 }

# Load .env
$envFile = Join-Path $PSScriptRoot "../.env"
Get-Content $envFile | Where-Object { $_ -match "^LINKEDIN_" } | ForEach-Object {
    $p = $_ -split "=", 2
    [System.Environment]::SetEnvironmentVariable($p[0].Trim(), $p[1].Trim())
}

$token    = $env:LINKEDIN_ACCESS_TOKEN
$personId = $env:LINKEDIN_PERSON_ID

if (-not $token)    { Write-Error "LINKEDIN_ACCESS_TOKEN missing in .env - run tools/linkedin_auth.ps1 first"; exit 1 }
if (-not $personId) { Write-Error "LINKEDIN_PERSON_ID missing in .env"; exit 1 }

$authorUrn = "urn:li:person:$personId"

$headers = @{
    Authorization      = "Bearer $token"
    "Content-Type"     = "application/json"
    "LinkedIn-Version" = "202306"
    "X-Restli-Protocol-Version" = "2.0.0"
}

# Upload image if provided
$imageUrn = $null

if ($imagePath -and (Test-Path $imagePath)) {
    Write-Host "Uploading image..."

    # Step 1: Initialize upload
    $initBody = @{
        initializeUploadRequest = @{
            owner = $authorUrn
        }
    } | ConvertTo-Json -Depth 5

    try {
        $initResp = Invoke-RestMethod -Method POST `
            -Uri "https://api.linkedin.com/rest/images?action=initializeUpload" `
            -Headers $headers -Body $initBody -TimeoutSec 30 -ErrorAction Stop

        $uploadUrl = $initResp.value.uploadUrl
        $imageUrn  = $initResp.value.image

        # Step 2: Upload binary
        $imgBytes = [System.IO.File]::ReadAllBytes((Resolve-Path $imagePath))
        $uploadHeaders = @{ Authorization = "Bearer $token" }
        Invoke-RestMethod -Method PUT -Uri $uploadUrl -Headers $uploadHeaders `
            -Body $imgBytes -ContentType "application/octet-stream" -TimeoutSec 30 -ErrorAction Stop

        Write-Host "Image uploaded: $imageUrn"

    } catch {
        Write-Host "Image upload failed: $($_.Exception.Message) - posting without image"
        $imageUrn = $null
    }
}

# Build post body
if ($imageUrn) {
    $postBody = @{
        author         = $authorUrn
        commentary     = $text
        visibility     = "PUBLIC"
        distribution   = @{
            feedDistribution              = "MAIN_FEED"
            targetEntities                = @()
            thirdPartyDistributionChannels = @()
        }
        content        = @{
            media = @{
                title = ""
                id    = $imageUrn
            }
        }
        lifecycleState = "PUBLISHED"
        isReshareDisabledByAuthor = $false
    }
} else {
    $postBody = @{
        author         = $authorUrn
        commentary     = $text
        visibility     = "PUBLIC"
        distribution   = @{
            feedDistribution              = "MAIN_FEED"
            targetEntities                = @()
            thirdPartyDistributionChannels = @()
        }
        lifecycleState = "PUBLISHED"
        isReshareDisabledByAuthor = $false
    }
}

# Post
Write-Host "Posting to LinkedIn..."

try {
    $r = Invoke-RestMethod -Method POST `
        -Uri "https://api.linkedin.com/rest/posts" `
        -Headers $headers -Body ($postBody | ConvertTo-Json -Depth 10) `
        -TimeoutSec 30 -ErrorAction Stop

    Write-Host "Posted successfully!"
    $postId = if ($r.id) { $r.id } else { "created" }
    Write-Host "Post ID: $postId"
    Write-Output $postId

} catch {
    Write-Error "LinkedIn post failed: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        try {
            $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
            Write-Error $reader.ReadToEnd()
        } catch {}
    }
    exit 1
}
