---
name: feedback_workflow_activation
description: Ne jamais activer un workflow n8n sans demande explicite de l'utilisateur
type: feedback
---

Ne jamais activer (ni désactiver) un workflow n8n via l'API sans demande explicite.

**Why:** L'utilisateur veut contrôler lui-même l'activation — un workflow actif peut déclencher des appels API payants ou des actions irréversibles à tout moment.

**How to apply:** Après déploiement (PUT), s'arrêter et dire "Le workflow est déployé. Tu veux l'activer ?"
