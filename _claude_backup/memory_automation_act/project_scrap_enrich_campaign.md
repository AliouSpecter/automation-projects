---
name: Workflow Scrap_Enrich_SendCampaign — état d'avancement
description: Suivi du workflow n8n de prospection (scraping FT, enrichissement, campagnes email) par secteur
type: project
---

## Workflow n8n
- **ID :** `cMtvM3lw671UBdNMvi4nO`
- **URL :** https://n8n.srv1105514.hstgr.cloud/workflow/cMtvM3lw671UBdNMvi4nO
- **Notion DB :** `31e8e6c9-f9d4-819c-a913-e50c6e43859c` (CRM Prospection - Signaux d'achat)

## Architecture — 5 sous-workflows (tous en trigger manuel)

| # | Nom | Trigger | Statut |
|---|---|---|---|
| 1 | FT Scraping | `Lancer FT Scraping` | ✅ Fonctionnel |
| 2 | Domain Scraping | `Lancer Domain Scraping` | ✅ Patché (fallback www) |
| 3 | Email Enrichissement | `When clicking 'Execute workflow'` | ✅ Fonctionnel |
| 4 | Campagne 1 — Premier contact | `Lancer Campagne 1` | ✅ Configuré Courtage |
| 5 | Campagne 2 — Relance J+3 | `Lancer Campagne 2` | ✅ Fonctionnel |

## Patches appliqués dans cette session
- Triggers manuels ajoutés sur FT Scraping, Domain Scraping, Campagne 1, Campagne 2
- Trigger Quotidien (schedule 24h) déconnecté
- Sticky notes (fond + instructions) ajoutées sur chaque workflow — listes à puces
- `Check_Domain_HTTP` patché : teste `https://domain` puis `https://www.domain` en fallback
- `Notion Query` (Campagne 1) : filtre `Secteur = Courtage` ajouté
- `Extract Contacts` (Campagne 1) : email courtage injecté

## Email Campagne 1 — Courtage (actif)
- **Objet :** "Une question sur vos leads comparateurs"
- **LP :** https://www.automationact.com/automatisation-assurance-et-courtage/
- **Angle :** 80% signe avec celui qui répond en premier · IA · pas d'abonnement mensuel

## État Notion — Secteur Courtage (au 2026-03-21)
- Total : 61 prospects
- Enrichi (email trouvé) : 25 — 41%
- Email non trouvé : 33 — 54%
- Exclu : 3 — 5%
- Contactés : 0 (campagne pas encore lancée)

## À faire avant de lancer Campagne 1 — Courtage
1. Dans Notion, passer en `Exclu` les 5 grands comptes identifiés :
   - GAN ASSURANCES (christopher.jackson@gan.fr)
   - VERSPIEREN (sletellier@verspieren.com)
   - MMA GESTION (mathis.mannone@mma.fr)
   - AXA ASSURANCES (carole.bessac@axa.fr)
   - BCA Expertise (antoine.noyer@bca.fr)
2. Lancer `Lancer Campagne 1` dans n8n
3. Vérifier dans Notion que les statuts passent bien en `Contacté`
4. Attendre J+3, puis lancer `Lancer Campagne 2`

## Ordre des secteurs planifiés
1. ✅ Écoles/Formation — campagne déjà envoyée (session précédente)
2. 🔄 Courtage — en cours (email prêt, pas encore envoyé)
3. ⬜ Immobilier
4. ⬜ Médical/Dentaire
5. ⬜ RH/PME

## Prochaine session — pour chaque nouveau secteur
1. FT Scraping : adapter `motsCles` + `secteurActivite` + `Secteur` dans Notion
2. Domain Scraping : lancer, puis vérifier domaine par domaine dans Notion → mettre `Enrichir`
3. Enrichissement : lancer Hunter
4. Campagne 1 : adapter filtre Secteur + email dans `Extract Contacts`
5. Campagne 2 : adapter filtre Secteur + Source + email de relance

**Why:** Suivi multi-secteur avec un seul workflow n8n consolidé — chaque run est manuel et séquentiel.
**How to apply:** Charger ce fichier en début de session pour reprendre exactement là où on s'est arrêté.
