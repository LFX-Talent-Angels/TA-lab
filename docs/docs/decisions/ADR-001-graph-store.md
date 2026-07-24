# ADR-001: Graph store — Neo4j

**Status:** Proposed (Sprint 2) — pending team ratification 260707

## Context
`SYSTEM.md` lists graph store as an open question. Sprint 1's four teams
(ESCO, O*NET, SFIA) independently chose Cypher for their example queries
without coordinating — a de facto signal, not yet a decision.

## Decision
Neo4j.

## Rationale
- All Sprint 1 example queries across ESCO, O*NET, and SFIA decks are
  already written in Cypher — adopting Neo4j preserves that work as-is.
- SFIA's bridge-entity pattern (Competency = Skill × Level intersection)
  and O*NET's typed edge properties (importance, level) both map cleanly
  onto Neo4j's property-graph model without translation.

## Alternatives considered
- Not yet evaluated against alternatives (e.g. Amazon Neptune, ArangoDB).
  Flagged as an open item — this ADR should be revisited if Neo4j's
  licensing or scale characteristics become a blocker in Sprint 3+.

## Consequences
Sprint 3's adapter layer (Plan §2) is built Neo4j-native. Switching later
means rewriting all adapters, not just swapping a driver.
