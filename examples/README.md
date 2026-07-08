# Examples

Teaching examples for mentors and mentees. These files are oriented around the
Talent Angels domain, but they intentionally avoid a production SaaS or
microservice shape. They show how to document research-style Graph-RAG work:
fixtures, graph modeling, retrieval, agents, evals, and example technical stack
choices.

## Files

- `ARCHITECTURE.sample.md` — architecture example for a taxonomy graph and
  Graph-RAG research workflow, including local and optional cloud stack choices.
- `AI_RUNTIME_ARCHITECTURE.sample.md` — architecture example for a local
  Locator/Connector/Pathfinder experiment, including models, frameworks, graph
  tools, and evals.

## How to Use Them

Read them as templates, not as final project facts. A good architecture document
should make graph semantics, experiment boundaries, fixtures, technical stack,
evals, and open decisions explicit enough that a new contributor can reproduce
the work.

When writing your own version:

- start from the question the experiment answers
- describe the system in present tense
- document graph nodes, edges, fixtures, retrieval, and evals
- name concrete stack choices and explain whether they are required or optional
- keep secrets, credentials, private URLs, and personal data out
- update the document when the graph model or experiment behavior changes
