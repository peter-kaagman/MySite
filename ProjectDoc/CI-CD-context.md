# MySite CI/CD & Kubernetes Deployment

## Doel van dit bestand

Dit bestand geeft context aan AI-assistenten (zoals GitHub Copilot Chat) in een andere VS Code sessie over het gewenste CI/CD-proces en het uiteindelijke doel: het automatisch bouwen, taggen en hosten van een Docker image bij een release commit, en het uitrollen naar Kubernetes.

---

## Gewenste workflow

1. **Release commit:**
   - Bij het aanmaken van een nieuwe release (tag, bijvoorbeeld `v1.2.3`) in de GitHub repository van MySite, moet GitHub Actions automatisch een Docker image bouwen.

2. **Image tagging:**
   - Het image moet worden getagd als zowel `:v1.2.3` als `:latest`.

3. **Image hosting:**
   - Het image moet worden gepusht naar de GitHub Container Registry (ghcr.io), bijvoorbeeld: `ghcr.io/<github-username>/mysite:v1.2.3` en `ghcr.io/<github-username>/mysite:latest`.

4. **Kubernetes deployment:**
   - Het uiteindelijke doel is om deze images te gebruiken in een Kubernetes cluster.
   - De deployment.yaml in deze map moet verwijzen naar het juiste image (bijvoorbeeld `ghcr.io/<github-username>/mysite:latest` of een specifieke versie).
   - Het updaten van de deployment gebeurt voorlopig handmatig (rollout restart), maar kan later geautomatiseerd worden.

---

## Toekomstige uitbreidingen

- Automatisch uitrollen naar Kubernetes na een succesvolle build (bijvoorbeeld via kubectl in GitHub Actions, webhook, of GitOps-tool).
- Versiebeheer en rollback via image tags.
- Secrets en configuratiebeheer via Kubernetes Secrets/ConfigMaps.

---

## Samenvatting

- Bij elke release commit/tag moet er automatisch een Docker image gebouwd en gepusht worden naar de GitHub Container Registry, met de juiste tags.
- Het image wordt vervolgens gebruikt in de Kubernetes deployment.
- Deze workflow is een basis voor een moderne, geautomatiseerde DevOps pipeline.

---

*Laat dit bestand staan voor context in toekomstige AI-sessies!*
