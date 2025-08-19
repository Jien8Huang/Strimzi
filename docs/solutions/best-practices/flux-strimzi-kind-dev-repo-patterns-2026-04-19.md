---
title: "Flux + Strimzi on kind: repo layout, ordering, and review pitfalls"
date: 2026-04-19
category: best-practices
module: kubernetes-gitops
problem_type: best_practice
component: tooling
severity: medium
applies_when:
  - Bootstrapping a small GitOps repo that installs Strimzi via Flux Helm and applies Kafka CRs on kind (or similar local clusters).
  - Running code review workflows on a repository that has not yet produced an initial commit (all paths untracked).
tags:
  - fluxcd
  - strimzi
  - gitops
  - kind
  - helmrelease
  - kustomization
---

# Flux + Strimzi on kind: repo layout, ordering, and review pitfalls

## Context

This repository was pivoted from a portfolio-style stub toward a **Flux-first** layout: `clusters/dev` as the Flux entrypoint, `infrastructure/` for the Strimzi operator (`HelmRepository` + `HelmRelease`), and `apps/kafka-dev/` for Strimzi `Kafka` / `KafkaNodePool` resources targeting **kind**. Along the way, two classes of friction showed up repeatedly:

1. **Reconciliation ordering** between a Helm-installed operator (CRDs) and **downstream** Strimzi CRs applied by a second Flux `Kustomization`.
2. **Review and CI scope** when Git has **no commits** yet (everything is untracked), plus small but sharp mismatches between **Helm chart contracts** and assumed values.

## Guidance

### Lock a single Flux bootstrap contract

Pick one story and document it in the runbook:

- **Flux CLI bootstrap** installs controllers into `flux-system` and creates the linkage objects (`GitRepository`, root `Kustomization`) pointing at this repository.
- The Git repo stores **workload/platform manifests** (for example under `clusters/dev/`) and avoids duplicating upstream `flux-system` controller installs unless you intentionally manage that in Git.

This removes the “do we commit `flux-system/` placeholders?” ambiguity for contributors.

### Split Flux `Kustomization`s by layer and use explicit health gates

Use separate Flux `Kustomization` objects (for example `infrastructure` then `apps`) and wire:

- `spec.path` to `./infrastructure` and `./apps/kafka-dev` respectively.
- `spec.dependsOn` on the **apps** `Kustomization` so it waits for **infrastructure** to reconcile first.

That alone is not always sufficient: the infrastructure `Kustomization` can become “Ready” before Helm has fully rolled the operator **and** registered CRDs in a way your cluster timing accepts. Add **`spec.healthChecks`** on the infrastructure `Kustomization` targeting the operator’s `HelmRelease`:

```yaml
spec:
  healthChecks:
    - apiVersion: helm.toolkit.fluxcd.io/v2beta2
      kind: HelmRelease
      name: strimzi-kafka-operator
      namespace: flux-system
```

Also give the infrastructure layer enough `timeout` budget for chart pulls on slower networks.

### Pin Helm charts and verify Helm values against the chart’s `values.yaml`

Strimzi’s operator chart exposes knobs like `watchAnyNamespace`. **Do not assume** a value key exists because it “sounds right”: open the chart version’s `values.yaml` for the pinned tag (for example `0.44.0`) and confirm spelling and defaults.

### Make local smoke scripts fail loudly on the wrong kube context

`kubectl` commands are easy to run against the wrong cluster. A practical pattern:

- Fail fast if `kubectl cluster-info` cannot reach an API server.
- Optionally require `EXPECTED_KUBE_CONTEXT` to match `kubectl config current-context` when running destructive or long-wait smoke checks.

### Align CI `kustomize` with what developers use

If developers commonly use `kubectl kustomize` (embedded kustomize), pin CI’s `kustomize` to a **close major/minor** to reduce “passes locally, fails in CI” drift.

### Document external chart index fragility

If `HelmRepository` points at a public HTTP index, transient outages show up as Flux source errors. Document the symptom (Flux `HelmRepository` / `HelmRelease` status) and the operational responses (retry, mirror, pin to a more stable source), rather than treating it as an application bug.

## Why This Matters

- **Ordering bugs** in GitOps often look like “Kubernetes is flaky” when they are actually **missing health gates** or **too-short timeouts** between layers.
- **Helm value drift** creates silent misconfigurations (ignored keys) that waste hours.
- **Untracked-only repos** break merge-base review assumptions: reviews should either wait for an initial commit or explicitly widen scope to full-tree reads.

## When to Apply

- Local **kind** (or k3d) clusters where Strimzi is installed via **Flux Helm** and Kafka is declared via **Strimzi CRs**.
- Small teams shipping a **single dev path** first (`clusters/dev`) before expanding to staging/prod overlays.

## Examples

### Infrastructure Flux `Kustomization` with HelmRelease health check

The key idea is: infrastructure readiness includes **Helm release health**, not only “objects applied”.

### Smoke script guard

```bash
if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "error: kubectl cannot reach a cluster" >&2
  exit 1
fi

if [[ -n "${EXPECTED_KUBE_CONTEXT:-}" ]] && [[ "$(kubectl config current-context 2>/dev/null || true)" != "${EXPECTED_KUBE_CONTEXT}" ]]; then
  echo "error: current kubectl context is not EXPECTED_KUBE_CONTEXT=${EXPECTED_KUBE_CONTEXT}" >&2
  exit 1
fi
```

### Review scope note (no commits yet)

If `git` has **no commits** and all work is **untracked**, diff-based review against a merge base is undefined. Stage changes (or make an initial commit) before expecting PR-style review tooling to behave normally.

## Related

- In-repo plan: `docs/plans/2026-04-19-002-feat-gitops-strimzi-cluster-repo-plan.md`
- Strimzi documentation: https://strimzi.io/documentation/
- Flux documentation: https://fluxcd.io/flux/
