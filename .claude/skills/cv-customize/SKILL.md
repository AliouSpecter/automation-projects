---
name: cv-customize
description: Use when the user wants to customize their CV or application message for a job offer. Triggers on /cv-customize or when user provides a job posting URL/text and asks to adapt their CV, application, or candidature message.
disable-model-invocation: true
argument-hint: "URL de l'offre ou texte collé"
---

# Skill: customize-cv

## Purpose
Personnaliser le CV et rédiger le message de candidature pour une offre d'emploi spécifique.
Output : un Google Doc contenant le CV adapté (titre, accroche, missions, outils) + le message de candidature.

---

## Step 1 — Obtenir l'offre d'emploi

Si l'argument contient une URL :
```powershell
powershell.exe -ExecutionPolicy Bypass -File "tools/scrape_job_offer.ps1" -url "[URL]"
```

Si le scraping échoue (LinkedIn, page protégée) ou si l'utilisateur a collé le texte directement : utiliser le texte fourni.

Si aucune offre n'est fournie, demander via AskUserQuestion :
- Option 1 : "Je colle le texte de l'offre"
- Option 2 : "J'ai une URL"

---

## Step 2 — Lire les fichiers source

Lire systématiquement les deux fichiers avant de continuer :
- `cv/base_cv.yaml` — données du CV
- `cv/profiles.yaml` — logique de profils

Lire également `workflows/customize_cv.md` pour les règles détaillées.

---

## Step 3 — Analyser l'offre et choisir le profil

Analyser le texte de l'offre :
- Poste exact, entreprise, secteur
- Compétences requises, missions décrites
- Mots-clés de profil (paid / traffic / growth)

Appliquer la logique de `workflows/customize_cv.md` (Étape 3) pour choisir parmi :
- `traffic_manager` (défaut)
- `paid_acquisition`
- `growth_manager`

**Toujours annoncer le profil choisi à l'utilisateur et justifier en 1 phrase avant de continuer.**

Exemple : "Profil retenu : Paid Acquisition Specialist — l'offre mentionne explicitement 'ROAS', 'CPA cible' et 'paid social'."

Si le signal est faible ou ambigu, préciser : "Profil retenu : Traffic Manager (par défaut — signal ambiguë)."

---

## Step 4 — Générer le contenu customisé

Suivre les règles de `workflows/customize_cv.md` (Étape 4) :

1. **Titre** : titre exact du profil sélectionné (adapté si l'offre utilise une variante précise)
2. **Tagline** : partir du profil, affiner selon secteur/contexte (3-5 mots max)
3. **Missions** : sélectionner par tags profil + priority threshold, adapter le wording si pertinent
4. **Compétences** : filtrer par highlight_skills du profil, réordonner selon l'offre

Le message de candidature est généré séparément (pas inclus dans le PDF du CV).

---

## Step 5 — Construire le fichier HTML

Lire `cv/template.html` (design de référence validé) puis générer `.tmp/cv_content.html` en remplaçant les zones marquées `<!-- ZONE: ... -->`.

Suivre toutes les règles d'encodage et de mise en page définies dans `workflows/customize_cv.md` (Étape 5).

**Points clés :**
- Tous les accents encodés en HTML entities (é=`&#233;` à=`&#224;` etc.) — voir liste complète dans le workflow
- Apostrophes → `&#8217;` | tirets → `&#8211;` | espace insécable → `&nbsp;`
- Tagline : utiliser `&nbsp;` + `&#8209;` pour empêcher les coupures indésirables (ex: `créative&nbsp;multi&#8209;canal`)
- Bulles : 6 normales en grille 3×2 + 1 centrée (`class="bub bub-center bt"`) — 7 max
- Expériences : blocs `.exp` dans `.exps` (justify-content:space-between — ne pas ajouter de margin-bottom)
- Ne pas modifier le CSS du template

**Si le PDF déborde sur 2 pages :** réduire `zoom` de 0.01 et augmenter `height` de ~4mm dans le HTML (ex: zoom 0.86→0.85, height 344mm→348mm).

Utiliser l'outil Write pour créer le fichier.

---

## Step 6 — Générer le PDF

```powershell
powershell.exe -ExecutionPolicy Bypass -File "tools/generate_cv_pdf.ps1" `
  -htmlFile ".tmp/cv_content.html" `
  -outputName "CV - [Titre exact de l'offre] - [Entreprise] - [AAAA-MM-JJ]"
```

Le script génère le PDF dans `cv/generated/` et retourne le chemin complet.

---

## Step 7 — Livrer à l'utilisateur

Présenter :
1. **Profil choisi** + justification
2. **Chemin du PDF** : `cv/generated/[nom].pdf`
3. **Résumé des customisations** : quelles missions incluses/exclues, adaptation notable du wording
4. **Points d'attention** si applicable (ex: signal growth faible, offre ambiguë, budget retiré car non précisé dans le CV)

Proposer les ajustements si demandés.

---

## Règles
- Toujours lire `cv/base_cv.yaml` et `cv/profiles.yaml` avant de générer quoi que ce soit
- Ne jamais inventer des compétences ou chiffres absents du CV maître
- Si une mission adapte le wording, rester fidèle au sens — ne pas exagérer
- Profil par défaut = `traffic_manager` (meilleur taux de retour)
- `growth_manager` uniquement si l'offre montre clairement un environnement cross-fonctionnel (produit, rétention, CRO)
- Message de candidature : 100-150 mots, 1 détail spécifique entreprise, jamais "Je suis très motivé"
- Message de candidature : rédigé séparément en texte, pas dans le PDF
- Jamais de tiret long (—) dans le contenu

---

## Notes
- v1.2 — design validé le 2026-03-06, référencé dans `cv/template.html`
- Output : `cv/generated/CV - [Titre] - [Entreprise] - [date].pdf`
- Le message de candidature est présenté en texte markdown dans la réponse, pas intégré au CV
