---
name: n8n-automation-update
description: Use when updating, correcting, or modifying nodes in an existing n8n workflow. Handles both copy-paste output and direct API apply.
disable-model-invocation: true
---

# Skill: n8n-update

## Purpose
Modifier des nodes spécifiques dans un workflow n8n existant.
Deux modes d'exécution selon l'instruction :
- **Copy-paste** : génère l'expression ou le JSON à coller manuellement dans n8n
- **Apply direct** : applique la modification via l'API sans activer le workflow

---

## Inputs attendus

- **Workflow ciblé** : nom ou ID du workflow (si inconnu, lancer `python tools/n8n_api.py workflows` pour lister)
- **Node(s) à modifier** : nom exact du node dans n8n
- **Modification** : ce qui doit changer (valeur d'un paramètre, expression, logique)
- **Mode** : copy-paste OU apply direct (déduire du contexte ou demander)

---

## Process

### Step 1 — Diagnostic client

Demander via AskUserQuestion :
> "Est-ce qu'un diagnostic client existe pour ce workflow ?"
> Options : Oui / Non / Autre (permettre de préciser)

**Si Oui :**
Lister les fichiers dans `.tmp/diagnostics/` :
```bash
ls .tmp/diagnostics/
```
Demander via AskUserQuestion lequel correspond au client, avec un choix par fichier trouvé.
Lire le fichier sélectionné entièrement.

**Si Non :**
Passer directement au Step 2.

### Step 2 — Identifier le workflow cible

Si l'ID du workflow est inconnu :
```bash
python tools/n8n_api.py workflows
```
Demander via AskUserQuestion lequel correspond, avec un choix par workflow listé.

### Step 3 — Analyser et proposer les mises à jour

Récupérer le workflow existant via l'API :
```bash
python tools/n8n_api.py workflows
```

Croiser **trois sources** pour déterminer quoi modifier :
1. **Le diagnostic client** (besoins, flux attendu, critères de qualification)
2. **Le workflow existant** (nodes actuels, paramètres, logique en place)
3. **L'instruction de l'utilisateur** (correction spécifique demandée)

Pour chaque node à modifier, produire une fiche :
```
### Node : [Nom exact]
- **Situation actuelle :** [ce que fait le node aujourd'hui]
- **Problème identifié :** [pourquoi ça ne correspond pas au besoin]
- **Modification proposée :** [ce qui doit changer]
- **Impact :** [effet attendu sur le flux]
```

Demander confirmation avant d'appliquer quoi que ce soit.

### Step 3 — Produire la modification

**Mode copy-paste :**
Générer directement la valeur / expression prête à coller.
Préciser exactement :
- Nom du node
- Nom du champ / paramètre
- Valeur à coller (expression n8n complète si besoin)

Format de sortie :
```
## Modification à appliquer

**Workflow :** [nom]
**Node :** [nom exact]
**Champ :** [nom du paramètre]

**Valeur à coller :**
[valeur ou expression complète]
```

**Mode apply direct :**
Utiliser le script Python pour appliquer sans activer :
```bash
python tools/n8n_api.py update <workflow_id> <node_name> <param_key> <value_file>
```

Si la commande n'existe pas encore dans le tool, générer un script `.tmp/` dédié à la modification.
Ne jamais activer le workflow automatiquement — toujours laisser en `active: false`.

### Step 4 — Confirmer

- Mode copy-paste : indiquer où coller et quoi vérifier après
- Mode apply direct : afficher le résultat de l'API (versionId, statut)

---

## Règles

- **Jamais d'activation automatique** — le test est toujours manuel
- **Ne modifier que les nodes demandés** — ne pas toucher au reste du workflow
- **Valider le JSON avant envoi** — un JSON invalide casse le workflow
- En cas de doute sur le node exact ou le champ, demander avant d'agir

---

## Notes
- Draft v0.1
- `n8n-create` (créer un nouveau workflow) = skill séparé, à construire
- Étendre `tools/n8n_api.py` avec une commande `update` quand le besoin se présente
