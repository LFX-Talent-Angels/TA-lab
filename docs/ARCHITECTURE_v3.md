# Architecture Blueprint: Agent and Technological Infrastructure

**Phase:** 2 of 6 (specdriven.ai) · **Checkpoint:** Architecture review
**Governing Document:** `constitution.md`

## 1. Architectural Intent and Goals

The fundamental objective of this architectural blueprint is to delineate a reproducible, evaluated framework upon which the Locator, Connector, and Pathfinder agents shall operate. The system is structurally designed to facilitate contributor comprehension across disparate skills and occupation taxonomies, enabling the systematic modeling of each taxonomy as an inspectable graph. This architecture explicitly constitutes a preliminary methodological approach designed for exploration, deliberately omitting production-grade deployment requirements or cross-taxonomy crosswalk formulations at this juncture. 

## 2. Conceptual Map

The architecture is systematically organized around a deterministic pipeline, ensuring that every experimental iteration produces a reproducible fixture, an inspectable graph representation, and an evaluative summary.

```mermaid
flowchart TD
  question[Research question]
  fixture[Small taxonomy fixture]
  model[Canonical graph model]
  kg[Inspectable graph]
  query[Graph query]
  retrieval[Graph-RAG experiment]
  answer[Agent answer]
  eval[Evaluation note]

  question --> fixture
  fixture --> model
  model --> kg
  kg --> query
  query --> retrieval
  retrieval --> answer
  answer --> eval
  eval -. improves .-> model
  eval -. improves .-> query
```
*Note: The primary heuristic is defined not by service ownership, but by the capacity of a contributor to reproduce the graph and inspect the underlying computational reasoning.*

## 3. Source Taxonomies and Ingestion Strategy

The system evaluates five primary reference taxonomies. Because these sources do not inherently share a unified structural schema, the architecture dictates the implementation of taxonomy-specific adapters that map native structures into a universally interpretable interface.

| Source | Utility Domain | Structural Modeling Challenge |
| :--- | :--- | :--- |
| **ESCO** | Occupations, skills, and corresponding qualifications. | Requires accommodation of semantic-web structures and multilingual nomenclature. |
| **O\*NET** | Occupations, constituent tasks, skills, and work activities. | Necessitates the translation of relational tables and complex rating scales. |
| **SFIA** | Digital competencies and standardized proficiency strata. | Demands resolution of responsibility hierarchies and progressive skill levels. |
| **BLS** | Occupational outlook data and macroeconomic labor contexts. | Requires synthesizing prose-based profiles with statistical data configurations. |
| **Lightcast** | Labor-market skill indicators and job-title frequency signals. | Entails managing proprietary licensed schemas and dynamic commercial data. |

## 4. Canonical Graph Vocabulary

To ensure robust comparability across analytical experiments, the architecture mandates a standardized, highly constrained ontological vocabulary.

### Foundational Nodes
| Node Classification | Semantic Definition |
| :--- | :--- |
| `Skill` | A demonstrable or acquirable professional capability. |
| `Task` | A discrete unit of labor or operational activity. |
| `Occupation` | A defined professional role or broader job family. |
| `Framework` | The originating taxonomy or institutional standard. |
| `Level` | A delineated stratum of proficiency or organizational responsibility. |
| `Evidence` | Corroborating source text, database entries, or formal citations. |

### Relational Edges
| Edge Designation | Semantic Definition |
| :--- | :--- |
| `HAS_SKILL` | Denotes that an occupation or task structurally incorporates a specific skill. |
| `PERFORMS_TASK` | Indicates that a given occupation encompasses a specific task. |
| `BROADER_THAN` | Establishes a definitive hierarchical subordination between conceptual nodes. |
| `RELATED_TO` | Defines a lateral, non-hierarchical conceptual association. |
| `HAS_LEVEL` | Connects a skill to its explicitly described proficiency threshold. |
| `SUPPORTED_BY` | Links a node or edge directly to its foundational source evidence. |
| `MAY_LEAD_TO` | Signifies a mathematically or theoretically probable career or educational progression. |

## 5. Agent Topology and Operational Modes

The orchestration layer interfaces with three autonomous agents, each governing a specific conceptual retrieval mode. 

| Operational Mode | Query Topology | Required Graph Operation |
| :--- | :--- | :--- |
| **Locator** | "Where is X?" | Executes entity resolution to locate and systematically disambiguate a target node. |
| **Connector** | "What is connected to X?" | Evaluates adjacent neighbor nodes and assesses the properties of connecting edges. |
| **Pathfinder** | "How do I get from X to Y?" | Executes directional, multi-hop search algorithms to establish valid relational paths. |

**Delegation Mechanics:**
Orchestration selectively delegates natural-language queries. The Locator agent solely owns entity resolution, ensuring that the Connector and Pathfinder subsequently consume stable identifiers rather than duplicating resolution algorithms.

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

    subgraph PATH_detail[Pathfinder]
      PATH --> PR[Route Subagent]
      PR -->|loads| PSK[Skill: multi-hop journey rules]
      PSK -->|invokes| PT1[Tool: path-search]
    end

    LR -.->|"consumes resolved ID"| CR
    LR -.->|"consumes resolved ID"| PR

    LT1 & LT2 & CT1 & CT2 & PT1 --> KG[(Knowledge Graph<br/>+ vector index)]
```

## 6. Technological Infrastructure

The specified technological stack balances the necessity for advanced cognitive processing with the imperative of infrastructural parsimony.

| Architectural Layer | Selected Technology | Functional Justification |
| :--- | :--- | :--- |
| **Graph Store** | Neo4j | Preserves the antecedent Cypher-native queries formulated during the initial taxonomy modeling sprint. |
| **Vector Index** | Supabase pgvector | Co-locates vector embeddings alongside relational metadata to circumvent unnecessary infrastructural bloat. |
| **Agent Framework** | LangGraph | Supplies robust native primitives for executing the requisite agent-subagent delegation hierarchy. |
| **Model Provider** | Anthropic Claude (API) | Maintains uninterrupted alignment with pre-existing computational tooling established within the repository. |

## 7. Retrieval Strategy and Query Lifecycle

The methodological retrieval sequence eschews opaque heuristic synthesis in favor of a strictly traceable Graph-RAG pattern.

**Procedural Flow:**
1. Receipt of the natural-language query.
2. Execution of candidate node lookup via semantic vector search.
3. Methodical graph expansion to ascertain traversal pathways.
4. Aggregation of corresponding corroborating evidence.
5. Algorithmic generation of the synthesized answer.
6. Explicit exposure of the data provenance to the end-user.

Semantic search paradigms are utilized exclusively to locate candidate nodes, whereas rigorous graph traversal functions to validate the empirical relationships, ensuring the agent does not fabricate theoretical edges absent from the source data.

## 8. Evaluation and Compliance Directives

The architecture mandates strict evaluative compliance for all experimental iterations. 

*   **Ingestion Integrity:** Assertions must verify that every source fixture row translates accurately into the prescribed nodes and edges.
*   **Graph Cohesion:** Models must be structurally validated to guarantee an absence of dangling or orphaned edges.
*   **Agentic Accuracy:** Locator outputs must align with expected conceptual identities; Connector algorithms must return exclusively legitimate graph neighbors; and Pathfinder routines must commence and terminate precisely at the requested conceptual boundaries. 
*   **Provenance:** All synthesized responses must possess direct citations anchored unequivocally in the designated fixture evidence.
