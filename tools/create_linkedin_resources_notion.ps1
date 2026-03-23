# tools/create_linkedin_resources_notion.ps1
# Crée une page Notion avec les ressources Claude Growth Marketing (Austin Lau)
# à partager aux personnes qui commentent "GROWTH" sur LinkedIn.
#
# Usage:
#   powershell.exe -ExecutionPolicy Bypass -File tools/create_linkedin_resources_notion.ps1

$ErrorActionPreference = "Stop"

# ── Load .env ──────────────────────────────────────────────────────────────────
$envPath = Join-Path $PSScriptRoot "..\.env"
Get-Content $envPath | Where-Object { $_ -match '^[A-Z_]' } | ForEach-Object {
    $parts = $_ -split '=', 2
    if ($parts.Length -eq 2) {
        [System.Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1].Trim())
    }
}
$notionKey = [System.Environment]::GetEnvironmentVariable('NOTION_API_KEY')

# ── Notion parent page ID (même répertoire que les autres pages partagées) ─────
$parentId = '31a8e6c9f9d480db9fe0f78f70f9fab5'
$title    = 'Ressources - Claude Growth Marketing (Austin Lau / Anthropic)'

# ── Blocks Notion ──────────────────────────────────────────────────────────────
$blocksJson = @'
[
  {"object":"block","type":"paragraph","paragraph":{"rich_text":[
    {"type":"text","text":{"content":"Ressources partag\u00e9es suite au post LinkedIn sur les workflows Claude d\u2019Austin Lau (Anthropic). Une seule personne = l\u2019output d\u2019une \u00e9quipe marketing enti\u00e8re."}}
  ]}},

  {"object":"block","type":"divider","divider":{}},

  {"object":"block","type":"heading_2","heading_2":{"rich_text":[
    {"type":"text","text":{"content":"\ud83d\udcda 1. Workflow complet d\u2019Austin Lau \u2014 Article officiel Anthropic"}}
  ]}},
  {"object":"block","type":"paragraph","paragraph":{"rich_text":[
    {"type":"text","text":{"content":"L\u2019article source publi\u00e9 par Anthropic. D\u00e9taille les 2 workflows principaux : g\u00e9n\u00e9ration de RSA Google Ads (slash command /rsa + 2 sub-agents) et plugin Figma pour les cr\u00e9atifs. R\u00e9sultat : 30 min \u2192 30 secondes par annonce."}}
  ]}},
  {"object":"block","type":"paragraph","paragraph":{"rich_text":[
    {"type":"text","text":{"content":"\ud83d\udd17 ","annotations":{}},
    "type":"text"},
    {"type":"text","text":{"content":"How Anthropic uses Claude in Marketing","link":{"url":"https://claude.ai/blog/how-anthropic-uses-claude-marketing"}}}
  ]}},

  {"object":"block","type":"divider","divider":{}},

  {"object":"block","type":"heading_2","heading_2":{"rich_text":[
    {"type":"text","text":{"content":"\ud83d\udee0\ufe0f 2. Comment construire chaque syst\u00e8me \u2014 Guide \u00e9tape par \u00e9tape"}}
  ]}},
  {"object":"block","type":"paragraph","paragraph":{"rich_text":[
    {"type":"text","text":{"content":"Article d\u00e9taill\u00e9 sur l\u2019impl\u00e9mentation technique : structure des sub-agents, commandes slash, export CSV pour Google Ads. Id\u00e9al pour r\u00e9pliquer le syst\u00e8me."}}
  ]}},
  {"object":"block","type":"paragraph","paragraph":{"rich_text":[
    {"type":"text","text":{"content":"\ud83d\udd17 "},
    "type":"text"},
    {"type":"text","text":{"content":"How Anthropic cut ad creation from 30min to 30sec","link":{"url":"https://peerlist.io/saxenashikhil/articles/how-anthropics-growth-marketing-team-cut-ad-creation-time-fr"}}}
  ]}},

  {"object":"block","type":"divider","divider":{}},

  {"object":"block","type":"heading_2","heading_2":{"rich_text":[
    {"type":"text","text":{"content":"\ud83e\udde9 3. Templates sub-agents (headlines, descriptions, analyse)"}}
  ]}},
  {"object":"block","type":"paragraph","paragraph":{"rich_text":[
    {"type":"text","text":{"content":"Librairie open-source de 160+ skills marketing en markdown. Couvre paid ads, SEO, content, email. Compatible Claude Code, Cursor et OpenClaw. Copy-paste ready \u2014 adapte directement \u00e0 ton contexte projet."}}
  ]}},
  {"object":"block","type":"paragraph","paragraph":{"rich_text":[
    {"type":"text","text":{"content":"\ud83d\udd17 "},
    "type":"text"},
    {"type":"text","text":{"content":"github.com/kostja94/marketing-skills","link":{"url":"https://github.com/kostja94/marketing-skills"}}}
  ]}},

  {"object":"block","type":"divider","divider":{}},

  {"object":"block","type":"heading_2","heading_2":{"rich_text":[
    {"type":"text","text":{"content":"\ud83e\udd8f 4. Guide d\u2019adaptation OpenClaw / Claude"}}
  ]}},
  {"object":"block","type":"paragraph","paragraph":{"rich_text":[
    {"type":"text","text":{"content":"Documentation officielle des sub-agents OpenClaw + guide pratique pour monter une \u00e9quipe d\u2019agents en 15 minutes. Permet d\u2019adapter les workflows d\u2019Austin Lau dans un environnement multi-agents (OpenClaw ou Claude Code)."}}
  ]}},
  {"object":"block","type":"paragraph","paragraph":{"rich_text":[
    {"type":"text","text":{"content":"\ud83d\udd17 "},
    "type":"text"},
    {"type":"text","text":{"content":"Sub-Agents \u2014 Documentation OpenClaw","link":{"url":"https://docs.openclaw.ai/tools/subagents"}}}
  ]}},
  {"object":"block","type":"paragraph","paragraph":{"rich_text":[
    {"type":"text","text":{"content":"\ud83d\udd17 "},
    "type":"text"},
    {"type":"text","text":{"content":"Build an OpenClaw Agent Team in 15 minutes","link":{"url":"https://ai2sql.io/how-to-build-your-own-ai-agent-team-with-openclaw-in-15-minutes"}}}
  ]}},

  {"object":"block","type":"divider","divider":{}},

  {"object":"block","type":"paragraph","paragraph":{"rich_text":[
    {"type":"text","text":{"content":"Page cr\u00e9\u00e9e par "}},
    {"type":"text","text":{"content":"automationact.com","link":{"url":"https://www.automationact.com/"}}}
  ]}}
]
'@

# ── Build Notion payload ───────────────────────────────────────────────────────
$payload = '{"parent":{"page_id":"' + $parentId + '"},' +
           '"icon":{"emoji":"\ud83e\udd16"},' +
           '"properties":{"title":[{"type":"text","text":{"content":"' + $title + '"}}]},' +
           '"children":' + $blocksJson + '}'

# ── Write payload UTF-8 NoBOM to temp file ─────────────────────────────────────
$tmpDir  = Join-Path $PSScriptRoot "..\.tmp"
if (-not (Test-Path $tmpDir)) { New-Item -ItemType Directory -Path $tmpDir | Out-Null }
$tmpFile = Join-Path $tmpDir "notion_linkedin_resources_payload.json"
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
