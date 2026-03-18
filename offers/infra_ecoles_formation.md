# Infra — Écoles & centres de formation

## Objectif
Qualifier automatiquement les prospects entrants, scorer leur maturité, gérer les financements, et maximiser le taux de transformation en inscription.

## Schéma général

```
[Lead entrant]
    │
    ├── Paid ads → landing → formulaire → déclenchement WhatsApp
    └── Lien WhatsApp sur site / pages programmes / emails de relance
    │
    ▼
[Bot de qualification]
    ├── Projet professionnel
    ├── Niveau actuel / parcours
    ├── Disponibilité (rythme, dispo)
    ├── Localisation
    └── Financement : CPF / OPCO / alternance / Pôle Emploi / perso
    │
    ▼
[Scoring automatique A/B/C]
    ├── A (chaud) → routage conseiller immédiat + alerte
    ├── B (tiède) → prise de RDV orientation + séquence pré-RDV
    └── C (froid) → nurture automatisé (séquence longue 4-8 semaines)
    │
    ▼
[Gestion du financement — module clé]
    ├── Identification du dispositif selon profil (CPF, OPCO, alternance...)
    ├── Explication des démarches étape par étape dans le fil WhatsApp
    └── Envoi automatique des docs nécessaires selon dispositif
    │
    ▼
[Pré-RDV & RDV orientation]
    ├── Rappels J-1 et J-0
    ├── Message pré-RDV : docs à lire, ce à quoi s'attendre
    ├── No-show → relance à 2h, 24h, 72h avec nouveaux créneaux
    └── Résumé de qualification envoyé au conseiller avant l'appel
    │
    ▼
[Couche IA / RAG]
    ├── Bot "conseiller formation" : brochures, programmes, FAQ, admission, financement
    ├── Réponses personnalisées selon profil (reconversion, alternance, international)
    └── Résumés de qualification → envoyés au conseiller avant chaque entretien
    │
    ▼
[Back-office]
    ├── Dashboard leads : source, score, avancement (contacté / RDV / inscrit)
    └── Export / sync CRM admissions + stats par campagne
```

## Stack technique
- WhatsApp Business API (via 360dialog ou Twilio)
- n8n : orchestration des flux
- Google Sheets / Notion / CRM admissions : suivi leads
- Google Calendar : RDV conseillers
- Claude (RAG) : assistant formation + résumés qualification

## Point critique : le financement
Le financement est le principal bloquant à l'inscription (CPF, OPCO, alternance, Pôle Emploi = règles différentes par dispositif).
Le bot doit :
1. Identifier le bon dispositif selon le profil
2. Expliquer les démarches simplement
3. Envoyer les bons docs au bon moment

Sans ce module, 70% des prospects qualifiés ne convertissent pas.

## ROI principal
- Conseillers contactent uniquement les leads A (plus de temps perdu sur leads non qualifiés)
- Taux de no-show entretien réduit via rappels multi-étapes
- Module financement intégré → moins de blocages post-qualification
- Nurture long terme → récupère les leads "pas encore prêts" sur 4-8 semaines
