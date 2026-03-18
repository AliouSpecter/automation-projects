# Infra — Assurance / Courtage

## Objectif
Répondre à chaque lead entrant en moins de 5 minutes, relancer les devis sans intervention manuelle, et ne jamais laisser un renouvellement partir à la concurrence.

## Schéma général

```
[Lead entrant]
    │
    ├── Comparateur (LeLynx, Assurland, Meilleurtaux) → email → trigger auto
    ├── Formulaire site → trigger auto
    └── Recommandation / bouche-à-oreille → formulaire ou appel direct
    │
    ▼
[Réponse automatique < 5 min]
    ├── Email : confirmation réception + délai de rappel
    └── SMS (Twilio / Sinch) : confirmation + opt-in WhatsApp
            "Bonjour, on a bien reçu votre demande.
             Un conseiller vous rappelle dans l'heure.
             Vous préférez échanger par WhatsApp ? → [wa.me/33X?text=Bonjour+j%27ai+soumis+une+demande]"
    │
    ▼
[Choix canal prospect]
    ├── Prospect clique WhatsApp → conversation ouverte par le prospect (opt-in conforme)
    │       └── Suite du process sur WhatsApp : qualification, devis, relances, renouvellement
    └── Pas de clic → suite du process par email uniquement
    │
    ▼
[Qualification automatique]
    ├── Questions clés (email ou WhatsApp) : type de contrat, situation, budget, échéance actuelle
    └── Résumé profil généré automatiquement → envoyé au courtier avant l'appel
    │
    ▼
[Coordination RDV]
    ├── Lien Calendly envoyé si prospect qualifié
    ├── Rappels J-1 et J-0 (email + SMS ou WhatsApp selon canal choisi)
    └── No-show → relance automatique x2 avec nouveaux créneaux
    │
    ▼
[Suivi devis]
    ├── Devis envoyé → relance automatique J+2, J+5, J+10
    ├── [HUMAIN] Courtier peut interrompre la séquence à tout moment si contact établi
    └── Pas de réponse à J+10 → clôture automatique + archivage
    │
    ▼
[Renouvellements]
    ├── Alerte automatique 90j avant échéance contrat
    ├── Séquence email/WhatsApp : rappel bénéfices, invitation à rester ou revoir le contrat
    ├── [HUMAIN] Courtier reçoit un résumé client + flag "à risque" si pas de réponse sous 30j
    └── Signature → confirmation automatique + mise à jour fiche client
    │
    ▼
[Back-office]
    ├── Pipeline leads : source, statut, devis envoyé, relances effectuées
    └── Sync CRM (HubSpot, Pipedrive) ou Google Sheets
```

## Stack technique
- Gmail / Outlook : source leads comparateurs
- n8n : orchestration des flux
- Twilio / Sinch : SMS opt-in WhatsApp
- WhatsApp Business API (via 360dialog ou Twilio) : suivi prospect opt-in
- Brevo / Mailjet : séquences email (prospects sans WhatsApp)
- Calendly : prise de RDV sans allers-retours
- Claude (IA) : résumés profil, personnalisation emails et messages
- Notion / Google Sheets / CRM existant : pipeline leads + suivi renouvellements

## Note technique : opt-in WhatsApp via SMS
Le lien wa.me dans le SMS contient un message pré-rempli pour que le prospect sache quoi écrire.
Format : `wa.me/33XXXXXXXXX?text=Bonjour+j%27ai+soumis+une+demande+d%27assurance`
C'est le prospect qui initie la conversation WhatsApp — conforme RGPD, aucun envoi non sollicité.
Si le prospect n'a pas WhatsApp ou ne clique pas → séquence email classique sans interruption.

## Deux offres

**Leads + Renouvellements**
Pour les cabinets qui veulent couvrir l'acquisition ET la fidélisation. Pipeline complet du lead entrant à la reconduction annuelle.

**Leads uniquement**
Pour les courtiers avec peu de renouvellements à gérer mais submergés par le volume de leads comparateurs sans suivi structuré.

## Point critique : la fenêtre des 5 minutes
Sur les comparateurs, le prospect soumet sa demande à 4-5 assureurs simultanément.
Celui qui répond en premier a 80% de chances de signer.
Les courtiers qui rappellent en 24h ne parlent plus qu'aux prospects que personne d'autre n'a voulu.
Sans réponse automatique < 5 min, tout le reste (qualification, relances, renouvellements) ne sert à rien.

## ROI principal
- Taux de contact lead x3 (réponse < 5 min vs 24-48h)
- -60% relances manuelles sur devis
- Renouvellements traités 90j à l'avance : zéro résiliation surprise
- Courtier intervient uniquement sur les prospects déjà contextualisés
- Canal WhatsApp activé uniquement si le prospect le choisit : relation plus fluide, moins de friction
