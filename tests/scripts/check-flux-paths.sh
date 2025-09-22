#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

test -d clusters/dev
test -f clusters/dev/infrastructure.yaml
test -f clusters/dev/apps.yaml
test -d infrastructure/strimzi
test -d apps/kafka-dev

grep -q "path: ./infrastructure" clusters/dev/infrastructure.yaml
grep -q "path: ./apps/kafka-dev" clusters/dev/apps.yaml
grep -q "name: flux-system" clusters/dev/infrastructure.yaml
grep -q "name: flux-system" clusters/dev/apps.yaml

echo "OK: Flux path wiring looks consistent."
