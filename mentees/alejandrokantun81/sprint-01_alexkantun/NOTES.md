# Sprint 1 — Research & Build a Taxonomy Graph

**Taxonomy chosen:** ESCO (European Skills, Competences, Qualifications and Occupations)

## Where the data came from

- **Source:** ESCO Classification dataset, v1.2.1 (English) — https://esco.ec.europa.eu/en/use-esco/download
- **Publisher:** European Commission, DG Employment, Social Affairs and Inclusion
- **License:** Creative Commons Attribution 4.0 International (CC BY 4.0) — https://creativecommons.org/licenses/by/4.0/
- **Format used:** CSV export (occupations, skills, ISCO groups, skill groups, and the occupation–skill / skill–skill relation files)

## The graph model

ESCO is already SKOS/RDF (`skos:Concept`, `skos:broader`, plus essential/optional skill predicates), so the property-graph translation is fairly direct:

| Node label | Key property | Represents |
|---|---|---|
| `Occupation` | `uri` | An ESCO occupation concept |
| `Skill` | `uri` | An ESCO skill/competence concept |
| `ISCOGroup` | `code` (string, to keep leading zeros) | ISCO-08 classification group |
| `SkillGroup` | `code` (string) | ESCO skill-hierarchy group |

| Relationship | Direction | Meaning |
|---|---|---|
| `REQUIRES_ESSENTIAL_SKILL` | `Occupation → Skill` | Skill is core to the occupation |
| `MAY_REQUIRE_OPTIONAL_SKILL` | `Occupation → Skill` | Skill is contextual/optional |
| `CLASSIFIED_UNDER` | `Occupation → ISCOGroup` | ISCO-08 mapping |
| `IS_BROADER_THAN` | `Group → Group` (Skill or ISCO) | Hierarchy edge |

```mermaid
graph LR
  D[Occupation: Software developer] -->|REQUIRES_ESSENTIAL_SKILL| S1[Skill: web services]
  D -->|MAY_REQUIRE_OPTIONAL_SKILL| S2[Skill: design user interface]
  D -->|CLASSIFIED_UNDER| G1[ISCOGroup 2512]
  A[Occupation: Data analyst] -->|CLASSIFIED_UNDER| G2[ISCOGroup 2519]
  S1 -->|PART_OF| SG[SkillGroup: ICT skills]
  S2 -->|PART_OF| SG
```

`graph.cypher` in this folder is a small, runnable slice that builds exactly this shape with a handful of real ESCO concepts — see that file for the nodes/edges and the example questions below.


## What I learned

**Theory**

- A knowledge graph earns its keep exactly where ESCO already lives: multi-hop questions ("what else needs this skill?", "what's the gap to occupation X?") that would otherwise need repeated joins.
- `MERGE` + uniqueness constraints make re-imports idempotent — important since ESCO ships periodic minor-version updates (this dataset is v1.2.1) that shouldn't duplicate the graph on re-run.
- In a property graph, the conceptual model and the physical model are the same artifact — there's no separate translation step between "what I sketched" and "what's queryable."

**Practice (ESCO-specific)**

- ESCO and O\*NET are *not* interchangeable — different structure, different keys, different license. Worth confirming the dataset before modeling, since the schemas don't transfer.
- `code` fields on `ISCOGroup`/`SkillGroup` need explicit **string** typing — ISCO-08 codes have leading zeros that get silently dropped if inferred as integers.
- ESCO's `skillSkillRelations` file reuses essential/optional semantics (not a symmetric "related to") — so the same two relationship types cover both occupation→skill and skill→skill edges; no extra relationship type was needed.
- `definition` is almost entirely empty on ESCO concepts — `description` is the populated, human-readable field to use instead.

## Example questions this graph can answer

1. **What skills does occupation X require?**
   ```cypher
   MATCH (o:Occupation {prefLabel: "Software developer"})-[r:REQUIRES_ESSENTIAL_SKILL|MAY_REQUIRE_OPTIONAL_SKILL]->(s:Skill)
   RETURN s.prefLabel, type(r) AS relationship;
   ```

2. **Which occupations share a given skill?**
   ```cypher
   MATCH (s:Skill {prefLabel: "web services"})<-[:REQUIRES_ESSENTIAL_SKILL|MAY_REQUIRE_OPTIONAL_SKILL]-(o:Occupation)
   RETURN o.prefLabel;
   ```

3. **How is an occupation classified in ISCO-08?**
   ```cypher
   MATCH (o:Occupation {prefLabel: "Data analyst"})-[:CLASSIFIED_UNDER]->(g:ISCOGroup)
   RETURN g.code, g.prefLabel;
   ```

## Reflection — what would the TA-agents need from this graph?


**Locator** — pinpoints a skill/task/occupation in the taxonomies.
- Needs a stable anchor it can resolve *to* from messy input (job titles, résumé text, free-form search). The ESCO `uri` is that anchor, but Locator can't search free text against a URI — it needs a full-text/fuzzy index over `prefLabel` and the split-out `altLabels` array (ESCO ships alt labels newline-delimited in a single cell; already handled here via `split()`).
- Benefits from `description` as a disambiguation field when multiple concepts share a near-identical label (e.g. "developer" matching several distinct occupations).

**Connector** — lists the nodes directly preceding/succeeding a location.
- Maps cleanly onto the single-hop edges already in this schema: `IS_BROADER_THAN` for hierarchy neighbors, `REQUIRES_ESSENTIAL_SKILL` / `MAY_REQUIRE_OPTIONAL_SKILL` for occupation↔skill adjacency in either direction.
- What's missing: "preceding/succeeding" implies one consistent notion of adjacency, but hierarchy edges and skill-requirement edges are semantically different kinds of steps. Connector would need to know which relationship types count as "neighbors" for a given query rather than treating every outgoing edge the same way.

**Pathfinder** — traces all routes between two locations (learning journeys).
- This is the multi-hop case (`allShortestPaths` / variable-length `MATCH`). The career-transition query already built for the Query deliverable (shared essential skills, Jaccard-normalized) is effectively a one-hop version of what Pathfinder needs generalized to N hops.
- What's hard: **the current graph has no edge weights.** ESCO's occupation–skill relation is a binary essential/optional flag — no numeric distance, cost, or difficulty on any edge. Pathfinder can confirm a route *exists*, but has no basis yet for preferring the easiest one over an alternative.
- The deferred `Qualification` pillar also limits Pathfinder today — a real learning journey usually ends at a qualification, not just another skill or occupation, and that pillar is still an empty placeholder in this build.

**Evaluator (future)** — ranks paths by relevance, distance, profile fit.
- Needs the most that isn't here yet: a numeric importance score per skill–occupation edge (O\*NET's IM/LV ratings are the closest analogue — ESCO has no equivalent, it's strictly essential/optional with no grading), a "distance" metric derived from path length or skill overlap (the Jaccard score already computed is a candidate building block), and some representation of a learner/candidate *profile* node to score "fit" against — none of which exists in the v1 schema.
- This is the clearest place where ESCO's structure diverges from O\*NET's: O\*NET bakes importance/level scores into every skill edge for free, which is exactly the kind of signal Evaluator wants. Building Evaluator on top of ESCO will likely mean deriving those weights rather than importing them.
