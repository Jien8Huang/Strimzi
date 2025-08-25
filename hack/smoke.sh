#!/usr/bin/env bash
set -euo pipefail

if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "error: kubectl cannot reach a cluster (check kubeconfig / current-context)" >&2
  exit 1
fi

if [[ -n "${EXPECTED_KUBE_CONTEXT:-}" ]] && [[ "$(kubectl config current-context 2>/dev/null || true)" != "${EXPECTED_KUBE_CONTEXT}" ]]; then
  echo "error: current kubectl context is not EXPECTED_KUBE_CONTEXT=${EXPECTED_KUBE_CONTEXT}" >&2
  echo "hint: kubectl config use-context \"${EXPECTED_KUBE_CONTEXT}\"" >&2
  exit 1
fi

echo "== Flux: Kustomizations (flux-system) =="
kubectl -n flux-system get kustomization infrastructure apps

echo
echo "== Flux: wait for Ready (bounded) =="
kubectl -n flux-system wait kustomization/infrastructure --for=condition=Ready --timeout=15m
kubectl -n flux-system wait kustomization/apps --for=condition=Ready --timeout=20m

echo
echo "== Strimzi operator pods (strimzi-system) =="
kubectl -n strimzi-system get pods

echo
echo "== Kafka CRs (kafka-dev) =="
kubectl -n kafka-dev get kafka,kafkanodepool

echo
echo "== Kafka readiness =="
kubectl -n kafka-dev wait kafka/dev-cluster --for=condition=Ready --timeout=15m

echo
echo "OK: smoke checks completed."
