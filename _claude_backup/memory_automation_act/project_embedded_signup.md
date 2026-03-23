---
name: Embedded Signup Setup — Automation Act
description: État d'avancement du setup WhatsApp Embedded Signup SaaS pour Automation Act
type: project
---

## Ce qui a été fait (2026-03-22)

### ✅ Étape 1 — System User Token
- System user "Aliou" (Admin) dans Business Manager Automationact
- Token généré avec 5 permissions : business_management, manage_app_solution, whatsapp_business_manage_events, whatsapp_business_management, whatsapp_business_messaging
- Stocké dans `.env` → `META_SYSTEM_USER_TOKEN`
- Token renseigné dans l'Embedded Signup Builder Meta

### ✅ Étape 2 — Webhook
- Workflow n8n créé : "Meta Webhook Verify" (ID: 5LW6mfCytY8Y64xO)
- URL : `https://n8n.srv1105514.hstgr.cloud/webhook/meta-whatsapp-verify`
- Verify token : `automationact_meta_2026` (dans `.env` → `META_WEBHOOK_VERIFY_TOKEN`)
- Webhook vérifié et validé par Meta (WhatsApp Business Account)

### ✅ Étape 3 — Bouton Embedded Signup
- Code JS prêt avec SDK v25.0
- **Retiré des pages de production** (partagées via campagnes)
- À remettre quand prêt : page écoles (ID 1415) après "Voir comment ça marche", page e-commerce (ID 1487) après "Installer cette automatisation"
- Page de test active : `https://www.automationact.com/test-whatsapp-connect/` (page ID 1522)

### ✅ Étape 4 — Callback backend (WordPress plugin)
- Plugin : `wp-plugin-whatsapp-callback/automationact-whatsapp.php`
- Endpoint POST : `/wp-json/automationact/v1/whatsapp-callback`
- Endpoint GET (admin) : `/wp-json/automationact/v1/whatsapp-clients`
- Flow : code OAuth → access token → WABA ID (via debug_token) → Phone Number ID → stockage wp_options

### ✅ Étape 5 — Test bout en bout validé
- Nouvelle config créée : "AA WhatsApp Only" (ID: `2091509874968206`)
  - Permissions : whatsapp_business_management + whatsapp_business_messaging uniquement
  - Assets : WhatsApp accounts uniquement
  - Produits : WhatsApp Cloud API uniquement
- Ancien config (ID: 1584400679282366) avait des permissions ads bloquées → abandonné
- Test réussi avec Business Manager "BIEN FAIT"
- Données stockées : WABA ID `1255667556632695`, Phone Number ID `1103958762791309`

## Clés importantes (.env)
- META_APP_ID=2093631011414930
- META_APP_SECRET=c22c1b441a7661f03b1fa2193c41805a
- META_CONFIG_ID=2091509874968206 (nouvelle config propre)
- META_SYSTEM_USER_TOKEN=voir .env
- META_WEBHOOK_VERIFY_TOKEN=automationact_meta_2026

## Next steps
1. Envoyer un message test depuis WABA ID 1255667556632695
2. Remettre le bouton sur les 2 pages de production (résoudre pb Elementor/LiteSpeed)
3. Abonner l'app aux webhooks WABA client
4. Supprimer la page de test une fois validé en production
