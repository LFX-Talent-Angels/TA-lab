# Specification — Agent & Tech Architecture

**Phase:** 2 of 6 (specdriven.ai) · **Checkpoint:** Stakeholder review
**Governs:** Sprint 2, Weeks 3–4 (260630 → 260714)
**Constitution:** see `constitution.md` — this spec must not contradict it.
**Reviewed at:** Mentee Sync #5, 260707

## 1. Intent

Sprint 1 produced five independent taxonomy knowledge graphs (ESCO, O*NET,
SFIA, BLS, Lightcast), each modeled by a different teammate with a different
schema. Sprint 2's job is **not** to build Locator, Connector, or Pathfinder —
it is to produce the *reviewed blueprint* those three agents will be built
against: an agent topology and a backend architecture that can sit on top
of Sprint 1's graphs without forcing a rewrite of any of them.

This is explicitly the "simple, first approach" — per the sprint brief —
to help the team understand and explore the space, not a final system design.

## 2. User journey

> A learner or advisor asks a natural-language question in chat
> ("What skills does a Data Analyst need?") and receives an answer grounded
> in one or more taxonomy graphs, without needing to know which taxonomy,
> which graph query, or which agent produced it.

Flow: **user → chat interface → orchestration → Locator/Connector/Pathfinder
→ Knowledge Graph + vector index → response**. (Per `SYSTEM.md` diagram.)

## 3. In scope

- Agent topology: Locator, Connector, Pathfinder as Agents; their subagents;
  the skills each loads; the tools each invokes; how they coordinate.
- Tech architecture: graph store, vector store, framework, model provider,
  and how the five taxonomies are ingested and queried.
- A diagram of the end-to-end query flow.

## 4. Out of scope (this sprint)

- Actual implementation of any agent (that's Sprint 3+, "Locator & Connector
  live" per the roadmap).
- Cross-taxonomy crosswalks (ESCO uri ↔ O*NET onet_soc_code ↔ SFIA code) —
  flagged as a real need in Sprint 1, but Pathfinder-level work, not Sprint 2.
- Evaluator agent — explicitly a future iteration per the roadmap.
- BLS and Lightcast graph modeling — Sprint 1 didn't complete these; the
  architecture must accommodate them without requiring them to exist yet.

## 5. Constraints (carried forward from Sprint 1)

| Constraint | Source | Architectural implication |
|---|---|---|
| No shared schema across taxonomies | ESCO (SKOS/RDF-derived) vs. O*NET (no canonical graph model) vs. SFIA (spreadsheet-derived, bridge-entity pattern) | Architecture needs either a thin common interface Locator/Connector query against, or taxonomy-specific adapters — this is a Clarify-phase decision, see §6. |
| Binary vs. graded edge weights | ESCO: essential/optional flag only. O*NET: Importance/Level/Frequency per descriptor, 12 domains, not all same scale. | Connector's definition of "neighbor" may need to be taxonomy-aware, not a single fixed rule. |
| Entity resolution is a hard prerequisite | O*NET Sprint 1: "stable identifiers are machine keys; people use job titles" | A resolution layer (NL → stable ID) sits in front of every agent, not just Locator. |
| Cross-domain edges are implicit, not stored | O*NET Content Model connects Knowledge→Skills, Tasks→Work Activities, but no source file encodes this | Must be built as explicit, logged inferred edges (Constitution: no silent inference). |
| Open infra questions, unresolved | `SYSTEM.md` "Open questions" | Graph store, vector store, framework, provider — each needs an ADR (see `plan.md`). |

## 6. Clarifications

- **Q: One abstraction layer or per-taxonomy adapters?**
  A: Per-taxonomy adapters into a common node/edge interface. Sprint 1's
  four schemas are different enough (SFIA's Competency bridge-entity vs.
  ESCO's direct Occupation→Skill edge) that forcing one schema now would
  either break SFIA's model or ESCO's simplicity. Adapters preserve each
  taxonomy's Sprint 1 work as-is.
- **Q: Does every agent need entity resolution, or just Locator?**
  A: Every agent needs it, but only Locator *owns* it. Connector and
  Pathfinder consume already-resolved stable IDs from Locator rather than
  re-implementing resolution — keeps resolution logic in one place.
- **Q: How does Connector define "neighbor" across taxonomies with
  different edge semantics?**
  A: Neighbor = single-hop via a relationship type explicitly tagged
  `traversable` in that taxonomy's adapter config. Importance/Level values
  ride as edge properties Connector can sort by, but don't change what
  counts as a neighbor.

## 7. Success criteria (= sprint acceptance criteria)

1. A team-reviewed agent architecture diagram exists.
2. The backend stack is chosen and justified in a document (DB, frameworks,
   APIs, providers) — see `plan.md` + ADRs in `docs/decisions/`.
3. A diagram/schema of the end-to-end query flow (chat → graph → chat) exists.

## 8. Dynamic

Self-organized team, Slack-coordinated, one collective presentation of
individual contributions at Mentee Sync #5 (260707).

## 9. References

1. Noemí Muñiz, *Talent Angels — Outcome-Based Road Map*.
   [Google Slides](https://docs.google.com/presentation/d/1RlLIxIIjQhTZQdxFSGMM7FQ579LjCv5ynE1KAUjMCtA/edit?slide=id.p1#slide=id.p1)
2. Alberto Ceballos, *Sprint 2 notes — Agent/Subagent/Skill/Tool model*
   (top-down and bottom-up definitions). Distributed to the team 260630.
   Canonical vocabulary source per Constitution.
3. Alfonso Govela, *Spec-Driven Development (SDD) — AI Overview*.
   Summarizes the Specify → Plan → Task → Implement & Validate cycle and
   the Spec-First / Spec-Anchored / Spec-as-Source maturity levels this
   project follows (Spec-Anchored).
4. Deepak Babu Piskala, *Spec-Driven Development: From Code to Contract
   in the Age of AI Coding Assistants*, arXiv:2602.00180v1 [cs.SE],
   30 Jan 2026. <https://arxiv.org/html/2602.00180v1>
