---
name: Elementor cache — patch API vs frontend
description: Patcher _elementor_data via REST API ne met pas à jour le frontend automatiquement
type: feedback
---

Patcher uniquement `_elementor_data` via l'API REST met à jour l'éditeur Elementor mais PAS le frontend — Elementor sert le `post_content` comme cache HTML rendu.

**Why:** Elementor stocke deux choses : `_elementor_data` (structure JSON lue par l'éditeur) et `post_content` (HTML rendu, servi en frontend). L'API ne régénère pas `post_content` automatiquement.

**How to apply:**
- Après chaque fix_elementor, demander à l'utilisateur d'ouvrir l'éditeur Elementor et cliquer "Mettre à jour" pour régénérer le frontend.
- OU patcher aussi `post_content` via l'API (attention : OutOfMemoryException si le fichier HTML est trop lourd — éviter d'inclure les `<style>` inline dans le body de la requête).
- Solution la plus simple et fiable : clic "Mettre à jour" dans Elementor editor après le script.
