# Test webhook Waalaxy avec payload complet
# Simule un vrai payload avec tous les champs

$webhookUrl = "https://n8n.srv1105514.hstgr.cloud/webhook/waalaxy-reply"

# Payload complet simulant une vraie reponse Waalaxy
$testPayload = @{
    firstName = "Jean"
    lastName = "Dupont"
    companyName = "Entreprise Test SAS"
    company = "Entreprise Alternative"
    email = "jean.dupont@entreprise-test.com"
    occupation = "Directeur des Ressources Humaines"
    jobTitle = "DRH"
    profileUrl = "https://www.linkedin.com/in/jean-dupont-test"
    linkedinUrl = "https://www.linkedin.com/in/jean-dupont-alt"
    message = "Bonjour, merci pour votre message. Je suis tres interesse par votre offre d'audit gratuit."
    campaignName = "Campagne RH DRH Mars 2026"
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
} | ConvertTo-Json -Depth 5

Write-Host "=== Test Webhook Waalaxy avec payload complet ===" -ForegroundColor Cyan
Write-Host "URL: $webhookUrl"
Write-Host ""
Write-Host "Payload envoye:" -ForegroundColor Yellow
Write-Host $testPayload
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri $webhookUrl -Method POST -ContentType "application/json" -Body $testPayload -TimeoutSec 15
    Write-Host "SUCCESS - Reponse n8n:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 5
    Write-Host ""
    Write-Host "Verifie maintenant dans Notion CRM Prospection:" -ForegroundColor Cyan
    Write-Host "   - Entreprise: 'Entreprise Test SAS'" -ForegroundColor White
    Write-Host "   - Nom: 'Jean Dupont'" -ForegroundColor White
    Write-Host "   - Email: 'jean.dupont@entreprise-test.com'" -ForegroundColor White
    Write-Host "   - Notes: 'Directeur des Ressources Humaines'" -ForegroundColor White
    Write-Host "   - Lien offre: 'https://www.linkedin.com/in/jean-dupont-test'" -ForegroundColor White
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $errorMsg = $_.Exception.Message
    Write-Host "ERREUR (HTTP $statusCode): $errorMsg" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Corps de la reponse: $responseBody" -ForegroundColor Red
    }
}
