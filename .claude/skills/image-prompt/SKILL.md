---
name: image-prompt
description: Use when generating, testing, or iterating on image prompts for Automation Act LinkedIn posts. Produces prompt variants without touching the n8n workflow.
disable-model-invocation: true
---

# Skill: image-prompt

## Purpose
Générer et tester des variantes de prompts image pour les posts LinkedIn Automation Act.
Sandbox de test : aucune modification du workflow n8n — le déploiement passe par `n8n-update` quand le prompt est validé.

---

## Inputs attendus

- **Format de post** : Résultat concret / Architecture / Optimisation / Preuve
- **Contexte** : métriques, outils, résultats à représenter (optionnel — peut être vague)
- **Modification ciblée** (si itération) : ce qui ne va pas dans le prompt actuel

---

## Step 1 — Identifier le besoin

Demander via AskUserQuestion :

| Mode | Quand |
|------|-------|
| Nouveau prompt | Créer un prompt pour un format pas encore couvert |
| Itération | Améliorer un prompt existant (résultat pas satisfaisant) |
| Variante | Tester une approche visuelle différente pour un format existant |

Si itération : demander ce qui ne va pas dans le résultat actuel (trop de texte, mauvaise mise en page, couleurs incorrectes, etc.)

---

## Step 2 — Générer le prompt

Produire une expression n8n complète prête à l'emploi (format `={{ ... }}`).

### Spécifications visuelles Automation Act

**Canvas :** 1080×1080px
**Fond :** #F2FBF5 solide + grille subtile (lignes 48px, gris très clair, 1px, à peine visible)
**Cartes :** fond blanc #FFFFFF, border-radius 20px, box-shadow `0 8px 32px rgba(0,0,0,0.08)`
**Couleurs :** navy #0F172A (texte sombre), vert forêt #2F9E6B (valeurs positives, badges succès)
**Typographie :** Inter ou Poppins, taille maximisée pour lisibilité
**Footer** (sous les cartes, sur le fond) : 3 colonnes — "Temps de déploiement" / "Zéro outil ajouté" / "Premiers résultats" + badge "automationact.com" bas droite en gris muted
**Interdit :** codes couleur visibles dans le rendu, icônes, visages, logos, phrases descriptives dans les valeurs

### Prompts par format

**Résultat concret**
2 cartes côte à côte (490px chacune, 880px de haut).
Carte gauche : badge "Sans automatisation" (navy). Carte droite : badge "Avec automatisation" (vert forêt).
Exactement 3 lignes de métriques par carte. Valeur en très grand (70-90px), label court en dessous (16px muted).
Valeurs gauche en navy, valeurs droite en vert forêt. Pas de phrases.

**Architecture**
1 grande carte (1020px wide, 820px tall).
Badge "Architecture" (navy). Titre bold 26px (objectif de l'automatisation).
Flux horizontal : pills d'outils (fond vert forêt, texte blanc, 16px bold) reliés par flèches →.
Note italique bas de carte : "Pas d'outil ajouté — orchestration de l'existant".

**Optimisation**
1 grande carte (1020px wide, 820px tall).
Badge "Optimisation" (navy). Moitié haute : label "Avant" muted + état initial en dark text.
Séparateur horizontal. Moitié basse : label "Après" vert forêt + amélioration en bold vert forêt.
Métrique clé affichée en très grand vert forêt en bas de carte.

**Preuve**
1 grande carte (1020px wide, 820px tall).
Badge "Résultats" (vert forêt). 3 à 5 lignes checklist : cercle vert ✓ + texte bold 20px.
Chiffre clé en grand vert en bas si disponible.

---

## Step 3 — Produire la sortie

**Format de sortie :**

```
## Prompt image — [format] — variante [N]

### Expression n8n (copy-paste dans "Build Image Prompt")
[expression complète ={{ ... }}]

### Ce que ce prompt produit
- [point visuel 1]
- [point visuel 2]
- [point visuel 3]

### Pour tester
Envoyer un message Telegram de test avec ces données :
[exemple de données de test]

### Pour déployer
Utiliser n8n-update sur le node "Build Image Prompt", champ "value".
```

Sauvegarder dans `.tmp/image-prompts/[format]-v[N].md`.

---

## Step 4 — Itération

Si le résultat visuel n'est pas satisfaisant après test, diagnostiquer :

| Problème | Correction |
|----------|-----------|
| Texte trop petit | Augmenter la taille de police demandée |
| Codes couleur visibles | Renforcer l'interdiction dans le prompt |
| Mauvaise mise en page | Préciser les dimensions et positions exactes |
| Trop de texte | Ajouter "NO sentences, ONLY values and short labels" |
| Footer mal placé | Préciser "directly on grid background, no box, below cards" |

Générer une nouvelle variante numérotée et la sauvegarder séparément.

---

## Règles
- Jamais de déploiement direct — uniquement via `n8n-update` après validation manuelle
- Chaque variante = fichier séparé (ne pas écraser les précédentes)
- Toujours produire l'expression n8n complète, pas juste la description textuelle
- Si le format de post n'est pas précisé, demander avant de générer

---

## Notes
- Draft v0.1
- Prompt de référence actuel (production) : `.tmp/update_image_v2.ps1` → variable `$n1val`
- À enrichir avec des captures des résultats validés
