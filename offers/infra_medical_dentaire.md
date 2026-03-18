# Infra — Cabinets médicaux & dentaires

## Objectif
Réduire le taux de no-show, automatiser la prise de RDV et libérer le secrétariat des tâches répétitives.

## Schéma général

```
[Patient]
    │
    ▼
[WhatsApp — point d'entrée unique]
    │ (lien sur Google Business / site / signature mail / SMS)
    │
    ▼
[Bot RDV]
    ├── Motif → durée → praticien → créneau → confirmation
    └── Nouveau patient → collecte admin (mutuelle, antécédents) avant 1er RDV
    │
    ▼
[Rappels automatiques]
    ├── J-2 : rappel RDV
    ├── J-1 : rappel + bouton "Reporter / Annuler"
    └── J-0 : rappel heure + infos pratiques
    │
    ▼
[Reprogrammation guidée]
    ├── Annulation → créneau libéré → proposé à liste d'attente automatiquement
    └── Nouveau créneau proposé directement dans le fil WhatsApp
    │
    ▼
[Couche IA / RAG]
    ├── FAQ personnalisée (avant/après soins, consignes, remboursements)
    ├── Triage messages : urgent / non urgent / administratif
    └── Résumés de conversation → envoyés par email/Sheets au praticien
    │
    ▼
[Back-office]
    ├── Dashboard : planning, taux de no-show, reprogrammations
    └── Paramétrage par praticien : délais, types d'actes, horaires
```

## Stack technique
- WhatsApp Business API (via 360dialog ou Twilio)
- n8n : orchestration des flux
- Google Calendar : gestion des créneaux (source de vérité)
- Google Sheets / Notion : back-office et dashboard
- Claude (RAG) : FAQ + triage + résumés

## Point de friction à clarifier avec le client
**Logiciels métier (Doctolib, HelloDoc, Médoc, Veasy) = silos fermés.**
Pas d'API publique → le bot tourne en parallèle, pas dans Doctolib.
Le secrétariat voit les RDV dans Google Calendar + reporte dans leur logiciel.
À expliquer clairement avant signature.

## ROI principal
- Réduction no-show (objectif : -50% via rappels automatiques)
- Secrétariat libéré des appels entrants et relances
- Créneaux libérés remis en circulation automatiquement (liste d'attente)
- Onboarding nouveau patient sans paperasse le jour J
