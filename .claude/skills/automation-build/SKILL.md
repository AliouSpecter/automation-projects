# Skill: automation-build

## Purpose
Conçoit l'architecture d'un workflow n8n à partir d'un diagnostic ou brief, et produit un livrable de build structuré et actionnable.

## Trigger
Utilisé quand l'utilisateur dit "construis le workflow" / "automation-build" / "on passe au build" ou référence un diagnostic existant.

---

## Inputs attendus

- **Diagnostic existant** : chemin vers `.tmp/diagnostics/[client].md` (prioritaire)
- **OU brief direct** : description du flux à automatiser
- **Flux ciblé** : si le diagnostic contient plusieurs opportunités, lequel on build en premier

---

## Process

### Step 1 — Lire le diagnostic
Si un fichier `.tmp/diagnostics/[client].md` existe, le lire entièrement.
Identifier le flux prioritaire (Niveau 1 / Quick win sauf indication contraire).

### Step 2 — Concevoir l'architecture du workflow

Décomposer le flux en nodes n8n dans l'ordre d'exécution :

| # | Node | Type n8n | Rôle |
|---|------|----------|------|
| 1 | ... | Trigger / Action / Logic | ... |

**Types de nodes à utiliser :**
- **Triggers** : Webhook, Schedule, Gmail Trigger, HubSpot Trigger
- **Logic** : IF, Switch, Merge, Wait
- **Transformation** : Set, Code (JS), Edit Fields
- **Services** : Gmail, HubSpot, Google Sheets, HTTP Request
- **Utilitaires** : No Operation (placeholder), Error Trigger, Stop and Error

**Règles de conception :**
- Toujours commencer par le trigger
- Un node = une responsabilité
- Nommer les nodes en français clair (ex: "Filtrer zone géographique")
- Prévoir une branche d'erreur si le flux est critique
- Éviter les nodes inutiles — rester minimal et solide

### Step 3 — Définir la logique métier

Pour chaque node IF ou Switch, documenter :
- Condition exacte (champ, opérateur, valeur)
- Branche TRUE → action
- Branche FALSE → action ou fin

### Step 4 — Identifier les credentials

Lister les credentials n8n à configurer :
- Nom de la credential dans n8n
- Service concerné
- Type (API Key, OAuth2, Basic Auth)

### Step 5 — Définir le plan de test

3 scénarios minimum :
1. **Happy path** : lead qualifié → flux complet
2. **Rejet** : lead non qualifié → email de refus
3. **Edge case** : données manquantes ou malformées

### Step 6 — Sauvegarder le livrable

Écrire le livrable dans `.tmp/builds/[nom-client].md` et indiquer le chemin.

---

## Format du livrable

```
# Build — [Nom client] — [Nom du flux]

**Date :** YYYY-MM-DD
**Basé sur :** .tmp/diagnostics/[client].md
**Priorité :** Niveau 1 / Quick win

---

## Architecture du workflow

| # | Nom du node | Type n8n | Rôle |
|---|-------------|----------|------|
| 1 | ...         | ...      | ...  |

---

## Logique détaillée

### Node X — [Nom]
- **Type :** IF
- **Condition :** [champ] [opérateur] [valeur]
- **TRUE →** [action]
- **FALSE →** [action]

---

## Credentials nécessaires

| Credential | Service | Type |
|-----------|---------|------|
| ...       | ...     | ...  |

---

## Plan de test

| Scénario | Input | Résultat attendu |
|----------|-------|-----------------|
| Happy path | ... | ... |
| Rejet | ... | ... |
| Edge case | ... | ... |

---

## Prochaine étape
[ ] Créer le workflow dans n8n
[ ] Configurer les credentials
[ ] Tester scénario par scénario
[ ] Activer en production
```

---

## Principes Automation Act
- Utiliser uniquement les outils déjà dans la stack client
- Préférer les nodes natifs n8n aux HTTP Request génériques
- Un workflow = un objectif métier clair
- Build minimal d'abord, itérer ensuite

---

## Notes
- Draft v0.1 — à enrichir avec des builds réels
- Ajouter des patterns récurrents (qualification lead, relance, centralisation CRM)
- Lier à `n8n-deploy` quand le déploiement programmatique est prêt
