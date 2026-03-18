# Test webhook Waalaxy → n8n → Notion
# Simule un payload Waalaxy "réponse reçue"

$webhookUrl = "https://n8n.srv1105514.hstgr.cloud/webhook/waalaxy-reply"

# Payload simulant une réponse Waalaxy
$body = @{
    firstName = "Jean"
    lastName = "Dupont"
    email = "jean.dupont@test.com"
    linkedinUrl = "https://www.linkedin.com/in/jean-dupont-test"
    message = "Bonjour, merci pour votre message. Je suis intéressé par votre offre d'audit."
    campaignName = "Campagne RH DRH Mars 2026"
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
} | ConvertTo-Json

Write-Host "=== Test Webhook Waalaxy → n8n ===" -ForegroundColor Cyan
Write-Host "URL: $webhookUrl"
Write-Host "Payload:" -ForegroundColor Yellow
Write-Host $body
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri $webhookUrl -Method POST -ContentType "application/json" -Body $body -TimeoutSec 15
    Write-Host "✅ SUCCESS - Réponse n8n:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 5
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $errorMsg = $_.Exception.Message
    Write-Host "❌ ERREUR (HTTP $statusCode): $errorMsg" -ForegroundColor Red
    
    # Lire le corps de la réponse d'erreur si disponible
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Corps de la réponse: $responseBody" -ForegroundColor Red
    }
}
