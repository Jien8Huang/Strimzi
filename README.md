# GitOps + Strimzi (local dev)

This repository holds **Flux** manifests that install the **Strimzi Kafka Operator** and a **small development Kafka cluster** (KRaft) for a disposable **kind** cluster.

## Layout

- `clusters/dev/` — entry path for Flux after `flux bootstrap` (root `Kustomization` points here).
- `infrastructure/strimzi/` — Flux `HelmRepository` + `HelmRelease` for the Strimzi operator chart (pinned).
- `apps/kafka-dev/` — `Kafka` + `KafkaNodePool` for a single-broker dev topology.
- `docs/bootstrap.md` — prerequisites and ordered bootstrap commands.
- `hack/smoke.sh` — readiness checks once a cluster is running.

## Quick start (outline)

Details live in `docs/bootstrap.md`. The ordering is:

1. Create a local **kind** cluster.
2. Run **`flux bootstrap github`** (or equivalent) so `flux-system` exists and the root `Kustomization` tracks `./clusters/dev` in this repository.
3. Wait for Flux `Kustomization` objects **infrastructure** and **apps** to reconcile.
4. Run `./hack/smoke.sh`.

## Documented learnings

- `docs/solutions/best-practices/flux-strimzi-kind-dev-repo-patterns.md` — Flux/Strimzi ordering, Helm value verification, and review pitfalls for this repo shape.

## References

- [Strimzi documentation](https://strimzi.io/documentation/)
- [Flux documentation](https://fluxcd.io/flux/)
