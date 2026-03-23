# Tasks — Automation Act

Mis à jour automatiquement par Claude Code apres chaque action complétée.
Statuts : `[ ]` à faire | `[~]` en cours | `[x]` terminé

---

## Récurrent quotidien

- [~] **Poster sur LinkedIn** — Performance Intelligence Agent programmé à 9h00 (tâche Windows : AutomationAct_Post_PIA)
- [~] **Corriger le workflow de relance de la campagne**

---

## A faire

## Prospection & Lead Generation (priorité)

### Création offre par LP adaptée avant prospection
<!-- Secteurs prioritaires : LinkedIn haute densité → Écoles ✓, RH, Assurance/Courtage | Email + LinkedIn → Immobilier, Médical/Dentaire, Commerciaux -->
- [x] Créer offre adaptée pour Immobilier (offre automatisation gestion locative) — LP publiée : https://www.automationact.com/automatisation-agences-immobilieres/
- [ ] Créer offre adaptée pour cabinets médicaux / dentaires (offre automatisation planning patient)
- [x] Créer offre adaptée pour Assurance / Courtage (réponse lead < 5 min, relance devis, rétention renouvellement)
  - [x] LP publiée — post WP ID 1498, image à la une v2 (2026-03-19)
- [x] Créer offre adaptée pour écoles (offre automatisation acquisition et qualification)
  - [x] LP écoles/centres de formation créée — post WP ID 1415, déployée sur automationact.com (2026-03-14)
  - [x] Hero : fenêtre Mac WhatsApp, conversation animée en loop, 7 contacts (Arthur, Benoît, Salma, Aliou, Camille, Noah, Céline) (2026-03-14)
  - [x] Corrections visuelles LP (2026-03-19)
- [ ] Créer offre adaptée pour ressources humaines (offre automatisation recrutement)
- [ ] Créer offre adaptée pour commerciaux (offre automatisation pipeline commercial)

### Finaliser les 3 systemes de lead gen
- [x] Scraping signaux d'achat (France Travail → Notion) — une offre par entreprise, best signal scoring déployé (2026-03-13)
  - [x] Enrichissement emails (workflow "Email Enrichment - Hunter.io" cMtvM3lw671UBdNMvi4nO) — testé et validé end-to-end (2026-03-14)
  - [x] Base prospects écoles/formation construite (offre infra_ecoles_formation.md) (2026-03-19)
    - [x] Termes testés : "responsable admissions" (bruit hospitalier), "conseiller formation" (trop large)
    - [x] Tester : "directeur centre de formation", "responsable développement formation", "directeur école" — testé (2026-03-16)
    - [x] Termes à tester : "Chargé des admissions", "Responsable pédagogique" — testé (2026-03-19)

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

- [x] Sync TASKS.md vers Notion (`tools/sync_tasks_notion.ps1`)
- [ ] Créer les SOPs dans `workflows/` pour chaque automation construite

### n8n - Workflows à construire

- [x] Construire le workflow n8n pour **Google Ads Test Engine** (post WP #1389)
- [ ] Ajouter GA4 comme source de données dans le workflow Google Ads Test Engine
- [ ] Construire le workflow n8n pour **Google Ads Performance Intelligence Agent** (post WP #1396)
- [ ] Construire le workflow n8n pour **Website Intent Lead Detection** (post WP #1404)
- [ ] Construire le workflow n8n pour **Automatisation assurance et courtage** (post WP #1498)

### Workflow à corriger

- [x] Tester le flow complet Claude Code → n8n webhook → LinkedIn (post + image)
- Corriger le workflow Transcript YouTube. Les commandes q/ and /check ne semblent pas fonctionnés.

---

## Réalisations

<!-- Les tâches terminées s'ajoutent ici, organisées par date -->
<!-- Archivé mensuellement vers Notion via tools/sync_tasks_notion.ps1 -->
<!-- Dernière archive : Réalisations archivées - Mars 2026 (2026-03-18) -->
