# tools/share_workflow_notion.ps1
# Exporte le workflow Google Ads Test Engine V2 depuis n8n
# et cree une page Notion prete a partager.
#
# Usage:
#   powershell.exe -ExecutionPolicy Bypass -File tools/share_workflow_notion.ps1

$ErrorActionPreference = "Stop"

# ── Helper: escape string for embedding in JSON ───────────────────────────────
function ConvertTo-JsonString {
    param([string]$s)
    $sb = [System.Text.StringBuilder]::new()
    foreach ($c in $s.ToCharArray()) {
        $code = [int]$c
        if     ($code -gt 127)  { $null = $sb.Append('\u{0:x4}' -f $code) }
        elseif ($c -eq '"')     { $null = $sb.Append('\"') }
        elseif ($c -eq '\')     { $null = $sb.Append('\\') }
        elseif ($c -eq "`n")    { $null = $sb.Append('\n') }
        elseif ($c -eq "`r")    { $null = $sb.Append('\r') }
        elseif ($c -eq "`t")    { $null = $sb.Append('\t') }
        else                    { $null = $sb.Append($c) }
    }
    return $sb.ToString()
}

# ── Load .env ──────────────────────────────────────────────────────────────────
$envPath = Join-Path $PSScriptRoot "..\.env"
Get-Content $envPath | Where-Object { $_ -match '^[A-Z_]' } | ForEach-Object {
    $parts = $_ -split '=', 2
    if ($parts.Length -eq 2) {
        [System.Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1].Trim())
    }
}
$notionKey = [System.Environment]::GetEnvironmentVariable('NOTION_API_KEY')
$n8nBase   = [System.Environment]::GetEnvironmentVariable('N8N_BASE_URL')
$n8nKey    = [System.Environment]::GetEnvironmentVariable('N8N_API_KEY')

# ── Fetch n8n workflow (raw JSON string) ───────────────────────────────────────
Write-Host 'Fetching n8n workflow...' -ForegroundColor Cyan
$wfResp  = Invoke-WebRequest -Uri "$n8nBase/api/v1/workflows/MJttlN1cxcx0nAZ8" `
               -Headers @{ 'X-N8N-API-KEY' = $n8nKey } -UseBasicParsing
$rawJson = $wfResp.Content
Write-Host "  Workflow JSON : $($rawJson.Length) chars" -ForegroundColor Gray

# ── Escape workflow JSON + chunk into 1900-char Notion rich_text parts ─────────
$escaped = ConvertTo-JsonString $rawJson
$chunks  = @()
$pos     = 0
while ($pos -lt $escaped.Length) {
    $len = [Math]::Min(1900, $escaped.Length - $pos)
    # Never split between \ and the next char (would break \X escape sequence)
    while ($len -lt ($escaped.Length - $pos) -and $escaped[$pos + $len - 1] -eq '\') {
        $len++
    }
    $chunks += $escaped.Substring($pos, $len)
    $pos    += $len
}
Write-Host "  Chunks Notion : $($chunks.Count)" -ForegroundColor Gray

# rich_text array for code block
$rtParts      = $chunks | ForEach-Object { '{"type":"text","text":{"content":"' + $_ + '"}}' }
$codeRichText = $rtParts -join ','

# ── Build Notion blocks (all French text pre-encoded as \uXXXX) ────────────────

# Paragraph + headings + lists (before code block)
$b1 = @'
[
  {"object":"block","type":"paragraph","paragraph":{"rich_text":[
    {"type":"text","text":{"content":"Cr\u00e9\u00e9 par "}},
    {"type":"text","text":{"content":"automationact.com","link":{"url":"https://www.automationact.com/"}}}
  ]}},
  {"object":"block","type":"heading_2","heading_2":{"rich_text":[
    {"type":"text","text":{"content":"\ud83c\udfaf Vue d\u2019ensemble"}}
  ]}},
  {"object":"block","type":"paragraph","paragraph":{"rich_text":[
    {"type":"text","text":{"content":"Un agent qui surveille vos campagnes Google Ads en continu. Pipeline en 4 phases : Collect (extraction automatique via Google Ads API et GA4, quotidiennement), Analyze (d\u00e9tection d\u2019anomalies statistiques sur CPA, CTR, CVR, IS Lost vs p\u00e9riodes pr\u00e9c\u00e9dentes), Interpret (chaque signal = observation structur\u00e9e avec hypoth\u00e8se business), Recommend (recommandations prioris\u00e9es par campagne et urgence). Chaque lundi matin : synth\u00e8se automatique avec les 3 actions prioritaires."}}
  ]}},
  {"object":"block","type":"heading_2","heading_2":{"rich_text":[
    {"type":"text","text":{"content":"\ud83d\udca1 Cas d\u2019usage"}}
  ]}},
  {"object":"block","type":"bulleted_list_item","bulleted_list_item":{"rich_text":[
    {"type":"text","text":{"content":"Vous g\u00e9rez plusieurs comptes et l\u2019analyse hebdomadaire prend plusieurs heures"}}
  ]}},
  {"object":"block","type":"bulleted_list_item","bulleted_list_item":{"rich_text":[
    {"type":"text","text":{"content":"Vous voulez d\u00e9tecter les anomalies (CPA en hausse, CTR en chute) avant qu\u2019elles co\u00fbtent cher"}}
  ]}},
  {"object":"block","type":"bulleted_list_item","bulleted_list_item":{"rich_text":[
    {"type":"text","text":{"content":"Vous voulez un rapport actionnable chaque lundi sans ouvrir Google Ads"}}
  ]}},
  {"object":"block","type":"heading_2","heading_2":{"rich_text":[
    {"type":"text","text":{"content":"\u2699\ufe0f Pr\u00e9requis"}}
  ]}},
  {"object":"block","type":"bulleted_list_item","bulleted_list_item":{"rich_text":[
    {"type":"text","text":{"content":"Compte n8n (self-hosted ou cloud)"}}
  ]}},
  {"object":"block","type":"bulleted_list_item","bulleted_list_item":{"rich_text":[
    {"type":"text","text":{"content":"Google Ads : Developer Token approuv\u00e9, OAuth2 configur\u00e9 (scope ads.readonly)"}}
  ]}},
  {"object":"block","type":"bulleted_list_item","bulleted_list_item":{"rich_text":[
    {"type":"text","text":{"content":"Google Analytics 4 : propri\u00e9t\u00e9 GA4 avec conversions track\u00e9es"}}
  ]}},
  {"object":"block","type":"bulleted_list_item","bulleted_list_item":{"rich_text":[
    {"type":"text","text":{"content":"Bot Telegram + chat ID (pour recevoir la synth\u00e8se hebdo)"}}
  ]}},
  {"object":"block","type":"bulleted_list_item","bulleted_list_item":{"rich_text":[
    {"type":"text","text":{"content":"Cl\u00e9 API Claude (Anthropic) ou OpenAI pour l\u2019analyse LLM"}}
  ]}},
  {"object":"block","type":"heading_2","heading_2":{"rich_text":[
    {"type":"text","text":{"content":"\ud83d\ude80 Installation"}}
  ]}},
  {"object":"block","type":"numbered_list_item","numbered_list_item":{"rich_text":[
    {"type":"text","text":{"content":"Copiez le JSON ci-dessous"}}
  ]}},
  {"object":"block","type":"numbered_list_item","numbered_list_item":{"rich_text":[
    {"type":"text","text":{"content":"Dans n8n : menu \u2261 > Workflows > Import from JSON \u2192 collez le JSON"}}
  ]}},
  {"object":"block","type":"numbered_list_item","numbered_list_item":{"rich_text":[
    {"type":"text","text":{"content":"Configurez les credentials (voir table ci-dessous) puis activez le workflow"}}
  ]}},
'@

# Code block (dynamic)
$b2 = '  {"object":"block","type":"code","code":{"language":"json","rich_text":[' + $codeRichText + ']}},'

# Config table + troubleshooting + about
$b3 = @'
  {"object":"block","type":"heading_2","heading_2":{"rich_text":[
    {"type":"text","text":{"content":"\u00c9tape 3 : adapter \u00e0 votre compte"}}
  ]}},
  {"object":"block","type":"table","table":{"table_width":3,"has_column_header":true,"has_row_header":false,"children":[
    {"object":"block","type":"table_row","table_row":{"cells":[
      [{"type":"text","text":{"content":"Quoi"}}],
      [{"type":"text","text":{"content":"O\u00f9 dans n8n"}}],
      [{"type":"text","text":{"content":"Modification"}}]
    ]}},
    {"object":"block","type":"table_row","table_row":{"cells":[
      [{"type":"text","text":{"content":"Customer ID Google Ads"}}],
      [{"type":"text","text":{"content":"Nodes HTTP Google Ads (2 nodes)"}}],
      [{"type":"text","text":{"content":"Remplacez 3300525230 par votre customer ID (sans tirets)"}}]
    ]}},
    {"object":"block","type":"table_row","table_row":{"cells":[
      [{"type":"text","text":{"content":"Developer Token"}}],
      [{"type":"text","text":{"content":"Header des nodes HTTP Google Ads"}}],
      [{"type":"text","text":{"content":"Remplacez par votre Developer Token"}}]
    ]}},
    {"object":"block","type":"table_row","table_row":{"cells":[
      [{"type":"text","text":{"content":"Seuils d\u2019alerte"}}],
      [{"type":"text","text":{"content":"Node \u00ab Apply Detection Rules \u00bb"}}],
      [{"type":"text","text":{"content":"CPA +20%, CTR -15%, CVR -10%, IS Lost Rank >30%, IS Lost Budget >25% - ajustez selon votre compte"}}]
    ]}},
    {"object":"block","type":"table_row","table_row":{"cells":[
      [{"type":"text","text":{"content":"Telegram chat ID"}}],
      [{"type":"text","text":{"content":"Node \u00ab Send Telegram \u00bb"}}],
      [{"type":"text","text":{"content":"Remplacez par votre chat ID"}}]
    ]}},
    {"object":"block","type":"table_row","table_row":{"cells":[
      [{"type":"text","text":{"content":"Credentials Google OAuth2"}}],
      [{"type":"text","text":{"content":"2 nodes HTTP Google Ads + node GA4"}}],
      [{"type":"text","text":{"content":"Configurez dans n8n > Credentials > Google Ads OAuth2"}}]
    ]}},
    {"object":"block","type":"table_row","table_row":{"cells":[
      [{"type":"text","text":{"content":"Credential LLM"}}],
      [{"type":"text","text":{"content":"Node Anthropic ou OpenAI"}}],
      [{"type":"text","text":{"content":"Ajoutez votre cl\u00e9 API dans n8n > Credentials"}}]
    ]}},
    {"object":"block","type":"table_row","table_row":{"cells":[
      [{"type":"text","text":{"content":"Credential Telegram"}}],
      [{"type":"text","text":{"content":"Node Send Telegram"}}],
      [{"type":"text","text":{"content":"Configurez votre bot Telegram dans n8n > Credentials"}}]
    ]}},
    {"object":"block","type":"table_row","table_row":{"cells":[
      [{"type":"text","text":{"content":"P\u00e9riodes d\u2019analyse"}}],
      [{"type":"text","text":{"content":"Node \u00ab Calculate Date Ranges \u00bb"}}],
      [{"type":"text","text":{"content":"R\u00e9cente : J-14/J-1, R\u00e9f\u00e9rence : J-28/J-15 - modifiable"}}]
    ]}},
    {"object":"block","type":"table_row","table_row":{"cells":[
      [{"type":"text","text":{"content":"Schedule"}}],
      [{"type":"text","text":{"content":"Node Schedule Trigger"}}],
      [{"type":"text","text":{"content":"Tous les lundis matin par d\u00e9faut - ajustez la fr\u00e9quence"}}]
    ]}}
  ]}},
  {"object":"block","type":"heading_2","heading_2":{"rich_text":[
    {"type":"text","text":{"content":"\ud83d\udd27 Troubleshooting"}}
  ]}},
  {"object":"block","type":"bulleted_list_item","bulleted_list_item":{"rich_text":[
    {"type":"text","text":{"content":"Erreur auth Google Ads : v\u00e9rifiez que le Developer Token est approuv\u00e9 et que le scope OAuth inclut ads.readonly"}}
  ]}},
  {"object":"block","type":"bulleted_list_item","bulleted_list_item":{"rich_text":[
    {"type":"text","text":{"content":"Rate limit API Google Ads : l\u2019extraction porte sur J-28/J-1. Si beaucoup de campagnes, fractionnez les p\u00e9riodes."}}
  ]}},
  {"object":"block","type":"bulleted_list_item","bulleted_list_item":{"rich_text":[
    {"type":"text","text":{"content":"Pas de message Telegram : v\u00e9rifiez le chat ID et que le bot est admin du groupe"}}
  ]}},
  {"object":"block","type":"heading_2","heading_2":{"rich_text":[
    {"type":"text","text":{"content":"\u2139\ufe0f \u00c0 propos"}}
  ]}},
  {"object":"block","type":"paragraph","paragraph":{"rich_text":[
    {"type":"text","text":{"content":"Template cr\u00e9\u00e9 par Aliou BA - "}},
    {"type":"text","text":{"content":"automationact.com","link":{"url":"https://www.automationact.com/"}}}
  ]}}
]
'@

$blocksJson = $b1 + "`n" + $b2 + "`n" + $b3

# ── Build full Notion payload ──────────────────────────────────────────────────
$parentId = '31a8e6c9f9d480db9fe0f78f70f9fab5'
$title    = 'Google Ads Anomaly Detector - Workflow n8n'

$payload = '{"parent":{"page_id":"' + $parentId + '"},' +
           '"icon":{"emoji":"\ud83d\udcca"},' +
           '"properties":{"title":[{"type":"text","text":{"content":"' + $title + '"}}]},' +
           '"children":' + $blocksJson + '}'

# ── Write payload UTF-8 NoBOM to temp file ─────────────────────────────────────
$tmpFile = Join-Path $PSScriptRoot "..\.tmp\notion_workflow_share_payload.json"
[System.IO.File]::WriteAllText($tmpFile, $payload, (New-Object System.Text.UTF8Encoding $false))
Write-Host "Payload : $($payload.Length) chars" -ForegroundColor Gray

# ── POST to Notion API ─────────────────────────────────────────────────────────
$headers = @{
    'Authorization'  = "Bearer $notionKey"
    'Notion-Version' = '2022-06-28'
    'Content-Type'   = 'application/json; charset=utf-8'
}
$bytes = [System.IO.File]::ReadAllBytes($tmpFile)

try {
    $response = Invoke-RestMethod -Method POST `
        -Uri 'https://api.notion.com/v1/pages' `
        -Headers $headers `
        -Body $bytes `
        -ErrorAction Stop

    $cleanId = $response.id -replace '-', ''
    $pageUrl = "https://www.notion.so/$cleanId"

    Write-Host "`nPage creee !" -ForegroundColor Green
    Write-Host "  ID  : $($response.id)" -ForegroundColor Gray
    Write-Host "  URL : $pageUrl" -ForegroundColor Cyan

} catch {
    $errBody = $_.ErrorDetails.Message
    Write-Error "Echec Notion API : $($_.Exception.Message)`n$errBody"
    exit 1
}
