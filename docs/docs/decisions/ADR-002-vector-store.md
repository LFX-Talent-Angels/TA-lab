# ADR-002: Vector store — Supabase pgvector

**Status:** Proposed (Sprint 2) — pending team ratification 260707

## Context
Graph-RAG retrieval needs a vector index alongside the graph (see
`SYSTEM.md` architecture diagram) for semantic/fuzzy matching that Locator's
resolution subagent needs (Plan §1) beyond exact stable-ID or Cypher lookup.

## Decision
Supabase pgvector.

## Rationale
- Colocates vector search with a relational layer, useful if taxonomy
  metadata (descriptions, licensing info per `NOTES.md` from Sprint 1)
  needs a queryable home outside the graph itself.
- Avoids introducing a fourth piece of infra for what the sprint brief
  calls a "simple, first approach."

## Alternatives considered
Standalone vector DB (Pinecone, Weaviate) — not yet evaluated; deferred
until Locator's fuzzy-search precision needs are known from Sprint 3
usage.

## Consequences
Locator's fuzzy-search tool (Plan §1, T7) queries pgvector, not a
dedicated vector service.
