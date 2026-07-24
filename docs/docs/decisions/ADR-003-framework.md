# ADR-003: Agent framework — LangGraph

**Status:** Proposed (Sprint 2) — pending team ratification 260707

## Context
`SYSTEM.md` lists "LLM provider(s) and framework (LangChain / LangGraph /
custom)" as an open question. The agent topology in `plan.md` §1 requires
explicit Agent → Subagent delegation with isolated contexts, per Alberto
Ceballos's model.

## Decision
LangGraph.

## Rationale
Native support for the delegation-graph pattern the topology diagram
already assumes (Orchestration → Agent → Subagent), rather than building
that control flow from scratch on top of raw LangChain or a custom loop.

## Alternatives considered
Custom orchestration loop — rejected for now in favor of simplicity: don't
build what a library already does well, matching the sprint's "simple,
first approach" goal.

## Consequences
Sprint 3's Orchestration task (T13) is scoped as a LangGraph graph
definition, not a custom router.
