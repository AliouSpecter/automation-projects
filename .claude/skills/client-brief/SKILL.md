# Skill: client-brief

## Purpose
Analyse la stack technique d'un client et identifie les opportunités d'automatisation prioritaires, selon la méthodologie Automation Act : ROI-first, zéro outil ajouté, branché sur l'existant.

## Trigger
Utilisé quand l'utilisateur dit "analyse cette stack" / "diagnostic client" / "automation-diagnose" ou partage des infos sur les outils et processus d'un prospect.

---

## Process

### Step 1 — Collecter le contexte client
Si l'utilisateur n'a pas fourni les infos, demander :
- **Secteur / type d'activité**
- **Stack existante** (CRM, ERP, outils métier, communication, fichiers)
- **Volume** : taille d'équipe, nombre de transactions/mois si connu
- **Douleurs exprimées** : ce qui prend trop de temps, ce qui génère des erreurs
- **Objectif business** du client (croissance, réduction coûts, scaling)

Si les infos sont partiellement disponibles, travailler avec ce qu'on a et signaler les gaps.

### Step 2 — Cartographier la stack
Organiser les outils en catégories :
- **Source de données** (CRM, formulaires, emails, sheets)
- **Traitement / métier** (ERP, outils sectoriels, bases internes)
- **Communication** (email, Slack, Teams, Telegram)
- **Output** (rapports, dashboards, notifications, facturation)

Identifier les **connecteurs natifs disponibles** (n8n, Make, Zapier nodes) pour chaque outil.

### Step 3 — Identifier les flux automatisables
Pour chaque flux candidat, évaluer :
| Critère | Question |
|---------|----------|
| **Fréquence** | Quotidien / hebdo / mensuel ? |
| **Volume** | Combien d'occurrences / mois ? |
| **Complexité** | Règles simples ou logique métier complexe ? |
| **Connecteurs** | API ou webhooks disponibles ? |
| **ROI estimé** | Temps gagné × fréquence × coût horaire |

### Step 4 — Prioriser
Classer les opportunités en 3 niveaux :

**Niveau 1 — Quick wins (< 2 semaines)**
- Flux répétitifs, outils connectés, règles simples
- ROI visible en moins d'1 mois

**Niveau 2 — Impact moyen (2-6 semaines)**
- Flux multi-étapes ou avec transformation de données
- Nécessite paramétrage mais pas de développement custom

**Niveau 3 — Projets structurants (> 6 semaines)**
- Intégrations profondes ou logique conditionnelle complexe
- À planifier après validation des quick wins

### Step 5 — Livrable diagnostic
Sauvegarder le livrable dans `.tmp/diagnostics/[nom-client].md` et indiquer le chemin à l'utilisateur.

Produire un résumé structuré avec :
1. **Stack cartographiée** (tableau lisible)
2. **Top 3 opportunités** avec ROI estimé et niveau d'effort
3. **Recommandation immédiate** : par quoi commencer et pourquoi
4. **Questions ouvertes** : ce qu'il faut clarifier avant de démarrer

---

## Format de sortie

```
## Diagnostic Automation — [Nom client ou secteur]

### Stack identifiée
| Catégorie | Outils | Connecteurs dispo |
|-----------|--------|------------------|
| ...       | ...    | ...              |

### Top opportunités
1. **[Flux]** — [description courte]
   - Fréquence : X/mois
   - Gain estimé : X h/mois
   - Effort : Niveau 1 / Quick win

2. ...

3. ...

### Recommandation immédiate
[Par quoi commencer, pourquoi, timeline estimée]

### Points à clarifier
- ...
```

---

## Principes Automation Act à respecter
- **Zéro outil ajouté** : utiliser ce que le client a déjà
- **ROI avant tout** : chaque automatisation doit avoir un gain mesurable
- **Premiers résultats dès J+14** : commencer par les quick wins
- **Pas de sur-ingénierie** : la solution la plus simple qui fonctionne

---

## Notes
- Draft v0.1 — à enrichir avec des vrais cas clients
- Ajouter des exemples de diagnostics réels quand disponibles
- Enrichir la liste des connecteurs n8n par secteur (immobilier, retail, B2B SaaS...)
