# Local bootstrap (kind + Flux + Strimzi)

This document is the **ordered runbook** for v1. It matches the plan decision **Flux bootstrap v1**: Flux controllers live in `flux-system` from `flux bootstrap`, while this repository contains only cluster workload manifests starting at `./clusters/dev`.

## Prerequisites (check in this order)

1. **Container runtime**: Docker (or a Docker-compatible engine) for **kind**.
2. **`kubectl`** installed and on `PATH`.
3. **`kind`** installed.
4. **`flux` CLI** installed (Flux v2).
5. **Git + network access** to the Git hosting used by `flux bootstrap` (for example GitHub).
6. **Host resources**: a practical starting point is **4 vCPU / 8Gi RAM** available to Docker for a single-node Kafka dev topology; reduce Docker resource limits if scheduling fails.

## One-time tooling install pointers

- kind: https://kind.sigs.k8s.io/docs/user/quick-start/
- Flux CLI: https://fluxcd.io/flux/installation/
- kubectl: https://kubernetes.io/docs/tasks/tools/

## 1) Create a kind cluster

```bash
kind create cluster --name strimzi-dev
```

## 2) Bootstrap Flux against this repository

Pick a GitHub org/repo and branch that will hold **these** manifests.

```bash
export GITHUB_TOKEN=...   # token with repo permissions (do not commit)
export GITHUB_USER=...
export GITHUB_REPO=strimzi   # example
export CLUSTER_NAME=strimzi-dev

flux bootstrap github \
  --owner="${GITHUB_USER}" \
  --repository="${GITHUB_REPO}" \
  --branch=main \
  --personal \
  --path=clusters/dev
```

Notes:

- `--path=clusters/dev` must match the directory in this repository Flux should reconcile first.
- After bootstrap, Flux creates `flux-system` objects including a `GitRepository` named **`flux-system`** by default. The Flux `Kustomization` files in `clusters/dev/` reference that name.

## 3) Wait for Flux layers

```bash
kubectl -n flux-system wait kustomization/infrastructure --for=condition=Ready --timeout=15m
kubectl -n flux-system wait kustomization/apps --for=condition=Ready --timeout=20m
```

If these fail, inspect:

```bash
kubectl -n flux-system get kustomization
kubectl -n flux-system describe kustomization infrastructure
kubectl -n flux-system describe kustomization apps
```

## 4) Verify Strimzi operator

```bash
kubectl -n strimzi-system get pods
```

## 5) Verify Kafka custom resources

```bash
kubectl -n kafka-dev get kafka,kafkanodepool
kubectl -n kafka-dev describe kafka dev-cluster
```

## 6) Smoke script

From the repository root:

```bash
./hack/smoke.sh
```

Optional safety rail (recommended if you use multiple kube contexts):

```bash
export EXPECTED_KUBE_CONTEXT=kind-strimzi-dev
./hack/smoke.sh
```

## Storage on kind

This dev topology uses a **5Gi** `PersistentVolumeClaim` via `KafkaNodePool`. kind’s default `standard` `StorageClass` is typically present; if PVCs stay `Pending`, inspect:

```bash
kubectl get storageclass
kubectl -n kafka-dev get pvc
```

## Teardown

```bash
kind delete cluster --name strimzi-dev
```

## Troubleshooting cues

- **Flux `GitRepository` auth**: bootstrap failures are almost always token/permissions or wrong repo/branch.
- **Helm chart version pins**: `infrastructure/strimzi/helmrelease.yaml` pins Strimzi chart **`0.44.0`**. Bump only when you intentionally upgrade operator APIs and re-read Strimzi release notes.
- **CRD skew**: if `kubectl apply` errors mention unknown fields, your operator chart pin is likely too old or too new relative to the manifests in `apps/kafka-dev/`.
- **HelmRepository index errors**: if `https://strimzi.io/charts/` is temporarily unavailable, Flux will surface errors on the `HelmRepository`/`HelmRelease` objects; retry later or mirror the chart source internally (operational workaround, not something this repo can guarantee).
