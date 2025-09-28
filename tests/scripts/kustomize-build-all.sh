#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

if command -v kustomize >/dev/null 2>&1; then
  KUSTOMIZE=(kustomize build)
elif command -v kubectl >/dev/null 2>&1; then
  KUSTOMIZE=(kubectl kustomize)
else
  echo "Neither kustomize nor kubectl found on PATH; skipping build checks."
  exit 0
fi

"${KUSTOMIZE[@]}" clusters/dev >/dev/null
"${KUSTOMIZE[@]}" infrastructure >/dev/null
"${KUSTOMIZE[@]}" apps/kafka-dev >/dev/null

echo "OK: kustomize build succeeded for clusters/dev, infrastructure, apps/kafka-dev."
