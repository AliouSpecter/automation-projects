# Skill: linkedin-carousel

## Trigger
Utilisé quand l'utilisateur dit "crée un carrousel", "génère un carrousel LinkedIn", "carrousel PDF" ou référence un brief/résumé/workflow à transformer en slides LinkedIn.

---

## Objectif
Transformer un brief, résumé textuel ou workflow en carrousel PDF LinkedIn (6 slides) et le publier.

---

## Design & Format

- **Dimensions** : 1080 × 1350 px par slide (portrait 4:5, optimal LinkedIn)
- **Fond** : blanc pur (#FFFFFF)
- **Titre** : Arial bold, 68–88px, noir (#0F172A)
- **Corps** : Arial, 22–28px, gris (#334155 / #475569)
- **Accent couleur** : vert Automation Act (#12784A) pour numéros de slide, étiquettes, highlights
- **Footer** : "Aliou BA" + sous-titre, séparateur fin
- **Pas de logo Automation Act sur les slides**

## Structure type (6 slides)

| # | Type | Contenu |
|---|------|---------|
| 01 | Cover | Titre accrocheur + stats clés + "Swipe →" |
| 02 | WHAT CHANGED | Chiffres et faits — ce qui a bougé |
| 03 | WHY | 3 causes numérotées |
| 04 | WHAT WE DO NEXT | 3 priorités en highlight boxes colorées |
| 05 | TOP 3 ACTIONS | Cards avec médailles + Score ICE |
| 06 | CTA | Message fort + appel à l'action |

---

## Process

### Step 1 — Lire le contenu source
Identifier les sections WHAT CHANGED / WHY / WHAT WE DO NEXT / TOP 3 dans le brief fourni.
Extraire les chiffres clés pour le Cover (stats : anomalies, campagnes, tests).

### Step 2 — Générer le HTML des slides
Créer `.tmp/carousel-[sujet]-[date].html` avec :
- Structure : 6 divs `.slide` de 1080×1350px
- CSS `page-break-after: always` sur chaque slide
- `@page { size: 1080px 1350px; margin: 0; }`
- Référencer le fichier HTML existant `.tmp/carousel-brief-2026-03-09.html` comme modèle de design

### Step 3 — Générer le PDF
```powershell
powershell.exe -ExecutionPolicy Bypass -File tools/generate_carousel_pdf.ps1 -HtmlFile ".tmp/carousel-[nom].html" -OutputPdf ".tmp/carousel-[nom].pdf"
```

### Step 4 — Vérification visuelle
Ouvrir le PDF et demander confirmation avant publication.

### Step 5 — Publier sur LinkedIn
Utiliser `tools/post_linkedin_document.ps1` (à créer si absent) pour uploader le PDF et créer le post document LinkedIn.

Le texte d'accompagnement du post doit :
- Mentionner la semaine ou le sujet
- Préciser que c'est automatique
- Appeler à commenter / suivre

---

## Règles de contenu

- **Pas d'em dash (—)** dans les slides : utiliser " - " ou ":"
- **Accents corrects** : toujours (é, è, à, ù, î, ô, û, ç, etc.)
- **Max 3 points par slide** : éviter la surcharge
- **Chiffres en gros** : si un chiffre est là, le rendre visible
- **Cover accrocheur** : une phrase courte, pas un titre générique

---

## Fichiers clés

- Template design : `.tmp/carousel-brief-2026-03-09.html`
- Tool génération PDF : `tools/generate_carousel_pdf.ps1`
- Tool publication document LinkedIn : `tools/post_linkedin_document.ps1`
