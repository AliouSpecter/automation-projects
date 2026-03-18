---
name: linkedin-post
description: Use when creating a LinkedIn post for Automation Act. Generates post text, proposes image content for validation, generates image via Gemini, then publishes after approval.
disable-model-invocation: true
argument-hint: "url, description, transcription vocale, ou brief libre"
---

# Skill: linkedin-post

## Purpose
Générer un post LinkedIn Automation Act + image (Gemini via n8n) + publication.
Pipeline : contenu → post (corrections) → contenu image (corrections) → génération Gemini → preview → publication.

---

## Step 1 — Collecter le contenu et déduire le format

Ne pas demander le format. L'utilisateur fournit son contenu librement — le format est déduit.

| Format | Signaux dans le contenu |
|--------|------------------------|
| **Résultat concret** | Avant/après chiffré, gain mesurable, cas client réel |
| **Architecture** | Stack technique, outils connectés, comment ça marche |
| **Optimisation** | Problème → ajustement → amélioration obtenue |
| **Preuve** | Validation, résultat vérifié, témoignage, chiffre externe |

Si le contenu peut correspondre à plusieurs formats, choisir celui qui met le mieux en valeur le résultat. Annoncer le format choisi et pourquoi avant de générer.

---

## Step 2 — Sources acceptées

**URL automationact.com** → WebFetch, extraire automatisation, outils, gains, métriques

**Copier-coller** → identifier résultat clé, contexte, chiffres

**Transcription vocale** → coller texte brut, reformuler dans la voix Automation Act

**Brief libre** → si métriques absentes : inventer valeurs plausibles B2B, noter "(estimé)"

---

## Step 3 — Générer le post LinkedIn

Style Automation Act :
- Langue : français, ton direct, professionnel, B2B
- Longueur : 150–250 mots
- Structure : accroche forte → contexte → résultat/valeur → CTA discret
- Pas d'emojis, pas de hashtags (sauf si demandé)
- **Jamais de tiret long (—) dans le texte**

Présenter le post. **Boucle corrections** jusqu'à validation explicite ("ok", "valide", "c'est bon").
Ne pas passer à l'image avant validation.

### Formats de référence

**Résultat concret**
```
[Accroche : chiffre ou résultat frappant]
[Contexte : qui, situation, problème]
Avant : [métriques x3]
Après automatisation : [métriques x3 améliorées]
[Approche en 1-2 phrases]
[CTA]
```

**Architecture**
```
[Accroche : ce que l'automatisation accomplit]
[Problème initial]
Stack : [outil A] → [outil B] → [outil C]
[Résultat]
[CTA]
```

**Optimisation**
```
[Accroche : le problème]
Avant : [situation initiale] / Après : [amélioration]
Gain : [chiffre clé]
[Logique en 2-3 phrases]
[CTA]
```

**Preuve**
```
[Accroche : résultat validé]
[Contexte]
[Preuve : chiffre, validation, témoignage]
[Ce que ça démontre]
[CTA]
```

---

## Step 4 — Proposer le contenu de l'image

Une fois le post validé, proposer sous forme de tableau ce qui apparaîtra dans l'image.
**Ne pas générer l'image avant validation de ce tableau.**

### 4a — Tableau de contenu selon le format

**Résultat concret** → carte avant/après avec 3 lignes :

| Colonne | Valeur gauche (Sans automatisation) | Valeur droite (Avec automatisation) |
|---------|--------------------------------------|--------------------------------------|
| Ligne 1 | [valeur avant 1]                    | [valeur après 1]                    |
| Ligne 2 | [valeur avant 2]                    | [valeur après 2]                    |
| Ligne 3 | [valeur avant 3]                    | [valeur après 3]                    |

**Architecture** → badges outils + titre :

| Champ | Valeur |
|-------|--------|
| Titre | [objectif de l'automatisation, court] |
| Outils | [outil1] → [outil2] → [outil3] |
| Tagline | Pas d'outil ajouté — orchestration de l'existant |

**Optimisation** → carte état initial / amélioration :

| Champ | Valeur |
|-------|--------|
| Label avant | [état initial en quelques mots] |
| Label après | [amélioration en quelques mots] |
| Gain clé | [chiffre principal, grand et visible] |

**Preuve** → liste de résultats validés :

| # | Résultat |
|---|---------|
| 1 | [résultat 1] |
| 2 | [résultat 2] |
| 3 | [résultat 3] |

Règles pour les valeurs :
- Chiffres courts et percutants (3h, -90%, x8, J+0, 0 erreur)
- Max 3-4 mots par cellule
- Extraire du post validé — ne pas inventer si les chiffres sont explicites
- Si absent : proposer une valeur plausible avec note "(estimé)"

**Boucle corrections contenu** : appliquer les retours et re-présenter jusqu'à validation explicite.

### 4b — Construire le prompt Gemini (en interne, ne pas afficher)

Une fois le contenu validé, construire le prompt détaillé à envoyer à Gemini.
Le prompt décrit l'image pixel par pixel : dimensions, fond, layout des cartes, couleurs, typographie, valeurs à afficher, footer.

Socle commun à tous les formats :
```
1080x1080px square image. BACKGROUND: solid flat #F2FBF5. Subtle grid overlay: horizontal and vertical lines every 48px, very light gray, 1px, barely visible.
FOOTER: below card(s), directly on grid background (no box), 3 equally-spaced columns.
Col1: forest green bold label "Temps de déploiement" / dark bold value "[valeur du post ou 2 à 4 semaines]".
Col2: forest green bold label "Zéro outil ajouté" / dark bold value "branché sur l'existant".
Col3: forest green bold label "Premiers résultats" / dark bold value "[valeur du post ou dès J+14]".
IMPORTANT: use correct French spelling and accents throughout (é, è, ê, à, â, ç, etc.). Do NOT display any hex color codes or technical values in the image. No website URL or domain name anywhere in the image.
```

**Résultat concret** : ajouter au socle
```
LAYOUT: 2 side-by-side white cards, each 490px wide, 880px tall, 20px from edges, 10px gap.
CARD STYLE: background #FFFFFF, border-radius 20px, box-shadow 0 8px 32px rgba(0,0,0,0.08).
LEFT top: pill badge "Sans automatisation" (dark navy bg, white text).
RIGHT top: pill badge "Avec automatisation" (forest green bg, white text).
CONTENT: exactly 3 rows per card. Each row: large bold value 70-90px + short label below 16px muted gray.
Left card values in dark navy. Right card values in forest green. Right card: add % or multiplier badge where relevant.
NO sentences. Rows evenly spaced.
Values: LEFT=[val1_avant], [val2_avant], [val3_avant] / RIGHT=[val1_apres], [val2_apres], [val3_apres].
```

**Architecture** : ajouter au socle
```
LAYOUT: one large white card, 1020px wide, 820px tall, centered, 30px margin.
CARD STYLE: background #FFFFFF, border-radius 20px, box-shadow 0 8px 32px rgba(0,0,0,0.08).
TOP: pill badge "Architecture" (dark navy bg, white text).
TITLE: bold dark 26px "[titre]" (max 2 lines).
FLOW: horizontal row of tool name pills (forest green bg, white text, 16px bold) connected by right arrows: [outil1] → [outil2] → [outil3].
BOTTOM of card: italic muted gray 15px "Pas d outil ajoute - orchestration de l existant".
```

**Optimisation** : ajouter au socle
```
LAYOUT: one large white card, 1020px wide, 820px tall, centered, 30px margin.
CARD STYLE: background #FFFFFF, border-radius 20px, box-shadow 0 8px 32px rgba(0,0,0,0.08).
TOP: pill badge "Optimisation" (dark navy bg, white text).
UPPER HALF: label "Avant" muted gray + "[label_avant]" in dark text.
DIVIDER: thin horizontal line.
LOWER HALF: label "Apres" forest green + "[label_apres]" in bold forest green, large font.
KEY METRIC: "[gain]" very large in forest green at bottom of card.
```

**Preuve** : ajouter au socle
```
LAYOUT: one large white card, 1020px wide, 820px tall, centered, 30px margin.
CARD STYLE: background #FFFFFF, border-radius 20px, box-shadow 0 8px 32px rgba(0,0,0,0.08).
TOP: pill badge "Resultats" (forest green bg, white text).
CONTENT: [N] checklist rows. Each row: green circle checkmark + bold dark text 20px: "[résultat1]" / "[résultat2]" / "[résultat3]".
```

### 4c — Générer l'image

Exécuter via Bash avec le prompt construit :

```powershell
powershell.exe -ExecutionPolicy Bypass -File "tools/get_linkedin_image.ps1" `
  -prompt "PROMPT_COMPLET" `
  -outputPath ".tmp/posts/[YYYY-MM-DD]-image.png"
```

Timeout normal : 30-90 secondes (génération Gemini).

Après génération, indiquer le chemin de l'image. Attendre validation avant de publier.
Si l'image ne convient pas : identifier ce qui doit changer → corriger le tableau de contenu → relancer (retour à 4a).

---

## Step 5 — Poster sur LinkedIn

Demander confirmation explicite avant de poster.

**IMPORTANT : toujours passer par -textFile pour préserver les accents français.**
Écrire le texte dans un fichier UTF-8, puis appeler le script :

```powershell
# Étape 1 : écrire le texte dans un fichier (préserve les accents)
[System.IO.File]::WriteAllText(".tmp/posts/[date]-post.txt", $postText, [System.Text.Encoding]::UTF8)

# Étape 2 : publier via le fichier
powershell.exe -ExecutionPolicy Bypass -File "tools/post_linkedin_n8n.ps1" `
  -textFile ".tmp/posts/[date]-post.txt" `
  -imagePath ".tmp/posts/[date]-image.png"
```

**Si 401 Unauthorized** : exécuter `tools/linkedin_refresh.ps1` d'abord.
Si refresh échoue : `tools/linkedin_auth.ps1` (re-autorisation navigateur).

**Si timeout depuis Claude Code** : fournir la commande à coller dans un terminal PowerShell externe.

---

## Step 6 — Sauvegarder et clore

Sauvegarder dans `.tmp/posts/[date]-[format].md` :
```
# Post LinkedIn — [format] — [date]
## Post
[texte]
## Image
[chemin PNG]
## Statut
[Publié / En attente]
```

Mettre à jour TASKS.md.

---

## Règles
- Format déduit automatiquement
- Boucle corrections post → puis boucle corrections contenu image → puis génération
- **Jamais générer l'image sans validation du tableau de contenu**
- Confirmation explicite avant de poster
- Jamais de tiret long (—) dans le texte
- Mettre à jour TASKS.md après publication

---

## Notes
- v1.2 — prompt construit ici (Claude Code), n8n = relais Gemini pur
- Image : `tools/get_linkedin_image.ps1 -prompt "..." -outputPath "..."`
- Publication : `tools/post_linkedin.ps1` (direct LinkedIn API, token .env)
- Workflow n8n image : OIhz9pRyEJPyuIUz — reçoit `{prompt}`, retourne `{imageBase64}`
