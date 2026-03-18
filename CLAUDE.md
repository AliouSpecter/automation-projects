# Agent Instructions

WAT framework (Workflows, Agents, Tools) : l'IA orchestre, les scripts exécutent.

## WAT Framework
- **Workflows** (`workflows/`) — Markdown SOPs : objectif, inputs, outils, outputs, edge cases. Lire avant d'agir.
- **Agents** (ton rôle) — lire le workflow, exécuter les outils dans l'ordre, gérer les erreurs, demander si ambigu
- **Tools** (`tools/`) — scripts PowerShell pour l'exécution déterministe ; credentials dans `.env`

## How to Operate

**1. Look for existing tools first**
Before building anything new, check `tools/` based on what your workflow requires. Only create new scripts when nothing exists for that task.

**2. Learn and adapt when things fail**
When you hit an error:
- Read the full error message and trace
- Fix the script and retest (if it uses paid API calls or credits, check with me before running again)
- Document what you learned in the workflow (rate limits, timing quirks, unexpected behavior)
- Example: You get rate-limited on an API, so you dig into the docs, discover a batch endpoint, refactor the tool to use it, verify it works, then update the workflow so this never happens again

**3. Keep workflows current**
Workflows should evolve as you learn. When you find better methods, discover constraints, or encounter recurring issues, update the workflow. That said, don't create or overwrite workflows without asking unless I explicitly tell you to. These are your instructions and need to be preserved and refined, not tossed after one use.

## File Structure
```
.tmp/           # Temporaires — régénérables, tout est jetable
tools/          # Scripts PowerShell — exécution déterministe
workflows/      # Markdown SOPs
.env            # Secrets (UNIQUEMENT ici)
```
Deliverables → cloud (Google Sheets/Slides/Drive). Local = traitement uniquement.

## Communication Rules

**Flag contradictions immediately**
If something in a new instruction contradicts a previous one (within the same session or vs. established workflow), point it out before executing. Ask for clarification rather than choosing one interpretation silently. Example: "Ca contredit ce que tu m'as dit plus tot sur X - tu peux preciser ?"

**French content: always use proper accents**
All content written in French must include correct accents (é, è, ê, à, ù, î, ô, û, ç, etc.). Never strip accents from French text, whether in HTML, scripts, or any other file. This applies to all content — page copy, labels, notes, comments.

## Context Management
- Préférer Grep/Glob à Read pour localiser du code — éviter de lire des fichiers entiers inutilement
- MEMORY.md doit rester sous 200 lignes — supprimer les entrées obsolètes régulièrement

## Nouveau chat — quand le suggérer
Proposer d'ouvrir un nouveau chat dans ces situations :
- Tâche principale terminée (workflow déployé, post publié, script finalisé)
- Contexte estimé à ~75% de saturation (nombreux échanges, gros fichiers lus, outputs longs)
Formulation : "Cette tâche commence à être saturée. Tu veux qu'on ouvre un nouveau chat pour la suite ?"

## Bottom Line

You sit between what I want (workflows) and what actually gets done (tools). Your job is to read instructions, make smart decisions, call the right tools, recover from errors, and keep improving the system as you go.

Stay pragmatic. Stay reliable. Keep learning.
