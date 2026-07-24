# Tasks — from Plan to Sprint 3 backlog

**Phase:** 4 of 6 (specdriven.ai) · **Checkpoint:** Scope review
**Derives from:** `plan.md` · **Feeds:** Sprint 3 ("Locator & Connector live")

Each task is PR-sized (1–4 hrs). `[P]` = can run in parallel with other `[P]`
tasks. Ordered by dependency.

## Infra
- [ ] T1 — Stand up Neo4j instance per `ADR-001` *(blocks T3+)*
- [ ] T2 `[P]` — Stand up Supabase pgvector per `ADR-002`
- [ ] T3 — Load ESCO Sprint-1 slice into Neo4j via its native schema (no adapter yet — validates raw import)

## Adapter layer
- [ ] T4 — Define common adapter interface (`resolve`, `neighbors`, `traversable_rel_types`) as code, from Plan §2
- [ ] T5 — Implement ESCO adapter against T3's loaded data
- [ ] T6 `[P]` — Implement O*NET adapter (validates the interface against a *different* schema shape — priority per Plan §4 open item)

## Locator
- [ ] T7 — Resolution subagent: fuzzy search tool over `prefLabel`/`altLabel` (ESCO only, first pass)
- [ ] T8 — Resolution subagent: stable-ID lookup tool
- [ ] T9 — Wire Locator skill to select adapter based on detected taxonomy

## Connector
- [ ] T10 — Traversal subagent: single-hop query tool, consuming Locator's resolved ID
- [ ] T11 — Edge-property sort tool (handles O*NET importance ranking; no-op for ESCO's binary flag)
- [ ] T12 — Neighbor-rules skill: `traversable_rel_types` config per adapter

## Orchestration + integration
- [ ] T13 — Route a query to Locator vs. Connector vs. both (LangGraph, per `ADR-003`)
- [ ] T14 — End-to-end smoke test: one chat query → Locator → Connector → response, matching Plan §3 sequence diagram

## Review gate
- [ ] T15 — Confirm all four ADRs (`ADR-001`–`004`) are either ratified or superseded before T1 starts in Sprint 3
