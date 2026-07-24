# Plan — Agent & Tech Architecture

**Phase:** 3 of 6 (specdriven.ai) · **Checkpoint:** Architecture review
**Derives from:** `specification.md` · **Governed by:** `constitution.md`
**Reviewed at:** Mentee Sync #5, 260707

---

## 1. Agent topology

Following Alberto Ceballos's model exactly (Constitution: Agent/Subagent/
Skill/Tool vocabulary): Locator, Connector, and Pathfinder are **Agents** —
each owns an open-ended objective and sits at the root of its own
delegation tree within a chat turn. Orchestration decides *which* agent(s)
a query needs; each agent then decides its own subagents/skills/tools.

```mermaid
flowchart TD
    U[User — natural language query] --> O[Orchestration]

    O -->|"pinpoint a node"| LOC[Locator Agent]
    O -->|"neighbors of a node"| CON[Connector Agent]
    O -->|"route A→B"| PATH[Pathfinder Agent]

    subgraph LOC_detail[Locator]
      LOC --> LR[Resolution Subagent]
      LR -->|loads| LSK[Skill: entity-resolution<br/>per taxonomy adapter]
      LSK -->|invokes| LT1[Tool: fuzzy search<br/>prefLabel/altLabels]
      LSK -->|invokes| LT2[Tool: stable-ID lookup]
    end

    subgraph CON_detail[Connector]
      CON --> CR[Traversal Subagent]
      CR -->|loads| CSK[Skill: neighbor-rules<br/>per taxonomy adapter]
      CSK -->|invokes| CT1[Tool: single-hop query]
      CSK -->|invokes| CT2[Tool: edge-property sort<br/>e.g. O*NET importance]
    end

    subgraph PATH_detail[Pathfinder — directional, not blocking]
      PATH --> PR[Route Subagent]
      PR -->|loads| PSK[Skill: multi-hop journey rules]
      PSK -->|invokes| PT1[Tool: path-search]
    end

    LR -.->|"consumes resolved ID"| CR
    LR -.->|"consumes resolved ID"| PR

    LT1 & LT2 & CT1 & CT2 & PT1 --> KG[(Knowledge Graph<br/>+ vector index)]
    KG --> TAX["ESCO · O*NET · SFIA · BLS · Lightcast<br/>(per-taxonomy adapters)"]
```

**Coordination rule (transition rule, per Alberto's notes):**
Orchestration delegates to a subagent only when a sub-part needs an
isolated context (e.g., resolution logic shouldn't pollute Connector's
traversal context). A skill is loaded when the agent knows *what* to do
but not *how* for this specific taxonomy (SFIA's Competency bridge-entity
vs. ESCO's direct edge). A tool is called only for the concrete,
deterministic action — a query against the graph.

**Why Locator owns resolution and the others consume it:** per
Clarification in `specification.md` §6 — keeps resolution logic in one
place instead of three, and matches Sprint 1's O*NET finding that
resolution is *the* bottleneck before any traversal begins.

## 2. Tech architecture

| Layer | Choice | Justification | ADR |
|---|---|---|---|
| Graph store | Neo4j | Sprint 1's four taxonomy decks are already Cypher-native (all example queries are Cypher); switching stores now would discard that work. | `ADR-001-graph-store.md` |
| Vector store | Supabase pgvector | Colocates with a relational layer if one is needed for taxonomy metadata; avoids standing up a fourth infra piece for Sprint 2's "simple, first approach" goal. | `ADR-002-vector-store.md` |
| Framework | LangGraph | Native support for the Agent/Subagent delegation pattern in §1, over a custom orchestration loop. | `ADR-003-framework.md` |
| Model provider | Anthropic Claude (API) | Team already builds with Claude per repo tooling references; no evaluated alternative yet. | `ADR-004-model-provider.md` |

Each row is a **draft recommendation**, not a locked decision — the ADR is
where the team either confirms or overturns it before Sprint 3 starts
building against it.

### Taxonomy ingestion

Each taxonomy keeps its Sprint 1 schema; a thin **adapter** per taxonomy
maps its native labels/relationships onto a common interface Locator and
Connector query against:
BLS and Lightcast, not yet modeled, plug in as adapters once their Sprint 1
(or later) graph work exists — the architecture doesn't block on them.

## 3. End-to-end query flow

```mermaid
sequenceDiagram
    participant U as User (chat)
    participant O as Orchestration
    participant L as Locator
    participant C as Connector
    participant KG as Graph + Vector Index

    U->>O: "What skills does a Data Analyst need?"
    O->>L: resolve("Data Analyst")
    L->>KG: fuzzy search prefLabel/altLabel
    KG-->>L: candidate nodes
    L-->>O: stable_id (e.g. ESCO uri)
    O->>C: neighbors(stable_id, rel_types=[REQUIRES_ESSENTIAL_SKILL, ...])
    C->>KG: single-hop Cypher query
    KG-->>C: Skill nodes + edge properties
    C-->>O: ranked skill list
    O-->>U: natural-language answer
```

## 4. Open items for Sprint 2 review (260707)

- Confirm/overturn the four draft stack choices above via ADR review.
- Confirm the adapter interface is sufficient for SFIA's bridge-entity
  (Competency) pattern — it's the most structurally different of the four
  modeled taxonomies so far.
- Decide whether BLS/Lightcast modeling starts in Sprint 3 alongside
  Locator/Connector build, or is deferred further.

## 5. References

See `specification.md` §9 for full source list. Agent topology in §1
follows Alberto Ceballos's Sprint 2 notes directly.
