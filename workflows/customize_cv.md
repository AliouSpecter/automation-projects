# Workflow : Personnalisation CV & Message de Candidature

## Objectif
Personnaliser le CV et rédiger un message de candidature adapté à une offre d'emploi spécifique.
Output : un Google Doc contenant le CV customisé + le message de candidature.

## Inputs requis
- Offre d'emploi : texte collé OU URL (Welcome to the Jungle, LinkedIn Jobs, Indeed, page carrière)
- Optionnel : entreprise cible, préférences de ton (formel / décontracté)

## Prérequis Google
Avant la première utilisation, s'assurer que :
1. `.env` contient `GOOGLE_CLIENT_ID` et `GOOGLE_CLIENT_SECRET`
2. Le token Google est valide (`GOOGLE_ACCESS_TOKEN` dans `.env`)
3. Si absent ou expiré : exécuter `tools/google_auth.ps1`

---

## Étape 1 — Obtenir le texte de l'offre

**Si URL fournie :**
```powershell
powershell.exe -ExecutionPolicy Bypass -File "tools/scrape_job_offer.ps1" -url "URL_ICI"
```
Capturer l'output. Si l'URL est inaccessible (LinkedIn nécessite auth), demander à l'utilisateur de coller le texte manuellement.

**Si texte fourni :** utiliser directement.

---

## Étape 2 — Analyser l'offre

Lire le texte de l'offre et extraire :
- **Poste exact** (titre du poste)
- **Entreprise** (nom, secteur, taille si mentionnée)
- **Compétences requises** (mots-clés techniques)
- **Missions principales** décrites dans l'offre
- **Culture / environnement** (startup, grand groupe, remote, produit, B2B/B2C...)
- **Signaux de profil** : mots-clés paid, growth, traffic

---

## Étape 2b — Évaluer le fit avant de continuer

**Priorité de profil (du plus fort au plus faible taux de retour) :**
1. `paid_acquisition` — sweet spot principal
2. `traffic_manager` — fort taux de retour
3. `digital_marketing_manager` — candidatable si paid est présent
4. `growth_manager` — uniquement si l'automatisation IA est centrale dans l'offre

**Seuils NO-GO — déconseiller explicitement de candidater si :**
- L'offre mentionne explicitement **"peu de paid"** ou **"pas de paid"** comme mode principal d'acquisition
- Le contexte est **radicalement absent du CV** : creator economy, product-led growth pur, RevOps pur sans HubSpot/paid, programmatic (DV360, TTD), SEM agence avec SA 360 obligatoire
- **2 compétences clés structurelles** sont absentes (pas juste des outils, mais des dimensions entières du rôle)
- L'offre cible un secteur très spécifique (finance, legal, médical) avec expertise métier requise que le CV ne couvre pas

**Seuils NUANCE — candidater avec mise en garde si :**
- 1 outil clé manquant (SA 360, Yotpo, Simio...) → assumable en entretien
- Contexte légèrement différent (annonceur vs agence, B2B vs B2C) → compensable

**Format de l'alerte NO-GO :**
> ❌ Je déconseille cette candidature. [Raison en 1-2 phrases]. Tu as de meilleures chances sur des offres paid media directes.

Ne pas générer le CV si NO-GO, sauf si l'utilisateur confirme vouloir quand même postuler.

---

## Étape 3 — Choisir le profil

Lire `cv/profiles.yaml` pour la logique complète. Règles de décision :

| Signaux dans l'offre | Profil choisi |
|---|---|
| "paid acquisition", "paid media", "media buyer", "ROAS", "CPA", "SMA", "paid social", "EMEA" | `paid_acquisition` |
| "traffic manager", "traffic", "trafic", "SEA", "campagnes digitales", "acquisition payante", "responsable SEA" | `traffic_manager` |
| "growth manager", "CRO", "rétention", "expérimentation", "funnel", "product-led", "ABM", "MQL/SQL", "nurturing" | `growth_manager` |
| "digital marketing manager", "responsable marketing", "chef de projet digital", titre généraliste | `digital_marketing_manager` |
| Signal ambigu ou mélangé | `traffic_manager` (meilleur taux de retour par défaut) |
| **Offre en anglais** | Utiliser `english_profiles` dans profiles.yaml (même logique, titres EN) |

**Règle pour `growth_manager` :** n'utiliser que si l'offre mentionne clairement des dimensions hors paid (rétention, produit, lifecycle, CRO, pipeline sales). Si le signal growth est faible, préférer `traffic_manager` et le signaler à l'utilisateur.

**Offres en anglais :** adapter le titre, le contenu ET le message de candidature en anglais. Utiliser les champs `.en` de `cv/base_cv.yaml` pour les missions.

---

## Étape 4 — Générer le contenu customisé

Lire `cv/base_cv.yaml` et construire le contenu personnalisé :

### 4a. Titre du poste
**Règle par défaut : utiliser le titre exact de l'offre d'emploi.**
Ne jamais substituer un titre générique du profil si l'offre donne un titre précis.
Exemple : l'offre dit "Responsable Paid Media EMEA" → titre du CV = "Responsable Paid Media EMEA".
Exception : si le titre de l'offre est très inhabituel ou potentiellement négatif pour le profil, signaler à l'utilisateur et proposer une adaptation.

### 4b. Tagline / Accroche courte
Partir de `.tagline` dans `cv/profiles.yaml`, puis l'affiner selon le secteur/contexte de l'entreprise (3-5 mots ajoutés max).

### 4c. Sélection des missions
Pour chaque expérience dans `cv/base_cv.yaml` :
1. Sélectionner les missions dont `profiles` inclut au moins un tag du profil cible
2. Filtrer par `priority` selon `mission_priority_threshold` du profil
3. Trier par pertinence (priorité 1 d'abord, puis 2, puis 3)
4. Adapter légèrement le wording si nécessaire pour coller à la terminologie de l'offre (sans inventer des compétences)

### 4d. Compétences & Outils
Sélectionner les catégories de skills selon `highlight_skills` du profil.
Réordonner les items pour mettre en avant ce que l'offre mentionne en premier.

### 4e. Abréviations pour éviter les coupures de ligne
Si une mission dépasse ~80 caractères, utiliser les abréviations courantes pour la tenir sur 1 ligne :
- landing page(s) → LP
- coût par lead → CPL | coût par acquisition → CPA | coût par clic → CPC
- mots-clés → MC (si le contexte est clair)
- conversion rate optimization → CRO (déjà courant)
Objectif : chaque mission tient sur 1 ligne dans la colonne droite. Pas d'abréviation si elle nuit à la lisibilité.

### 4f. Message de candidature
Format : email ou InMail LinkedIn (demander si pas précisé).

**Ton : simple, clair, direct. Pas de formules de politesse à l'ancienne.**

Structure :
- Ligne d'objet : "Candidature [Titre exact de l'offre] - [Prénom Nom]"
- Bloc 1 (pourquoi cette entreprise + fit) : 1-2 phrases spécifiques sur le poste/contexte, en lien avec le profil
- Bloc 2 (expérience + chiffres) : résultats concrets, années d'expérience pertinentes, focus métier
- Bloc 3 (différenciateur IA) : agents IA appliqués au paid media / SEO / GEO, accélération exécution et tests
- Bloc 4 (nuance si besoin) : si une compétence est moins récente mais réelle, l'assumer directement
- CTA discret : "Disponible pour en discuter"
- Longueur : 120-160 mots

**Modèle de référence (à adapter, pas à copier) :**
> Je souhaite rejoindre [Entreprise] car le poste correspond directement à mon profil [axe clé], dans un contexte [early-stage / B2B / croissance] où l'impact est immédiat.
> J'ai [X] ans d'expérience en marketing digital, avec un fort focus sur [axe principal] (-30% CPL, +20% ventes, +30% demandes de démo).
> En parallèle de mes missions, je développe des agents IA appliqués au paid media et au SEO/GEO (optimisation des campagnes, analyse de performance, génération de contenus), ce qui permet d'accélérer l'exécution et de tester plus vite à coût maîtrisé.
> [Si lacune : l'assumer directement avec contexte passé.]
> Disponible pour en discuter.

**Règles du message :**
- Jamais "Je suis très motivé par votre entreprise"
- Jamais de tiret long (-) ni de tiret cadratin (—) : remplacer par ":", "," ou reformuler. Vaut pour le CV ET la lettre de motivation.
- Pas de sur-affirmation : éviter "exactly", "precisely", "perfectly", "c'est exactement" — dire les choses simplement sans forcer l'enthousiasme
- Toujours 1 détail spécifique à l'entreprise (produit, secteur, stade, problème)
- Assumer les lacunes directement plutôt que les esquiver
- Quand "Automation Act" est mentionné dans la lettre, toujours inclure le lien : https://www.automationact.com
- Si offre en anglais : rédiger le message en anglais
- Utiliser les expériences secondaires (D-egde, Sama Event, E-calebass) quand elles apportent une connexion sectorielle ou contextuelle pertinente. Exemples :
  - Offre dans le secteur hôtelier / voyage → mentionner D-egde (agence web B2B, clients hôteliers)
  - Offre événementielle / B2C communauté → mentionner Sama Event (start-up évènementielle)
  - Offre e-commerce / web → mentionner E-calebass (optimisation sites, UX, conversion)

---

## Étape 5 — Construire le HTML du CV

**Template de référence : `cv/template.html`**

Lire `cv/template.html` et générer `.tmp/cv_content.html` en remplaçant les zones marquées `<!-- ZONE: ... -->`.

### Règles de remplissage

**Encodage obligatoire** (PS5 + Edge headless = pas de charset natif) :
- Accents → HTML entities : é=`&#233;` è=`&#232;` ê=`&#234;` à=`&#224;` â=`&#226;` î=`&#238;` ô=`&#244;` û=`&#251;` ç=`&#231;` ù=`&#249;` œ=`&#339;`
- Apostrophe typographique → `&#8217;`
- Tiret demi-cadratin → `&#8211;`
- Espace insécable → `&nbsp;`
- Tiret non-sécable → `&#8209;` (ex: `multi&#8209;canal`)
- `>` → `&gt;` | `<` → `&lt;` | `&` → `&amp;` | `€` → `&#8364;`

**ZONE: TITRE_POSTE** — Titre exact de l'offre (règle étape 4a)

**ZONE: INTRO** — 3 lignes séparées par `<br>` :
1. Accroche séniorité (champ `accroches` de `base_cv.yaml` selon profil)
2. `<strong>Tagline bold</strong>` — adapter selon offre ; utiliser `&nbsp;` pour empêcher la coupure entre mots liés (ex: `créative&nbsp;multi&#8209;canal`)
3. Ligne différenciateur IA

**ZONE: COMPETENCES** — 3 catégories avec `<span class="skill-cat">` :
- Sélectionner selon `highlight_skills` du profil
- 3-4 items par catégorie, étoiles : `&#9733;` (pleine) `&#9734;` (vide)
- Réordonner pour mettre en avant les compétences mentionnées dans l'offre

**ZONE: BUBBLES** — 7 outils max :
- 6 bulles normales en grille 3×2, alterner `.by` (jaune) et `.bt` (teal)
- 1 bulle supplémentaire avec `class="bub bub-center bt"` (centrée en 3e ligne)
- Sélectionner selon `tools_highlight` du profil dans `profiles.yaml`

**ZONE: EXPERIENCES** — Blocs `.exp` dans l'ordre anté-chronologique :
```html
<div class="exp">
  <div class="exp-title">TITRE_TENU</div>
  <div class="exp-co">Entreprise (Secteur) | Période</div>
  <ul>
    <li>Mission 1</li>
    <li>Mission 2</li>
  </ul>
  <div class="exp-res">=> Résultats : CHIFFRE1 | CHIFFRE2</div>
</div>
```
Nombre de missions cible par expérience : DiliTrust 4-5 | Freelance 3-4 | SOS SAHEL 3 | D-egde 2 | Sama Event 2 (sans `.exp-res`)

**Mise en page :** Ne pas modifier le CSS. Si le contenu déborde sur 2 pages au PDF, réduire `zoom` de 0.01 et augmenter `height` de ~4mm (ex: 0.86→0.85, 344mm→348mm).

Sauvegarder dans `.tmp/cv_content.html`.

---

## Étape 6 — Générer le PDF

```powershell
powershell.exe -ExecutionPolicy Bypass -File "tools/generate_cv_pdf.ps1" `
  -htmlFile ".tmp/cv_content.html" `
  -outputName "CV - [Titre exact offre] - [Entreprise] - [AAAA-MM-JJ]"
```

Le script génère le PDF dans `cv/generated/` et retourne le chemin complet.

---

## Étape 7 — Valider et livrer

Présenter à l'utilisateur :
1. **Profil choisi** et justification (pourquoi ce profil vs les autres)
2. **Chemin du PDF** généré dans `cv/generated/`
3. **Points d'attention** : si missions adaptées, si ton modifié, si signal growth faible, etc.

Proposer les ajustements si demandés (changer profil, adapter mission, reformuler message).

---

## Edge cases

**Offre en anglais**
→ CV entièrement en anglais (titre, sections, missions, compétences, formations, langues)
→ Utiliser les champs `.en` de `cv/base_cv.yaml` pour les missions
→ Rédiger le message de candidature en anglais
→ Sections : "Key skills" | "My tools" | "Education" | "Languages" | "Experience" | "Other activities"

**Offre très généraliste ("Digital Marketing Manager")**
→ Par défaut : `traffic_manager`
→ Analyser la culture de l'entreprise pour affiner

**Startup early-stage**
→ Mettre en avant la polyvalence et l'autonomie (missions priority 3 éligibles)
→ Alléger les formulations formelles dans le message

**Grand groupe / ESN**
→ Formulation plus structurée
→ Mettre en avant les KPI et reportings

**Offre avec budget non précisé**
→ Ne pas inventer de chiffres — garder la mission mais retirer le budget spécifique
→ Reformuler : "campagnes Google Ads multi-format" sans chiffrer si la donnée n'est pas dans le CV

**Poste déjà postulé**
→ Vérifier si une version précédente existe dans `.tmp/`
→ Créer une nouvelle version avec date dans le nom du doc

---

## Notes sur les données CV (Aliou BA)
- **Expérience revendiquée** : 8-10 ans marketing digital, +6 ans paid media, budgets >1.5M€/an
- **Poste actuel** : Paid acquisition manager @ DiliTrust (Legal Tech SaaS B2B) depuis sept. 2024
- **Point fort** : paid media multi-canal, B2B international (4 continents), agents IA
- **Point faible pour growth** : pas d'expérience en environnement product-led pur — compenser avec missions ABM/pipeline/HubSpot de DiliTrust
- **Langue** : CV en anglais si l'offre est en anglais. CV en français sinon.

## Fichiers lus par ce workflow
- `cv/base_cv.yaml` — source de vérité du CV (Aliou BA, données réelles)
- `cv/profiles.yaml` — logique de profil (4 profils FR + 3 profils EN)

## Outils exécutés
- `tools/scrape_job_offer.ps1` — si URL fournie
- `tools/generate_cv_pdf.ps1` — génération PDF via Edge headless (aucune API, local)
