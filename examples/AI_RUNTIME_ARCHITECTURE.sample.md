# Example Agent Experiment Architecture

This example avoids a production-service framing. It shows how to document an
agent experiment for Talent Angels: what the agent tries to answer, what graph
tools it uses, how it is evaluated, and when the experiment is ready to promote.

# Locator / Connector / Pathfinder Experiment Architecture

The first Talent Angels agents can be built as experiments over a small graph
fixture. They do not need deployment, accounts, or complex infrastructure to be
architecturally clear.

## 1. Experiment Question

Every agent experiment starts with a narrow question.

Examples:

- Locator: "Can we reliably find the graph node for a skill mentioned in plain
  English?"
- Connector: "Can we explain the immediate neighbors of an occupation?"
- Pathfinder: "Can we produce a plausible path between two occupations using
  explicit graph edges?"

If the question is vague, the architecture will become vague.

## 2. Minimal Runtime

```mermaid
flowchart LR
  prompt[User prompt]
  normalize[Normalize text]
  candidates[Find candidate nodes]
  graph[Graph operation]
  evidence[Collect evidence]
  response[Structured answer]
  eval[Eval case]

  prompt --> normalize
  normalize --> candidates
  candidates --> graph
  graph --> evidence
  evidence --> response
  response --> eval
```

This can run in a notebook, test, CLI command, or local script. The architecture
is about the reasoning loop, not the hosting model.

## 3. Example Technical Stack

This stack is illustrative. Its job is to show how technical choices are
documented, not to force every experiment to use the same tools.

| Layer | Example technology | Used for |
| --- | --- | --- |
| Python runtime | Python 3.11+ | shared implementation language |
| Environment | `uv` | dependency installation and lockfile |
| Graph fixture | JSONL or YAML | tiny committed nodes and edges |
| In-memory graph | NetworkX | path search and neighbor traversal |
| Graph database | Neo4j | optional shared graph inspection |
| Vector search | Chroma or LanceDB | local semantic candidate lookup |
| Embeddings | OpenAI embeddings or local embedding model | label and evidence retrieval |
| Agent control flow | LangGraph or plain Python functions | route between locate/connect/pathfind steps |
| Structured output | Pydantic | validate agent responses |
| Evaluation | pytest + YAML cases | repeatable behavior checks |
| Notebook UI | Jupyter or Marimo | mentor-friendly inspection |

### Model Configuration

Document model choices explicitly:

| Use | Example model class | Selection rule |
| --- | --- | --- |
| Candidate explanation | small low-cost chat model | enough for short grounded summaries |
| Complex path explanation | stronger reasoning model | use only when path explanation needs synthesis |
| Embeddings | small embedding model | optimize for cost and repeatability |
| Eval judge | optional stronger model | only when deterministic checks are insufficient |

Do not hard-code provider keys or model secrets. Read them from environment
variables and document placeholders in `.env.example`.

### Optional Hosted Demo

Most experiments should run locally. A hosted demo is optional and should stay
small.

| Need | Example AWS service | Note |
| --- | --- | --- |
| Run query API | App Runner | simpler than managing a VM for a small Python app |
| Store graph exports | S3 | good for generated JSON/GraphML artifacts |
| Store secrets | Secrets Manager | provider keys and database credentials |
| View logs | CloudWatch Logs | enough for demo troubleshooting |
| Container images | ECR | if the API is containerized |

If the hosted demo uses paid models or cloud resources, the architecture doc
should include a cost/risk note.

## 4. Shared Inputs

All three agents use the same basic inputs.

| Input | Description |
| --- | --- |
| `query` | user question or direct task |
| `fixture` | small graph sample used for reproduction |
| `node_types` | allowed node types, such as Skill or Occupation |
| `edge_types` | allowed edge types, such as HAS_SKILL or BROADER_THAN |
| `max_depth` | traversal limit for path search |

The fixture should be small enough that a reviewer can read it by hand.

## 5. Shared Outputs

Each agent should return structured output before prose.

```json
{
  "agent": "Locator",
  "answer": "The closest match is Data analysis.",
  "nodes": [
    {
      "id": "skill:data-analysis",
      "label": "Data analysis",
      "type": "Skill"
    }
  ],
  "edges": [],
  "evidence": [
    {
      "source": "fixture",
      "id": "evidence:001"
    }
  ],
  "warnings": []
}
```

Natural-language explanation can be added after the structured result. This
makes tests and UI rendering easier.

## 6. Locator Design

Locator maps a phrase to a graph node.

```text
query text
  -> normalize phrase
  -> search labels and aliases
  -> rank candidates
  -> return best node or ask for clarification
```

Good Locator behavior:

- returns alternatives when terms are ambiguous
- distinguishes skills from occupations
- explains which label or alias matched
- refuses to invent a node when none exists

Example eval:

```yaml
- query: "data viz"
  expected_node: "skill:data-visualization"
  accepted_alternatives:
    - "skill:visual-communication"
```

## 7. Connector Design

Connector explains what surrounds a node.

```text
node
  -> select edge types
  -> retrieve neighbors
  -> group by relationship
  -> summarize graph context
```

Good Connector behavior:

- groups neighbors by edge type
- keeps direction clear
- reports when a node has sparse context
- shows evidence for surprising relationships

Example eval:

```yaml
- node: "occupation:data-analyst"
  edge_type: "HAS_SKILL"
  must_include:
    - "skill:data-analysis"
    - "skill:spreadsheet-software"
```

## 8. Pathfinder Design

Pathfinder searches for routes between two graph locations.

```text
source phrase
  -> locate source node
target phrase
  -> locate target node
source + target
  -> constrained path search
  -> explain path steps
```

Good Pathfinder behavior:

- states assumptions about source and target
- limits path length
- avoids using unsupported edges
- returns no path when no path exists in the fixture
- separates "found in graph" from "plausible but not represented"

Example eval:

```yaml
- from: "occupation:customer-support-specialist"
  to: "occupation:data-analyst"
  max_depth: 4
  path_must_start_with: "occupation:customer-support-specialist"
  path_must_end_with: "occupation:data-analyst"
```

## 9. Evidence and Provenance

Every answer should identify why it believes something.

Evidence can be:

- a fixture row
- a taxonomy concept ID
- a source label
- a source relationship
- a short note written by the experiment author

Do not cite evidence that the agent did not actually retrieve.

## 10. Failure Modes

The architecture should name expected failures.

| Failure | Example | Expected behavior |
| --- | --- | --- |
| Ambiguous term | "engineer" | ask for clarification or return alternatives |
| Missing node | unknown skill | say it is not in the fixture |
| Sparse graph | node has no neighbors | report sparse context |
| No path | disconnected concepts | return no path, not a fabricated bridge |
| Weak evidence | relationship comes from a note | mark as lower confidence |

## 11. Promotion Criteria

An experiment is ready to promote when:

- it has a readable fixture
- it has repeatable evals
- the output is structured
- failure behavior is documented
- graph assumptions are written down
- at least one other contributor can reproduce it

Promotion does not mean "ship to production." It means the pattern is clear
enough to reuse in the main project.

## 12. What This Document Should Not Contain

Keep this kind of document focused. Do not include:

- API keys
- private learner data
- full source taxonomy dumps
- unrelated product roadmap
- implementation history
- speculative infrastructure plans

Those belong in local config, ignored data folders, ADRs, or roadmap docs.
