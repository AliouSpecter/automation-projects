<#
.SYNOPSIS
  Resume des couts et quotas API utilisees dans les automations N8N.
.USAGE
  .\tools\check_api_costs.ps1
#>

$envFile = Join-Path $PSScriptRoot "..\.env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            [System.Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim())
        }
    }
}

$ANTHROPIC_KEY  = $env:ANTHROPIC_API_KEY
$PERPLEXITY_KEY = $env:PERPLEXITY_API_KEY
$APIFY_KEY      = $env:APIFY_API_KEY
$HUNTER_KEY     = $env:HUNTER_API_KEY
$N8N_URL        = $env:N8N_BASE_URL
$N8N_KEY        = $env:N8N_API_KEY

function Show-Section($title) {
    Write-Host ""
    Write-Host "=== $title ===" -ForegroundColor Cyan
}

# HUNTER.IO
Show-Section "Hunter.io"
if ($HUNTER_KEY) {
    try {
        $r = Invoke-RestMethod "https://api.hunter.io/v1/account?api_key=$HUNTER_KEY" -Method GET
        Write-Host "Plan            : $($r.plan_name)"
        Write-Host "Searches        : $($r.requests.searches.used) / $($r.requests.searches.available) ce mois"
        Write-Host "Verifications   : $($r.requests.verifications.used) / $($r.requests.verifications.available) ce mois"
        Write-Host "Reset le        : $($r.reset_date)"
        $remaining = $r.requests.searches.available - $r.requests.searches.used
        if ($remaining -lt 5) {
            Write-Host "ALERTE : $remaining searches restantes seulement" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Erreur Hunter.io : $_" -ForegroundColor Red
    }
} else {
    Write-Host "HUNTER_API_KEY non definie" -ForegroundColor DarkGray
}

# APIFY
Show-Section "Apify"
if ($APIFY_KEY) {
    try {
        $r = Invoke-RestMethod "https://api.apify.com/v2/users/me?token=$APIFY_KEY" -Method GET
        $d = $r.data
        $plan = $d.plan
        Write-Host "Plan            : $($plan.id)"
        Write-Host "Credits/mois    : $($plan.monthlyUsageCreditsUsd) USD inclus"
        Write-Host "Max credits/mois: $($plan.maxMonthlyUsageUsd) USD"
        Write-Host "Compute units   : max $($plan.maxMonthlyActorComputeUnits) / mois"
        Write-Host "Proxy SERPs     : max $($plan.maxMonthlyProxySerps) / mois"
        Write-Host "Usage detaille  : https://console.apify.com/billing"
    } catch {
        Write-Host "Erreur Apify : $_" -ForegroundColor Red
    }
} else {
    Write-Host "APIFY_API_KEY non definie" -ForegroundColor DarkGray
}

# ANTHROPIC
Show-Section "Anthropic (Claude)"
if ($ANTHROPIC_KEY) {
    try {
        $headers = @{ "x-api-key" = $ANTHROPIC_KEY; "anthropic-version" = "2023-06-01" }
        Invoke-RestMethod "https://api.anthropic.com/v1/models" -Headers $headers -Method GET | Out-Null
        Write-Host "Cle API         : OK (valide)"
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        if ($code -eq 401) {
            Write-Host "Cle API         : INVALIDE" -ForegroundColor Red
        } else {
            Write-Host "Cle API         : OK"
        }
    }
    Write-Host "Couts           : https://console.anthropic.com/settings/billing"
    Write-Host "Usage tokens    : https://console.anthropic.com/settings/usage"
} else {
    Write-Host "ANTHROPIC_API_KEY non definie" -ForegroundColor DarkGray
}

# PERPLEXITY
Show-Section "Perplexity"
if ($PERPLEXITY_KEY) {
    Write-Host "Cle API         : configuree"
    Write-Host "Couts           : https://www.perplexity.ai/settings/api"
    Write-Host "Note            : pas d'API usage - voir le dashboard"
} else {
    Write-Host "PERPLEXITY_API_KEY non definie" -ForegroundColor DarkGray
}

# N8N EXECUTIONS
Show-Section "N8N - Volume executions (30 dernieres)"
if ($N8N_URL -and $N8N_KEY) {
    try {
        $headers = @{ "X-N8N-API-KEY" = $N8N_KEY }
        $url = "$N8N_URL/api/v1/executions?limit=30&includeData=false"
        $r = Invoke-RestMethod $url -Headers $headers -Method GET
        $execs   = $r.data
        $success = ($execs | Where-Object { $_.status -eq "success" }).Count
        $errors  = ($execs | Where-Object { $_.status -eq "error" }).Count
        $running = ($execs | Where-Object { $_.status -eq "running" }).Count
        Write-Host "Total           : $($execs.Count) executions"
        Write-Host "Success         : $success"
        Write-Host "Erreurs         : $errors"
        if ($running -gt 0) { Write-Host "En cours        : $running" }
    } catch {
        Write-Host "Erreur N8N : $_" -ForegroundColor Red
    }
} else {
    Write-Host "N8N_BASE_URL ou N8N_API_KEY non definis" -ForegroundColor DarkGray
}

Write-Host ""
