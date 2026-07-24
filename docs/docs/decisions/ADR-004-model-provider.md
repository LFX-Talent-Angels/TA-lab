# ADR-004: Model provider — Anthropic Claude (API)

**Status:** Proposed (Sprint 2) — pending team ratification 260707

## Context
`SYSTEM.md` lists model provider as an open question.

## Decision
Anthropic Claude, via API.

## Rationale
Team's existing tooling and mentorship references (per Sprint 1 tip: "use
whatever AI coding agent you like; have it read this repo's CLAUDE.md")
already center on Claude-based agents.

## Alternatives considered
Not yet evaluated against other providers — this is the least-scrutinized
of the four ADRs and the one most worth challenging at the 260707 review.

## Consequences
Skills and prompts in Plan §1 are written/tuned against Claude's behavior;
provider-swapping later means re-validating skill outputs, not just
swapping an API key.
