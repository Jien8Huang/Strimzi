# clusters/dev

This directory is the **Flux reconciliation entrypoint** for a single local development cluster.

`flux bootstrap` should configure the root `GitRepository` + `Kustomization` so Flux runs `kustomize build` against `./clusters/dev`.

## What gets applied from here

- `infrastructure.yaml` — Flux `Kustomization` that reconciles `./infrastructure` (Strimzi operator install).
- `apps.yaml` — Flux `Kustomization` that reconciles `./apps/kafka-dev` (Kafka custom resources). It `dependsOn` **infrastructure**.
