# Infra — Ressources Humaines PME

## Objectif
Automatiser les tâches répétitives du recrutement et de l'onboarding pour que le RH se concentre sur les entretiens, l'intégration et le pilotage — sans changer d'outils.

## Schéma général

```
[Candidature entrante]
    │
    ├── Indeed / LinkedIn / APEC → parsing email → déclenchement séquence
    └── Formulaire site carrières → trigger automatique
    │
    ▼
[Accusé de réception automatique]
    └── Email personnalisé < 5 min : confirmation réception + délai de retour
    │
    ▼
[Scoring IA sur CV]
    ├── Analyse CV selon critères du poste (expérience, compétences, localisation)
    ├── Score A/B/C généré automatiquement
    ├── A + B → résumé profil envoyé au RH pour validation (email ou Notion)
    │       │
    │       ├── [HUMAIN] RH consulte les profils A et B, valide ou rejette chacun
    │       │
    │       ├── Validé → lien Calendly envoyé automatiquement au candidat
    │       └── Rejeté → refus automatique poli sous 24h
    └── C (hors critères) → refus automatique poli sous 24h (pas de validation requise)
    │
    ▼
[Coordination entretien]
    ├── Lien de prise de RDV envoyé directement (Calendly / Cal.com)
    ├── Rappels J-1 et J-0 candidat (email ou SMS)
    ├── No-show → relance automatique avec nouveaux créneaux (x2 max)
    └── Résumé profil + notes envoyés au recruteur 30 min avant l'appel
    │
    ▼
[Post-entretien]
    ├── Email de suivi automatique au candidat (délai de retour)
    ├── [HUMAIN] RH saisit sa décision : Retenu / En attente / Refusé
    │       │
    │       ├── Retenu → déclenchement séquence onboarding automatique
    │       ├── En attente → relance automatique au RH si pas de décision sous 5 jours
    │       └── Refusé → email de refus automatique poli au candidat
    └── Archivage automatique dans pipeline recrutement (Notion / Sheets)
    │
    ▼
[Onboarding — déclenchement à la signature]
    ├── Email de bienvenue J-7 (contexte, équipe, adresse, parking)
    ├── Collecte documents par étapes : RIB, pièce identité, diplômes, mutuelle
    ├── Relances automatiques si document manquant (J-5, J-3, J-1)
    ├── Checklist accès outils J-1 (email pro, logiciels, badges)
    ├── [HUMAIN] Manager confirme que les accès sont en place avant J1
    └── Check J+30 : feedback manager + feedback nouveau collaborateur
            │
            └── [HUMAIN] RH lit les retours et décide de la suite (validation PE, actions correctives)
```

## Stack technique
- Gmail / Outlook : source emails candidatures
- n8n : orchestration des flux
- Claude (IA) : scoring CV, résumés profil, emails personnalisés
- Calendly / Cal.com : prise de RDV sans allers-retours
- Notion / Google Sheets : pipeline recrutement + suivi onboarding
- Brevo / Mailjet : envoi emails séquences

## Deux offres

**Recrutement + Onboarding**
Pour les PME en croissance avec recrutements fréquents. Couvre tout le cycle : candidature entrante → collaborateur opérationnel.

**Recrutement uniquement**
Pour les PME avec 1-3 postes ouverts en permanence, submergées par le volume de CVs et les relances manuelles.

## Point critique : la réactivité
70% des candidats qualifiés acceptent la première offre sérieuse reçue.
Un accusé de réception sous 5 min + lien Calendly immédiat = avantage concurrentiel direct sur les entreprises qui répondent en 48h.
Sans ce point, le scoring et l'onboarding n'ont pas d'importance — le candidat est déjà parti.

## ROI principal
- RH contacte uniquement les profils déjà scorés A (plus de lecture de CVs non qualifiés)
- Réduction no-shows entretien via rappels multi-étapes
- Onboarding docs complet avant J1 (fini les relances administratives la première semaine)
- Candidats refusés notifiés proprement (image employeur préservée)
- Pipeline recrutement visible et traçable à tout moment
