# sample-nodejs — GitOps Repository

Desired-state repository for the [sample-nodejs](https://github.com/MarkeyBass/sample-nodejs) app.
**Argo CD watches this repo** and keeps the Kubernetes cluster in sync with it.
No human or pipeline ever runs `kubectl apply` against the cluster for app changes.

## Structure

```
charts/sample-nodejs/   # Helm chart (Deployment, Service, Ingress, ConfigMap)
  values.yaml           # image.tag here is bumped by the app repo's CI on release
argocd/application.yaml # Argo CD Application — the one manifest applied by hand (bootstrap)
```

## The GitOps flow

```
developer push → app repo CI:
  Semgrep SAST ─ npm audit ─ build image ─ Trivy gate ─ push to Docker Hub
  └─ commits new image.tag to THIS repo
                    │
        Argo CD detects the commit
                    │
        cluster converges to the new desired state (rolling update)
```

## Why a separate GitOps repo (vs. manifests in the app repo)

- **Separation of concerns** — app history stays about code; this repo's history is a
  clean, auditable deployment log ("what ran in the cluster, when").
- **No CI trigger loops** — the CI bot commit that bumps `image.tag` lands here,
  not in the app repo, so it can never re-trigger the app pipeline.
- **Least privilege** — cluster/deploy permissions are governed by access to this
  repo, independent of who can merge application code.
- **Scales to many services/environments** — one desired-state repo can hold
  charts/values for a whole fleet and per-env value files (dev/staging/prod).

## Bootstrap (one-time)

```bash
# 1. Image pull secret for the private Docker Hub repo (use a READ-ONLY access token)
kubectl create namespace sample-app
kubectl create secret docker-registry dockerhub-creds \
  --namespace sample-app \
  --docker-username=markeybass \
  --docker-password=<READ_ONLY_ACCESS_TOKEN>

# 2. Register the app with Argo CD — the only manual apply in the whole system
kubectl apply -f argocd/application.yaml
```

## Deployment vs StatefulSet — why Deployment

The app is fully stateless: no persistent volumes, no stable network identity, no
ordered startup requirements. The in-memory Prometheus counter resetting on pod
restart is by design (counters are rate()-d in Prometheus). Stateless workloads
belong in a **Deployment**: interchangeable replicas, cheap rolling updates and
horizontal scaling. A StatefulSet would add ceremony (stable pod names, ordered
rollout) that buys nothing here.
