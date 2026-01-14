# Kubernetes Deployment voor MySite

## Vereisten

- Kubernetes cluster (1.24+)
- kubectl geconfigureerd
- Docker voor image builds
- Ingress controller (nginx-ingress)
- cert-manager voor TLS certificates (optioneel)

## Snelle start

### 1. Build en push Docker image

```bash
# Build lokaal
docker build -t mysite:latest .

# Tag voor registry
docker tag mysite:latest ghcr.io/peter-kaagman/mysite:latest

# Push naar registry
docker push ghcr.io/peter-kaagman/mysite:latest
```

### 2. Update secrets

**Belangrijk:** Verander de dummy waarden in `k8s/secret.yaml`:

```bash
# Genereer random session secret
openssl rand -base64 32

# Update secret.yaml met echte waarden
```

### 3. Deploy naar Kubernetes

```bash
# Maak namespace
kubectl apply -f k8s/namespace.yaml

# Deploy configuratie
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml

# Deploy applicatie
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml

# Optioneel: autoscaling en network policies
kubectl apply -f k8s/hpa.yaml
kubectl apply -f k8s/networkpolicy.yaml
```

### 4. Verifieer deployment

```bash
# Check pods
kubectl get pods -n mysite-prod

# Check logs
kubectl logs -f deployment/mysite -n mysite-prod

# Check service
kubectl get svc -n mysite-prod

# Check ingress
kubectl get ingress -n mysite-prod
```

## Productie overwegingen

### Database

De huidige setup gebruikt SQLite, wat **niet geschikt is voor productie** met meerdere replicas. Overweeg:

- **PostgreSQL** of **MySQL** met externe/managed service
- Update `configmap.yaml` met database connectie details
- Voeg database credentials toe aan `secret.yaml`
- Implementeer database migraties via initContainer

### TLS Certificates

Voor automatische TLS certificates met Let's Encrypt:

```bash
# Installeer cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Maak ClusterIssuer
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: jouw-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

### Monitoring

Voeg monitoring toe met Prometheus en Grafana:

```bash
# Installeer Prometheus stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
```

### Sessie persistentie

Voor sessie persistentie over pod restarts:

1. Maak PersistentVolumeClaim:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysite-sessions-pvc
  namespace: mysite-prod
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
```

2. Uncomment de PVC volume mount in `deployment.yaml`

### Secrets beheer

Voor productie, gebruik een van:

- **Sealed Secrets**: Encrypt secrets in git
- **External Secrets Operator**: Sync van externe vaults
- **HashiCorp Vault**: Centrale secret management
- **Cloud provider secrets**: AWS/Azure/GCP secret managers

## Updates en rollbacks

### Rolling update

```bash
# Update image tag in deployment.yaml
kubectl set image deployment/mysite mysite=ghcr.io/peter-kaagman/mysite:v2 -n mysite-prod

# Monitor rollout
kubectl rollout status deployment/mysite -n mysite-prod
```

### Rollback

```bash
# Rollback naar vorige versie
kubectl rollout undo deployment/mysite -n mysite-prod

# Rollback naar specifieke revisie
kubectl rollout history deployment/mysite -n mysite-prod
kubectl rollout undo deployment/mysite --to-revision=2 -n mysite-prod
```

## Troubleshooting

```bash
# Pod logs
kubectl logs -f deployment/mysite -n mysite-prod

# Describe pod voor events
kubectl describe pod <pod-name> -n mysite-prod

# Port forward voor lokaal testen
kubectl port-forward svc/mysite 8080:80 -n mysite-prod

# Exec into pod
kubectl exec -it <pod-name> -n mysite-prod -- /bin/bash

# Check resource usage
kubectl top pods -n mysite-prod
kubectl top nodes
```

## CI/CD

GitHub Actions workflow is beschikbaar in `.github/workflows/deploy.yml`.

Vereiste secrets in GitHub repository:
- `KUBE_CONFIG`: Base64 encoded kubeconfig file

```bash
# Genereer kubeconfig secret
cat ~/.kube/config | base64 | pbcopy
# Plak in GitHub Secrets als KUBE_CONFIG
```

## Cleanup

```bash
# Verwijder alles
kubectl delete namespace mysite-prod
```
