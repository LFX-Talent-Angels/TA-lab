# Example Architecture Document

This is a teaching example for Talent Angels. It is not a production blueprint
and it intentionally uses a research-project shape instead of a SaaS
microservice shape.

# Talent Angels Graph-RAG Architecture Example

Talent Angels explores how AI agents can reason over skills, tasks, and
occupations. The project starts as a research and learning system: mentees build
small graph slices from public taxonomies, compare modeling choices, and turn the
best patterns into reusable agent capabilities.

The architecture is organized around a pipeline:

```text
taxonomy source
  -> small reproducible fixture
  -> normalized graph model
  -> graph queries
  -> retrieval experiments
  -> agent answers
  -> evaluation notes
```

The important question is not "which service owns this?" The important question
is "can a contributor reproduce the graph, inspect the reasoning, and improve
the answer?"

## 1. Architectural Goals

The system should help contributors:

- understand five different skills/occupation taxonomies
- model each taxonomy as a graph
- compare graph structures across sources
- retrieve relevant nodes from natural language
- trace relationships between skills, tasks, and occupations
- evaluate whether an agent's answer is grounded in the graph

Non-goals for the current example:

- production deployment
- user account management
- payments
- real-time messaging
- private learner profiles
- large proprietary data ingestion

## 2. Conceptual Map

```mermaid
flowchart TD
  question[Research question]
  fixture[Small taxonomy fixture]
  model[Canonical graph model]
  graph[Inspectable graph]
  query[Graph query]
  retrieval[Graph-RAG experiment]
  answer[Agent answer]
  eval[Evaluation note]

  question --> fixture
  fixture --> model
  model --> graph
  graph --> query
  query --> retrieval
  retrieval --> answer
  answer --> eval
  eval -. improves .-> model
  eval -. improves .-> query
```

Every useful experiment should leave behind a fixture, a graph representation, a
query, and a short note explaining what worked or failed.

## 3. Source Taxonomies

Talent Angels studies five reference sources. They do not share one schema, so
the first architectural challenge is translation into a common graph language.

| Source | Useful for | Typical modeling challenge |
| --- | --- | --- |
| ESCO | occupations, skills, qualifications | semantic-web structure and multilingual labels |
| O*NET | occupations, tasks, skills, work activities | relational tables and rating scales |
| SFIA | digital skills and proficiency levels | levels of responsibility and skill levels |
| BLS | occupational outlook and labor-market context | prose profiles plus statistical tables |
| Lightcast | labor-market skill and job-title signals | licensed schemas and changing commercial data |

For exercises, use small public samples or synthetic fixtures. Do not commit
private, licensed, or oversized source dumps.

## 4. Canonical Graph Vocabulary

The project needs a small shared vocabulary so experiments can be compared.

### Nodes

| Node | Meaning |
| --- | --- |
| `Skill` | A capability someone can learn or demonstrate |
| `Task` | Work someone performs |
| `Occupation` | A role, job family, or occupational profile |
| `Framework` | Source taxonomy or standard |
| `Level` | A proficiency or responsibility level |
| `Evidence` | Source-backed text, table row, or citation |

### Edges

| Edge | Meaning |
| --- | --- |
| `HAS_SKILL` | an occupation or task is associated with a skill |
| `PERFORMS_TASK` | an occupation includes a task |
| `BROADER_THAN` | hierarchy between concepts |
| `RELATED_TO` | non-hierarchical relationship |
| `HAS_LEVEL` | skill is described at a proficiency level |
| `SUPPORTED_BY` | node or edge has source evidence |
| `MAY_LEAD_TO` | possible learning or career transition |

This vocabulary is intentionally small. Additions should come from repeated need
across multiple taxonomy experiments.

## 5. Suggested Project Layout

This is an example layout for an implementation repo or exercise folder.

```text
taxonomy-graph-experiment/
├── README.md
├── data/
│   ├── raw/                  # gitignored local downloads
│   ├── fixtures/             # tiny committed samples
│   └── processed/            # generated, usually gitignored
├── notebooks/                # exploration and visual checks
├── src/
│   ├── ingest/               # source-specific parsers
│   ├── graph_model/          # canonical nodes and edges
│   ├── queries/              # reusable graph queries
│   ├── retrieval/            # semantic + graph retrieval experiments
│   └── agents/               # Locator, Connector, Pathfinder prototypes
├── evals/
│   ├── locator_cases.yaml
│   ├── connector_cases.yaml
│   └── pathfinder_cases.yaml
└── docs/
    ├── architecture.md
    └── decisions/
```

The folder names are less important than the separation:

- raw source data is not the same as committed fixtures
- graph modeling is not the same as retrieval
- retrieval is not the same as answer synthesis
- eval cases are first-class artifacts

## 6. Example Technical Stack

This section is intentionally concrete. A useful architecture document does not
only say "we use AI" or "we use a database"; it names the stack, explains what
each part does, and marks which choices are required versus optional.

### Local Research Stack

| Concern | Example choice | Why it fits |
| --- | --- | --- |
| Language | Python 3.11+ | strong graph, data, ML, and notebook ecosystem |
| Package manager | `uv` | fast reproducible Python environments |
| Experiment UI | Jupyter notebooks or Marimo | easy inspection of graph fixtures and query outputs |
| CLI | Typer | simple commands for ingest/query/eval workflows |
| Data validation | Pydantic | typed nodes, edges, and structured agent outputs |
| Graph in memory | NetworkX | good for small fixtures and pathfinding experiments |
| Tabular processing | Polars or pandas | practical parsing for CSV/XLSX taxonomy samples |
| Test runner | pytest | small, readable eval-style tests |

### Graph and Retrieval Stack

| Concern | Example choice | Notes |
| --- | --- | --- |
| Graph database | Neo4j Community | useful once fixtures outgrow in-memory graphs |
| Query language | Cypher | readable path and neighbor queries |
| Vector index | Chroma or LanceDB | local-first semantic search for candidate nodes |
| Embeddings | small embedding model | baseline for labels, aliases, and short evidence text |
| Graph-RAG framework | LlamaIndex Property Graph or custom thin layer | start simple; avoid hiding graph semantics too early |

The architecture should state whether the graph source of truth is NetworkX,
Neo4j, files, or another store. For early exercises, a committed fixture plus
NetworkX may be enough. For shared demos, Neo4j makes graph inspection easier.

### AI Runtime Stack

| Concern | Example choice | Notes |
| --- | --- | --- |
| Agent framework | LangGraph or a small custom state machine | use a framework only when branching/state becomes real |
| LLM provider | OpenAI, Anthropic, or local model provider | configured through environment variables, never committed |
| Primary model | small reasoning-capable model for experiments | keep cost low for mentee workflows |
| Judge model | optional stronger model for eval review | only for evals that need qualitative judgment |
| Structured output | Pydantic schemas | tests should validate objects, not prose |
| Prompt storage | versioned markdown files | easier review than prompts embedded in code |

Model names change over time. A real architecture doc should record the exact
model used for an experiment, the date it was chosen, and the reason for the
choice.

### Optional Cloud Demo Stack

The default project shape is local-first. If the team wants a shared demo, a
minimal AWS stack could look like this:

| Concern | Example AWS service | Purpose |
| --- | --- | --- |
| Static demo UI | S3 + CloudFront | host a small read-only frontend |
| Query API | App Runner or ECS Fargate | run a Python API without managing servers |
| Batch ingestion | Lambda or ECS task | rebuild graph artifacts from fixtures |
| Object storage | S3 | store public fixtures and generated graph exports |
| Secrets | Secrets Manager | hold provider API keys outside git |
| Logs | CloudWatch Logs | inspect query and ingestion failures |
| Container registry | ECR | store API or batch job images |

This is an example, not a mandate. The architecture should also document the
non-cloud alternative, especially for mentees who need to run everything locally.

### Configuration Rules

- Commit `.env.example`, never real `.env` files.
- Keep large raw data in ignored folders or external storage.
- Put public tiny fixtures in git.
- Use placeholders for model and provider keys.
- Document required environment variables in the README.
- Include a cost note for any cloud or paid model dependency.

## 7. Experiment Lifecycle

```text
1. Pick one narrow question.
2. Create or select a tiny fixture.
3. Model the fixture as nodes and edges.
4. Write one or two graph queries.
5. Add semantic lookup only if graph lookup alone is insufficient.
6. Run an agent or scripted answer over the graph.
7. Record where the answer was grounded and where it guessed.
8. Promote reusable patterns into shared code or docs.
```

Example question:

```text
"What skills connect customer support work to entry-level data analysis?"
```

A good experiment for that question does not need a full database. It needs a
small graph that includes a few support tasks, a few analysis tasks, and enough
skills to make the path inspectable.

## 8. Retrieval Strategy

Talent Angels uses Graph-RAG as a pattern, not as a magic box.

```text
Natural-language query
  -> candidate node lookup
  -> graph expansion
  -> evidence collection
  -> answer generation
  -> provenance display
```

Semantic search is useful for finding candidate nodes. Graph traversal is useful
for checking relationships. The answer should not invent edges that are not in
the graph or in the cited evidence.

## 9. Agent Modes

The project can expose three agent modes without making them separate services.

| Mode | Question type | Required graph operation |
| --- | --- | --- |
| Locator | "Where is X?" | find and disambiguate a node |
| Connector | "What is connected to X?" | inspect neighbors and edge types |
| Pathfinder | "How do I get from X to Y?" | search paths between nodes |

Each mode can begin as a notebook or CLI command before becoming an interactive
chat feature.

## 10. Evaluation

Architecture is incomplete without evals. Each experiment should include at
least one expected behavior.

| Area | Example check |
| --- | --- |
| Ingestion | every fixture row becomes the expected nodes and edges |
| Graph model | no dangling edges |
| Locator | top candidate matches expected concept |
| Connector | returned neighbors are real graph neighbors |
| Pathfinder | every path starts and ends at the requested concepts |
| Answering | citations point to actual fixture evidence |

Tiny evals are better than impressive demos that cannot be reproduced.

## 11. Documentation Rules

Architecture docs should answer:

- What is the graph trying to represent?
- Which data sources are in scope?
- What technical stack is assumed?
- Which stack choices are final vs experimental?
- What is committed to git and what stays local?
- Which node and edge types are canonical?
- How do we know an answer is grounded?
- Which decisions are still open?

Avoid:

- dumping every implementation detail into the architecture doc
- describing history instead of current state
- hiding uncertainty behind polished diagrams
- committing private data or full proprietary datasets

## 12. Open Decisions

These should move to ADRs when the team decides:

- canonical node ID format
- graph database or in-memory graph library
- vector index choice
- LLM provider and default model
- agent framework
- cloud demo hosting, if any
- fixture format
- cross-taxonomy mapping review process
- minimum citation/provenance standard
- criteria for promoting a lab experiment into shared project code
