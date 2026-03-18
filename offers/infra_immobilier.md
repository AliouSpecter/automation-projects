# Infra — Agences immobilières

## Objectif
Capter et qualifier les leads entrants 24/7, les attribuer automatiquement aux agents, et ne jamais laisser un prospect sans réponse dans les 5 premières minutes.

## Schéma général

```
[Lead entrant]
    │
    ├── Formulaire portail (SeLoger, LBC, PAP) → parsing email → trigger WhatsApp
    ├── Formulaire site / ads → redirection WhatsApp
    └── QR code vitrine / flyer → WhatsApp
    │
    ▼
[Bot de qualification]
    ├── Budget
    ├── Zone / type de bien
    ├── Délai projet
    └── Financement (déjà approuvé ?)
    │
    ▼
[Scoring automatique]
    ├── Chaud → attribution agent immédiate + alerte
    ├── Tiède → envoi biens correspondants (carrousel / PDF) + RDV visite
    └── Froid → nurture automatisé (1 message / 2 semaines, 90-180 jours)
    │
    ▼
[Suivi actif — leads chauds/tièdes]
    ├── Envoi automatique de biens correspondants
    ├── Prise de RDV visite + rappels J-1 et J-0
    └── Récap visite envoyé au prospect + note pour l'agent
    │
    ▼
[Couche IA / RAG]
    ├── Assistant "conseiller immo" : fiches biens, FAQ achat/loc, docs juridiques
    ├── Résumé des besoins acheteur → généré automatiquement pour l'agent
    └── Suggestions de biens similaires selon historique de conversation
    │
    ▼
[Back-office]
    ├── Pipeline leads : source, score, statut, RDV planifiés
    └── Sync CRM (HubSpot, Pipedrive) ou Google Sheets
```

## Stack technique
- WhatsApp Business API (via 360dialog ou Twilio)
- n8n : orchestration + parsing emails portails
- Google Sheets / HubSpot / Pipedrive : CRM leads
- Google Calendar : gestion visites
- Claude (RAG) : assistant conseiller + résumés

## Note technique
Les leads des portails (SeLoger, LBC, PAP) arrivent par **email**, pas par formulaire.
Il faut un parser email → extraction données → trigger WhatsApp.
Prévoir dès l'intégration (Gmail ou Outlook en source).

## ROI principal
- Réponse lead < 5 minutes (vs 24-48h en moyen en agence)
- Qualification automatique → agents contactent uniquement les leads chauds
- Nurture long terme → récupère les leads "pas encore prêts" à 3-6 mois
- Réduction charge admin : récaps visites, relances, RDV gérés automatiquement
