# Sprint 2 — Agent & Tech Architecture (Draft)

> Building on the Sprint 1 BLS Knowledge Graph, this sprint designs — but does not yet fully implement — the agent topology and technical stack that will let AI Graph Agents query and reason over the taxonomy knowledge graphs (BLS, and later O*NET, ESCO, SFIA, Lightcast) described in the Talent Angels project.

---

## Table of Contents

1. [Sprint Goal](#sprint-goal)
2. [Agent Architecture](#agent-architecture)
3. [Tech Architecture](#tech-architecture)
4. [End-to-End Query Flow](#end-to-end-query-flow)
5. [Open Questions for Team Review](#open-questions-for-team-review)

---

## Sprint Goal

Sprint 1 built one knowledge graph (BLS Table 1.2 → Neo4j) for one taxonomy. Sprint 2 designs the agent layer that will sit on top of this graph (and future taxonomy graphs), so a user can ask a question in natural language and get an answer grounded in the graph — this is Graph-based Retrieval-Augmented Generation (GraphRAG), the project's core deliverable.

Acceptance criteria for this sprint:

- [ ] A team-reviewed agent architecture diagram exists.
- [ ] The backend stack is chosen and justified in a document (DB, frameworks, APIs, providers).
- [ ] A diagram/schema exists showing how a query flows end to end (chat → graph → chat).

Team dynamic: organize as a team, communicate via Slack, coordinate a joint presentation of individual results.

---

## Agent Architecture

### Framework: Agent → Subagent → Skill → Tool

- **Agent** — owns an open-ended goal, decides strategy, delegates work.
- **Subagent** — receives a scoped assignment, resolves it in its own context, returns a distilled result.
- **Skill** — the packaged *how*: a procedure the (sub)agent loads to know what to do in a domain. Passive — it doesn't execute anything itself.
- **Tool** — the concrete, deterministic action that touches the outside world (e.g., a database query).

You go down a level only when the level above can't resolve on its own: delegate to a subagent when context would get polluted, load a skill when the *how* is missing, call a tool when the world needs to be touched.

### The Three Main Agents (per project definition)

| Agent | Definition | In practice |
|---|---|---|
| **Locator** | Identifies and pinpoints the exact position of a skill, task, or occupation within the taxonomies | Resolves "Software Developer" → SOC code `15-1252`, confirms which taxonomy/taxonomies contain it, and where it sits in the hierarchy |
| **Connector** | Determines and lists the nodes directly preceding and succeeding a given location, so a user can see related tasks/skills | Given a node, returns its immediate neighbors — e.g., what wage/education/projection nodes hang off it, or what adjacent occupations share an edge |
| **Pathfinder** | Traces and maps all possible routes between two locations, built from chains of Connector steps | Given a start and target occupation/skill, walks the graph (via repeated Connector calls) to enumerate learning journeys between them |

A future **Evaluator** agent (not in scope this sprint) would rank the paths Pathfinder finds, by relevance, distance, and fit to a user's skill profile. The architecture below is drafted so Evaluator can be added later without restructuring the other three.

### Draft Topology

```
                              ┌────────────────┐
                              │  User / Chat   │
                              └────────┬───────┘
                                       │
                              ┌────────▼────────┐
                              │  Orchestrator    │  (routes: locate / relate / path?)
                              └────────┬────────┘
                 ┌──────────────────────┼──────────────────────┐
                 ▼                      ▼                      ▼
           ┌───────────┐          ┌───────────┐          ┌─────────────┐
           │  Locator   │          │ Connector │          │  Pathfinder  │
           │  (Agent)   │          │  (Agent)  │          │   (Agent)    │
           └─────┬─────┘          └─────┬─────┘          └──────┬───────┘
                 │                      │                       │
         ┌───────┴────────┐     ┌───────┴────────┐      ┌───────┴────────┐
         │ Subagent:       │     │ Subagent:       │      │ Subagent:       │
         │ NodeResolver    │     │ NeighborScan    │      │ RouteWalker     │
         └───────┬────────┘     └───────┬────────┘      │ (calls Connector │
                 │                      │                │  repeatedly)     │
        Skill: "how to match       Skill: "how to        └───────┬────────┘
        a free-text term to        list a node's                 │
        a taxonomy node/          direct predecessor/     Skill: "how to
        SOC code"                 successor edges"        chain neighbor
                 │                      │                  lookups into a
        Tool: Cypher query        Tool: Cypher query       full path, avoid
        (Neo4j) / vector          (Neo4j)                  cycles, cap depth"
        similarity search                                          │
                                                            Tool: Cypher query
                                                            (Neo4j), calls
                                                            Connector as a tool
```

Notes:

- The **Orchestrator** is a thin routing agent: "is the user asking *where is X* (Locator), *what's next to X* (Connector), or *how do I get from X to Y* (Pathfinder)?"
- **Pathfinder is built on Connector**, matching the project definition ("all possible routes ... through combinations of Connector paths") — Pathfinder's subagent calls Connector repeatedly rather than duplicating graph-walking logic.
- Skills are literally the Cypher query patterns already documented in the Sprint 1 README ("Example Questions the Graph Can Answer") — this becomes the first shared skill library across agents.
- Tools are the Neo4j driver calls already built in `database.py` (Sprint 1), extended with a read-query method and, later, a vector-similarity tool for fuzzy term matching.

---

## Tech Architecture

| Layer | Choice | Why |
|---|---|---|
| **Graph DB** | Neo4j Aura (already in use from Sprint 1) | Skills/tasks/occupations are naturally graph-shaped (nodes + relationships); reuses the Sprint 1 investment and schema patterns |
| **Vector DB** | *(proposed)* Neo4j native vector index, or a separate store (Chroma) | Needed for semantic matching — e.g., a user typing "jobs with Python" won't exact-match a graph node; embeddings let Locator find the closest node by meaning |
| **Backend framework** | Python + LangGraph *(proposed)* | Sprint 1 README already names LangGraph + Neo4j GraphRAG as the intended agent layer; fits multi-agent orchestration (Locator/Connector/Pathfinder handing off to each other) |
| **Model provider** | Anthropic Claude *(proposed)* | Reasoning/orchestration model powering agent decisions and natural-language answers |
| **APIs for taxonomy ingestion** | O*NET Web Services API, ESCO SPARQL endpoint, Lightcast API, BLS flat files (per Sprint 1) | Each taxonomy publishes its own access method; SOC codes (or ESCO/O*NET crosswalks to SOC) are the shared join key across all five |
| **Config/secrets** | `python-dotenv` (already in use) | Keeps Sprint 2 consistent with the Sprint 1 pattern in `config.py` |

**Justification summary**: Sprint 1 validated Neo4j + Python + Cypher for one taxonomy (BLS). Rather than switching stacks, Sprint 2 extends it: reuse `database.py`/`config.py`, add a vector index for semantic/fuzzy lookups (needed once Locator has to resolve free-text user input to graph nodes), and add LangGraph as the layer coordinating Locator/Connector/Pathfinder, since it's designed for exactly this kind of multi-agent, multi-step flow over graph-backed data.

*(Items marked "proposed" are open for team confirmation before the sync review — see below.)*

---

## End-to-End Query Flow

Example: *"What jobs can I move into from Software Developer, and what's the path?"*

```
1. User types question in chat UI
        │
        ▼
2. Orchestrator agent receives the message
   → classifies intent as a "path" question → routes to Pathfinder
        │
        ▼
3. Pathfinder loads its Skill: "how to chain neighbor lookups into a path"
        │
        ▼
4. Pathfinder first needs the starting node resolved:
   → delegates to Locator agent → Locator's NodeResolver subagent
   → Tool: Cypher/vector lookup → returns SOC code 15-1252 (Software Developer)
        │
        ▼
5. Pathfinder's RouteWalker subagent repeatedly calls Connector
   → Connector's NeighborScan subagent runs Tool: Cypher query per hop
   → walks the graph outward, collecting candidate occupations/paths
        │
        ▼
6. RouteWalker assembles the full route(s), stops at depth limit / no cycles
   → returns a distilled list of paths to Pathfinder agent
        │
        ▼
7. Pathfinder formats a natural-language answer
        │
        ▼
8. Orchestrator returns the answer to the chat UI
        │
        ▼
9. User sees: "From Software Developer, you could move toward Data Scientist
   (shared skills, +X% growth) via these intermediate steps: ..."
```

---

## Open Questions for Team Review

- [ ] Confirm the Locator/Connector/Pathfinder boundary matches the project definition exactly, or refine subagent names.
- [ ] Vector DB choice — Neo4j native vector index vs. separate store (Chroma/Pinecone)?
- [ ] Which taxonomy gets ingested next after BLS — O*NET (skills/tasks) or ESCO (EU skills)? Needed before Connector/Pathfinder have more than one node type to traverse.
- [ ] Confirm model provider and orchestration framework choice as a team before locking the tech doc.
- [ ] How does Pathfinder cap path length / avoid combinatorial blowup on a large graph?
