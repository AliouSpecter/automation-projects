---
name: site-add-automation
description: Use when adding a new automation page to automationact.com. Generates adapted HTML from a brief and creates the draft post on WordPress via API.
disable-model-invocation: true
---

# Skill: site-add-page

## Purpose
Créer une nouvelle page d'automatisation sur automationact.com à partir d'un brief ou d'une idée.
Génère le HTML section par section (adapté du template de référence) et publie en brouillon sur WordPress via l'API REST.

## Reference template
`.tmp/reference_post.html` — HTML du post ID 1312 (post de référence, structure Elementor + custom HTML)
Lire ce fichier avant de générer quoi que ce soit.

---

## Inputs attendus

- **Nom de l'automatisation** (ex: "Qualification automatique de leads immobiliers")
- **Brief** : ce que ça fait, pour qui, quels outils, quels gains
- **Métriques avant/après** si disponibles (sinon, inventer des valeurs plausibles du secteur avec note "(estimé)")

---

## Process

### Step 1 — Collecter le brief

Si l'utilisateur n'a pas tout fourni, demander via AskUserQuestion :
- Nom de l'automatisation
- Problème résolu / pour qui
- Stack utilisée (outils connectés)
- Gain principal (temps, argent, erreurs éliminées)

### Step 2 — Lire le template

Lire `.tmp/reference_post.html` entièrement pour comprendre la structure HTML exacte (classes CSS, balises, sections).

### Step 3 — Générer le HTML section par section

Adapter chaque section du template au nouveau cas. Conserver les classes CSS existantes (`aa2-aab*`).

**Sections à produire :**

1. **Hero** (`#hero`) — Titre H1 accrocheur + sous-titre descriptif (ce que l'automatisation fait concrètement)

2. **Avant/Après** — 2 cartes côte à côte :
   - Carte "Avant" : **3 à 5 items** selon la lisibilité — choisir les métriques les plus parlantes, pas forcément toutes
   - Carte "Après" : mêmes items avec valeurs améliorées (classe `aa2-aabList__val--good`)
   - Référence 3 items : page creas_linkedin (https://www.automationact.com/creas_linkedin/)

3. **Problème** — Section "Pourquoi c'est difficile à faire manuellement" : 3-4 points de friction

4. **À quoi ça sert / Pour qui** — Description de l'objectif + profil de l'utilisateur cible

5. **Comment ça marche** — Étapes numérotées du flux (6 étapes max)

6. **Résultats & prérequis** — Ce qu'on obtient + ce qu'il faut avoir en place pour démarrer

### Step 4 — Assembler et sauvegarder

Assembler le HTML complet avec le wrapper Elementor :
```html
<div data-elementor-type="wp-post" class="elementor">
  <div class="elementor-element e-flex e-con-boxed e-con e-parent">
    <div class="e-con-inner">
      <div class="elementor-element elementor-widget elementor-widget-html">
        [sections HTML ici]
      </div>
    </div>
  </div>
</div>
```

Sauvegarder dans `.tmp/pages/[slug].html`.

### Step 5 — Créer le brouillon WordPress (post_content)

```powershell
powershell.exe -ExecutionPolicy Bypass -File tools/wp_api.ps1 create "[Titre]" ".tmp/pages/[slug].html"
```

Noter l'ID du post créé (ex: 1376).

### Step 6 — Injecter le contenu Elementor (_elementor_data)

**CRITIQUE** : WordPress crée le post mais Elementor affiche une page vide car il lit `_elementor_data` (meta), pas `post_content`.

Créer `.tmp/fix_elementor_[postId].ps1` basé sur `.tmp/fix_elementor_1376.ps1` avec le bon `$postId` et `$htmlFile`, puis exécuter :

```powershell
powershell.exe -ExecutionPolicy Bypass -File ".tmp/fix_elementor_[postId].ps1"
```

Le script :
1. Extrait les 5 `<section>` du fichier HTML avec regex `(?s)(<section\s+class="aa2-[^"]+".+?</section>)`
2. Construit un array Elementor JSON (5 containers × 1 HTML widget chacun)
3. PATCHe le post avec `meta._elementor_data` + `meta._elementor_edit_mode = "builder"`

Afficher le lien d'édition pour que l'utilisateur vérifie et publie.

### Step 7 — Générer et injecter l'image à la une

**Principe** : une image par page, style metric impactant (grand chiffre vert sur fond #F2FBF5), sans badge de catégorie (déjà affiché sur la page archive par WordPress).

**7a — Identifier le metric clé** à partir du contenu de la page :
- Priorité : réduction de coût (-X%), gain de temps (-X% ou Xmin), multiplication de volume (xN)
- Eyebrow : courte description du KPI (ex: "Coût par article SEO", "Temps de production")
- Stat : le chiffre fort (ex: "-90%", "10 min", "x4")
- Unit : le contexte du chiffre (ex: "vs rédacteur externe", "pour 8 créas testables")
- Label : ce que l'automatisation produit (1 ligne, max 50 caractères)
- Sub : une phrase courte de résumé (ex: "Brief Notion → article publié. Zéro rédacteur.")

**7b — Créer le HTML de capture** `.tmp/featured-image-[postId].html` :

```html
<!DOCTYPE html>
<html><head><meta charset="UTF-8">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  html, body { width: 1200px; height: 630px; overflow: hidden; font-family: -apple-system, 'Segoe UI', sans-serif; }
  body {
    background: radial-gradient(800px 500px at 60% 30%, rgba(18,120,74,0.14), transparent 55%),
                linear-gradient(to bottom right, #F2FBF5, #edf7f0);
    display: flex; align-items: center; justify-content: center; position: relative;
  }
  body::before { content: ''; position: absolute; inset: 0;
    background-image: radial-gradient(rgba(15,23,42,0.07) 1px, transparent 1px);
    background-size: 28px 28px; }
  .logo { position: absolute; bottom: 36px; right: 52px; font-size: 14px; font-weight: 700; color: rgba(15,23,42,0.28); z-index: 1; }
  .center { display: flex; flex-direction: column; align-items: center; position: relative; text-align: center; z-index: 1; }
  .eyebrow { font-size: 15px; font-weight: 700; color: rgba(15,23,42,0.38); letter-spacing: 0.08em; text-transform: uppercase; margin-bottom: 8px; }
  .stat-val { font-size: 160px; font-weight: 900; color: #12784A; line-height: 1; letter-spacing: -0.04em; }
  .stat-unit { font-size: 32px; font-weight: 700; color: rgba(15,23,42,0.45); margin-top: 4px; margin-bottom: 28px; }
  .divider { width: 52px; height: 3px; background: rgba(18,120,74,0.30); border-radius: 99px; margin-bottom: 28px; }
  .stat-label { font-size: 34px; font-weight: 900; color: #0F172A; letter-spacing: -0.02em; line-height: 1.15; }
  .stat-sub { font-size: 20px; font-weight: 500; color: rgba(15,23,42,0.42); margin-top: 10px; }
</style></head>
<body>
  <div class="center">
    <div class="eyebrow">[EYEBROW]</div>
    <div class="stat-val">[STAT]</div>
    <div class="stat-unit">[UNIT]</div>
    <div class="divider"></div>
    <div class="stat-label">[LABEL]</div>
    <div class="stat-sub">[SUB]</div>
  </div>
  <div class="logo">automationact.com</div>
</body></html>
```

**7c — Générer le PNG** via Edge headless :

```powershell
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$html = "c:\...\..tmp\featured-image-[postId].html"
$out  = "c:\...\..tmp\featured-image-[postId].png"
& $edge "--headless=old" --disable-gpu --no-sandbox --hide-scrollbars "--screenshot=$out" "--window-size=1200,630" "file:///$($html.Replace('\','/'))"
Start-Sleep -Seconds 3
```

**7d — Uploader et associer** via script PowerShell (modèle : `.tmp/upload_featured_image.ps1`) :
- POST `/wp-json/wp/v2/media` avec header `Content-Type: image/png` + body = bytes du PNG
- PATCH `/wp-json/wp/v2/posts/[postId]` avec `{ featured_media: <mediaId> }`

**Règles image :**
- Jamais de badge de catégorie (WordPress l'affiche déjà)
- Toujours les accents (é, è, ê, à, ù, î, ô, û, ç...)
- Jamais de tiret long (—)
- Stat en vert #12784A, fond #F2FBF5, logo "automationact.com" muted en bas à droite

---

## Règles
- Toujours créer en **brouillon** — jamais publier directement
- Conserver les classes CSS du template — ne pas en inventer de nouvelles
- Si métriques manquantes : inventer des valeurs plausibles du secteur avec note "(estimé)"
- Le titre WordPress = titre H1 de la page (pas de duplication)
- **Toujours exécuter Step 6** après Step 5 — sinon la page est vide dans Elementor
- **Jamais de tiret long (—) dans le texte** — utiliser ":" ou "-" ou reformuler
- **Texte concis** : aller à l'essentiel, éviter les répétitions, rester complet et équilibré — ni trop court ni verbeux
- **Métriques** : choisir 3 à 5 items selon la pertinence, pas toujours 5 par obligation
- **Corrections ciblées** : modifier uniquement les éléments demandés via Edit — ne pas régénérer tout le HTML sauf si c'est clairement plus simple et efficace

---

## Notes
- Tool : `tools/wp_api.ps1` (PowerShell — Python non installé sur cette machine)
- Posts existants : ID 1312, 1252, 463, 1376 (LinkedIn Post automation)
- Template de référence : `.tmp/reference_post.html`
- Script Elementor de référence : `.tmp/fix_elementor_1376.ps1`
- Structure Elementor : array JSON de containers, chaque container = 1 HTML widget avec `settings.html = "<section...>"`
