<#
WordPress REST API Tool
Usage:
  .\tools\wp_api.ps1 posts                         # list all automation posts
  .\tools\wp_api.ps1 get <id_or_slug>              # get post HTML content
  .\tools\wp_api.ps1 create <title> <html_file>    # create draft post from HTML file
  .\tools\wp_api.ps1 duplicate <id_or_slug>        # duplicate post as draft
#>

param([string]$cmd, [string]$arg1, [string]$arg2)

# Load credentials from .env
$envFile = Join-Path $PSScriptRoot "..\\.env"
if (Test-Path $envFile) {
    Get-Content $envFile | Where-Object { $_ -match "^WP_" } | ForEach-Object {
        $parts = $_ -split "=", 2
        [System.Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1].Trim())
    }
}

$WP_URL  = $env:WP_URL.TrimEnd("/")
$WP_USER = $env:WP_USER
$WP_PASS = $env:WP_APP_PASSWORD
$base64  = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${WP_USER}:${WP_PASS}"))
$headers = @{ Authorization = "Basic $base64"; "Content-Type" = "application/json" }

function Resolve-Post($idOrSlug) {
    try {
        $id = [int]$idOrSlug
        return Invoke-RestMethod -Uri "$WP_URL/wp-json/wp/v2/posts/$id" -Headers $headers
    } catch {
        $posts = Invoke-RestMethod -Uri "$WP_URL/wp-json/wp/v2/posts?slug=$idOrSlug&_fields=id,slug,title" -Headers $headers
        if (-not $posts) { Write-Host "Post not found: $idOrSlug"; exit 1 }
        return Invoke-RestMethod -Uri "$WP_URL/wp-json/wp/v2/posts/$($posts[0].id)" -Headers $headers
    }
}

switch ($cmd) {
    "posts" {
        $r = Invoke-RestMethod -Uri "$WP_URL/wp-json/wp/v2/posts?per_page=50&_fields=id,slug,title,status" -Headers $headers
        Write-Host ("{0,-8} {1,-12} {2}" -f "ID", "STATUS", "SLUG/TITLE")
        Write-Host ("-" * 80)
        $r | ForEach-Object { Write-Host ("{0,-8} {1,-12} {2}" -f $_.id, $_.status, $_.slug) }
    }
    "get" {
        $post = Resolve-Post $arg1
        Write-Host "=== $($post.title.rendered) (ID: $($post.id)) ==="
        $post.content.rendered
    }
    "create" {
        $html = Get-Content $arg2 -Raw -Encoding UTF8
        $obj  = [ordered]@{ title = $arg1; content = $html; status = "draft" }
        $body = $obj | ConvertTo-Json -Depth 5 -Compress
        $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
        $r = Invoke-RestMethod -Method POST -Uri "$WP_URL/wp-json/wp/v2/posts" -Headers $headers -Body $bodyBytes
        Write-Host "Created draft post:"
        Write-Host "  ID   : $($r.id)"
        Write-Host "  Edit : $WP_URL/wp-admin/post.php?post=$($r.id)&action=edit"
    }
    "duplicate" {
        $post = Resolve-Post $arg1
        $body = @{ title = "[COPY] $($post.title.rendered)"; content = $post.content.rendered; status = "draft" } | ConvertTo-Json -Compress
        $r = Invoke-RestMethod -Method POST -Uri "$WP_URL/wp-json/wp/v2/posts" -Headers $headers -Body $body
        Write-Host "Duplicated as draft:"
        Write-Host "  Source : $($post.title.rendered) (ID: $($post.id))"
        Write-Host "  New ID : $($r.id)"
        Write-Host "  Edit   : $WP_URL/wp-admin/post.php?post=$($r.id)&action=edit"
    }
    default {
        Get-Help $MyInvocation.MyCommand.Path
    }
}
