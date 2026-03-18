# Tasks — Automation Act

Mis à jour automatiquement par Claude Code apres chaque action complétée.
Statuts : `[ ]` à faire | `[~]` en cours | `[x]` terminé

---

## Récurrent quotidien

- [~] **Poster sur LinkedIn** — Performance Intelligence Agent programmé à 9h00 (tâche Windows : AutomationAct_Post_PIA)

---

## A faire

## Prospection & Lead Generation (priorité)

### Création offre par LP adaptée avant prospection
- [ ] Créer offre adaptée pour Immobilier (offre automatisation gestion locative)
- [ ] Créer offre adaptée pour cabinets médicaux / dentaires (offre automatisation planning patient)
- [~] Créer offre adaptée pour écoles (offre automatisation acquisition et qualification)
  - [x] LP écoles/centres de formation créée — post WP ID 1415, déployée sur automationact.com (2026-03-14)
  - [x] Hero : fenêtre Mac WhatsApp, conversation animée en loop, 7 contacts (Arthur, Benoît, Salma, Aliou, Camille, Noah, Céline) (2026-03-14)
  - [ ] Corrections visuelles en cours (nouveau chat)
- [ ] Créer offre adaptée pour ressources humaines (offre automatisation recrutement)
- [ ] Créer offre adaptée pour commerciaux (offre automatisation pipeline commercial)

### Finaliser les 3 systemes de lead gen
- [x] Scraping signaux d'achat (France Travail → Notion) — une offre par entreprise, best signal scoring déployé (2026-03-13)
  - [x] Enrichissement emails (workflow "Email Enrichment - Hunter.io" cMtvM3lw671UBdNMvi4nO) — testé et validé end-to-end (2026-03-14)
    - [x] Phase 1 : SerpApi → domaine → Notion PATCH — flow complet fonctionnel (2026-03-13)
    - [x] Phase 2 : Hunter domain search → email → Notion — déployé et validé (2026-03-14)
      - [x] Colonne "Enrichissement email" (select: Enrichir/Enrichi/Exclu/Email non trouvé) ajoutée dans Notion DB prospects
      - [x] Branche B : Get Prospects A Enrichir (Domaine rempli + Enrichir) → Extract Domain → Hunter → Pick Best Email → Update Notion
      - [x] Batching Hunter : 5 req/batch, 1000ms délai — rate limit résolu
      - [x] Pick Best Email : $input.all() + $('Extract Domain').all()[i] — 50 items traités
      - [x] Résultat test : 17/50 emails trouvés (34%), 33 non trouvés (petites structures/asso)
  - [~] Base prospects écoles/formation en cours de construction (offre infra_ecoles_formation.md)
    - [x] Termes testés : "responsable admissions" (bruit hospitalier), "conseiller formation" (trop large)
    - [x] Tester : "directeur centre de formation", "responsable développement formation", "directeur école" — testé (2026-03-16)
    - [x] Termes à tester : "Chargé des admissions", "Responsable pédagogique" — à lancer
 
- [x] LinkedIn outreach automatisé (Waalaxy) — campagne active, webhook n8n → Notion déployé
  - [x] Sélectionner les meilleurs prospects — 122 contacts qualifiés (directeur/responsable admissions, France, profil complet) (2026-03-17)
  - [x] Mettre à jour le message Touch 3 (2026-03-17)
  - [x] Optimiser profil LinkedIn avant lancement (2026-03-17)
  - [x] Envoyer la campagne Waalaxy — 122 contacts, séquence "Formation et écoles", invitation sans note + 2 messages (2026-03-17)

- [x] Lead magnet and LinkedIn
- [x] Finaliser profil LinkedIn orienté accompagnement automatisation — titre, à propos, services, Featured link automationact.com ajouté (2026-03-16)
- [ ] Poster au moins une fois par jour sur LinkedIn
- [ ] Proposer bouton de prise de rendez-vous direct sur profil

### Infrastructure

- [ ] Sync TASKS.md vers Notion (`tools/sync_tasks_notion.ps1`)
- [ ] Créer les SOPs dans `workflows/` pour chaque automation construite

### n8n - Workflows à construire

- [x] Construire le workflow n8n pour **Google Ads Test Engine** (post WP #1389)
- [ ] Ajouter GA4 comme source de données dans le workflow Google Ads Test Engine
- [ ] Construire le workflow n8n pour **Google Ads Performance Intelligence Agent** (post WP #1396)
- [ ] Construire le workflow n8n pour **Website Intent Lead Detection** (post WP #1404)

### Workflow à corriger

- [x] Tester le flow complet Claude Code → n8n webhook → LinkedIn (post + image)
- Corriger le workflow Transcript YouTube. Les commandes q/ and /check ne semblent pas fonctionnés.

---

## Réalisations

<!-- Les tâches terminées s'ajoutent ici, organisées par date -->

### 2026-03-17

- [x] Campagne Waalaxy "Formation et écoles" lancée — 122 contacts qualifiés (directeur/responsable admissions, France), séquence invitation sans note + 2 messages, webhook n8n actif
- [x] Email mis à jour vers adresse pro sur Waalaxy et Calendly (Google login) — Tally en attente code confirmation

### 2026-03-16

- [x] Post LinkedIn publié — Google Ads Test Engine (repost vidéo) — workflow n8n en action + brief Telegram, métriques détaillées dans le texte, lien automationact.com/google-ads-test-engine/ en commentaire

### 2026-03-14

- [x] Enrichissement emails Phase 2 déployé — workflow "Email Enrichment - Hunter.io" (cMtvM3lw671UBdNMvi4nO) — branche B : Notion (Enrichir) → Extract Domain → Hunter domain-search → Pick Best Email → Notion (Enrichi / Email non trouvé)
- [x] Colonne "Enrichissement email" (select 4 valeurs) ajoutée dans Notion DB prospects via API
- [x] Batching Hunter configuré (5 req/1s) — rate limit 403 résolu
- [x] Test validé : 17/50 emails enrichis (34%), aucune erreur rate limit

### 2026-03-10 (suite)

- [x] Système 3 Waalaxy — compte créé, plan PRO (22,80 $/mois), campagne "Invitation + 2 Messages" configurée, 966 contacts RH/DRH importés
- [x] Messages Waalaxy rédigés — Touch 1 (sans note), Touch 2 DM ciblé, Touch 3 audit gratuit (lien Tally https://tally.so/r/Y5OJZN)
- [x] Déployé n8n workflow "Waalaxy Reply - Notion CRM" (ID: FPsaLa0mBS4QDel8) — webhook waalaxy-reply → crée fiche Notion avec Statut "Réponse reçue" — testé et validé end-to-end
- [x] Déployé n8n workflow "Waalaxy Message Envoye - Notion CRM" (ID: mdyG6Cf5lPwxJKYl) — webhook waalaxy-message-sent → upsert Notion avec Statut "En attente de réponse" (webhook non disponible sur plan PRO Waalaxy — désactivé)
- [x] Ajouté option "En attente de réponse" au select Statut dans Notion CRM Prospection
- [x] Webhook "réponse" configuré dans campagne Waalaxy → URL : https://n8n.srv1105514.hstgr.cloud/webhook/waalaxy-reply
- [x] Optimiser profil LinkedIn avant lancement campagne — titre, services, Featured link, description "About" orientée bénéfices (2026-03-17)
- [ ] Lancer campagne Waalaxy (après profil LinkedIn)

### 2026-03-10

- [x] Déployé workflow n8n "Audit Gratuit - Tally -> Notion + Email" (ID: KNPryxtLO80ytQKb) — Tally webhook → Extract Fields (matching par key) → Notion CRM (colonnes Entreprise, Nom, Email, Domaine, Budget, Notes, Statut, Source, Date signal)
- [x] Créé colonnes Notion "Nom" et "Budget" dans la DB CRM Prospection
- [x] Connecté formulaire Tally (https://tally.so/r/Y5OJZN) au webhook n8n + redirection Calendly

### 2026-03-09

- [x] Posté sur LinkedIn — "Google Ads Performance Intelligence Agent" (type Résultat concret) — accents corrects, sans section Avant/Après répétitive
- [x] Corrigé workflow n8n rGXpgRiuqFY8FuQ1 — LinkedIn v2 API + fix convertToFile sourceProperty
- [x] Corrigé encodage accents dans `post_linkedin_n8n.ps1` — fonction `ConvertTo-JsonString` : non-ASCII → `\uXXXX` en JSON
- [x] Supprimé automationact.com du footer image — mis à jour SKILL.md linkedin-post
- [x] Créé intégration Notion + clé API — ajouté NOTION_API_KEY et NOTION_PARENT_PAGE_ID dans .env
- [x] Créé `tools/post_notion_brief.ps1` — publie une page dans la DB Notion "Automation Act" avec contenu structuré (tables, callouts, couleurs)
- [x] Publié Weekly Brief Google Ads Test Engine (semaine 2026-03-09) sur Notion — page ID : 31e8e6c9-f9d4-81e7-ad47-c55c58afabdd
- [x] Créé skill `/linkedin-carousel` — génère un carrousel PDF 6 slides (1080x1350) via HTML + Edge headless
- [x] Créé `tools/generate_carousel_pdf.ps1` — HTML → PDF via Edge `--headless=old --print-to-pdf`
- [x] Généré carrousel PDF brief semaine 2026-03-09 — `.tmp/carousel-brief-2026-03-09.pdf` (149 KB) — à tester publication manuelle LinkedIn
- [x] Créé page Notion "Planning - Automation Act - Semaine du 2026-03-09" — tables tâches + posts LinkedIn — ID : 31e8e6c9-f9d4-81db-b3b4-e75443637a3d
- [x] Déployé **Google Ads Test Engine V2** sur n8n (ID: MJttlN1cxcx0nAZ8) — 10 nodes, détection anomalies/opportunités par comparaison J-14/J-1 vs J-28/J-15, output Telegram
- [x] Mis à jour WP post #1389 (google-ads-test-engine) — ajouté section B (Signaux détectés) + section C (Weekly Exec Summary) + tableau Règles de détection

### 2026-03-08

- [x] Refactorisé pipeline LinkedIn Claude Code : image via `get_linkedin_image.ps1` + publication via `post_linkedin_n8n.ps1` → n8n `rGXpgRiuqFY8FuQ1` (contourne firewall local)
- [x] Créé n8n workflow "LinkedIn Publish via Webhook" (ID: rGXpgRiuqFY8FuQ1) — reçoit text+imageBase64+token, publie côté serveur n8n
- [x] Simplifié n8n workflow OIhz9pRyEJPyuIUz — réduit à relay Gemini pur (input: prompt → output: imageBase64)
- [x] Mis à jour skill `/linkedin-post` v1.2 — boucle corrections post → validation tableau image → génération Gemini → preview → publication
- [x] Désactivé workflow yKXwLxH8Oi66oNSk (LinkedIn Image Generation via Gemini) — fusionné dans OIhz9pRyEJPyuIUz

### 2026-03-07

- [x] Créé page WP #1404 — Website Intent Lead Detection (format classique, 5 sections, image à la une J+0)
- [x] Construit workflow n8n "Google Ads Test Engine" (ID: P39Yp8V6aeW5Xed1) — Schedule → Raw Metrics (Sheets) → Detect Anomalies → Claude Hypotheses → ICE Score → Append to Backlog (Sheets) → Brief → Gmail
- [x] Configuré Google Sheets (ID: 1WYPPI-oYhoxI7-q7Gy2HJr8-uA6KAxqfbafFdSUxAZc) — onglet "Raw Metrics" (12 campagnes simulation) + onglet "Backlog" (formatage coloré : vert/orange/rouge selon score ICE)

### 2026-03-06

- [x] Posté sur LinkedIn — "Backlog d'optimisation automatisé" (type Architecture) — via workflow n8n, image Google Ads API → GA4 → Notion → n8n
- [x] Corrigé accents node "Build Image Prompt" (n8n workflow LinkedIn Post Aliou_V2_LATEST) — déploiement via API n8n PUT + activation
- [x] Corrigé accents dans tools/generate_image.ps1 — HTML entities pour tous les templates
- [x] Créé workflow n8n "LinkedIn Post via Webhook" (ID: OIhz9pRyEJPyuIUz) — webhook /webhook/linkedin-post → convert binary → LinkedIn post

### 2026-03-05

- [x] Posté sur LinkedIn — workflow vocal → post → image → publication (avec vidéo de démo)
- [x] Corrigé accents post WP #1396 — bug PS5 ConvertTo-Json + méthode post_content (bypass Elementor HTML widget)

### 2026-03-04

- [x] Publié post WP #1389 — Google Ads Test Engine
- [x] Publié post WP #1376 — Publier sur LinkedIn tous les jours
- [x] Publié post WP #1396 — Google Ads Performance Intelligence Agent
- [x] Créé TASKS.md et mis en place le suivi de tâches
