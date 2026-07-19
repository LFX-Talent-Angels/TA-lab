Sprint 1 — ESCO Knowledge Graph
Author: Alejandro · LFX Technical Assistant Project (Sprint 1) Taxonomy: ESCO Classification v1.2.1 (English) · Graph DB: Neo4j AuraDB (managed, Bolt-only)


Why ESCO
ESCO (European Skills, Competences, Qualifications and Occupations) was the assigned taxonomy for this sprint. A few things made it a good fit for a property-graph build:

Natively semantic, not relational. ESCO ships as a SKOS/RDF model (skos:Concept, skos:broader, skos:prefLabel) plus bespoke essential/optional skill-occupation predicates — it is already shaped like a graph rather than a set of normalized tables.
Built-in organizing principle. ESCO itself splits into three pillars — Occupations, Skills & Competences, and Qualifications — which maps directly onto the :Pillar modeling requirement for this sprint.
Stable cross-reference keys. Occupations map to ISCO-08 codes; this gives a second usable hierarchy (:ISCOGroup) on top of the native skill/occupation taxonomy.

Correction made mid-sprint: early reference material pointed at the O*NET (US DOL) data dictionary instead of ESCO. O*NET and ESCO are structurally different datasets (O*NET is relational text files keyed on O*NET-SOC Code / Element ID; ESCO is SKOS/RDF keyed on URIs) — the data dictionary was swapped for the correct ESCO documentation before modeling began.


Data source and license
Item
Detail
Release
ESCO Classification dataset v1.2.1 (English)
Publisher
European Commission, DG Employment, Social Affairs and Inclusion
Download
ESCO portal Download section (CSV package, English)
License
Creative Commons Attribution 4.0 International (CC BY 4.0)
Formats available
CSV, RDF, TTL, ODS, XML, JSON-LD


ESCO v1.2.1 is a minor release — translation and content-quality fixes to the v1.2 major release, not a structural change — so the v1.2 modeling assumptions (pillars, ISCO-08 mapping, essential/optional skill semantics) hold for this dataset.

Attribution: This work includes information from the ESCO classification, published by the European Commission. © European Union, 2025. Licensed under CC BY 4.0.


Graph model
Pillars (organizing principle)
ESCO's own three-pillar structure was implemented as :Pillar nodes connected to the relevant hierarchy roots via PART_OF_PILLAR:

Pillar
Status
Connects to
Occupations
Implemented
:ISCOGroup / :Occupation roots
Skills and Competences
Implemented
:SkillGroup / :Skill roots
Qualifications
Deferred (placeholder)
:Qualification (not yet populated — needs EQF-linked registry data, separate from the core ESCO CSVs)


graph TB

  P1((Pillar: Occupations))

  P2((Pillar: Skills and Competences))

  P3((Pillar: Qualifications<br/>· placeholder ·))

  P1 -->|PART_OF_PILLAR| ISCO[ISCOGroup roots]

  P2 -->|PART_OF_PILLAR| SG[SkillGroup roots]

  P3 -.->|deferred| Q[Qualification — v2]
Node labels and relationships
Node label
Notes
:Occupation
ESCO occupation concepts
:ISCOGroup
ISCO-08 classification groups; code typed as string to preserve leading zeros
:Skill
ESCO skill/competence concepts
:SkillGroup
ESCO skill hierarchy groups; code typed as string
:Qualification
Deferred — empty, documented placeholder
:Pillar
3-pillar organizing principle


Relationship types (10 total, confirmed):

(:Occupation)-[:REQUIRES_ESSENTIAL_SKILL]->(:Skill)

(:Occupation)-[:MAY_REQUIRE_OPTIONAL_SKILL]->(:Skill)

(:Skill)-[:REQUIRES_ESSENTIAL_SKILL]->(:Skill)        // reused semantics, skill-to-skill

(:Skill)-[:MAY_REQUIRE_OPTIONAL_SKILL]->(:Skill)      // reused semantics, skill-to-skill

(:Occupation)-[:CLASSIFIED_UNDER]->(:ISCOGroup)

(:ISCOGroup)-[:IS_BROADER_THAN]->(:ISCOGroup)

(:SkillGroup)-[:IS_BROADER_THAN]->(:SkillGroup)

(:Skill)-[:PART_OF]->(:SkillGroup)

(:ISCOGroup)-[:PART_OF_PILLAR]->(:Pillar)

(:SkillGroup)-[:PART_OF_PILLAR]->(:Pillar)

Loaded size (current):

Metric
Count
Occupation nodes
3,039 (expected 3,043 — discrepancy open, see retrospective)
Skill nodes
13,939 (expected 13,960 — discrepancy open)
SkillGroup nodes
640
Relationships (total)
~156,000

Verification anchors
10 root ISCOGroup nodes = ISCO-08 major groups (codes 0–9)
4 root SkillGroup nodes = ESCO's S/K/L/T pillar branches

These were used as sanity checks after each ingestion pass — if the root counts drift from 10 and 4, the hierarchy import broke somewhere upstream.


Reproduce this build
ESCO is delivered as flat CSV files; Neo4j AuraDB doesn't expose a server-side plugin layer (Bolt only), which rules out one common RDF-import path:

Approach
Verdict
n10s (Neosemantics)
❌ Not usable on AuraDB — requires server-side plugin installation, which Aura doesn't expose
Aura Data Importer (CSV)
✅ Used for this build — graphical model + CSV mapping over Bolt
rdflib-neo4j
✅ Viable alternative — client-side RDF ingestion over Bolt, not used here but documented as a fallback

Steps taken
Created an AuraDB Free instance via the Aura Console.
Designed the property graph model in Data Importer (Define Manually): node labels typed exactly as the target Cypher labels (e.g. Occupation, not a descriptive variant like "Occupation Job Profile" — the importer requires an exact match).
Uploaded the ESCO CSVs (occupations, skills, skill groups, ISCO groups, and the occupation–skill / skill–skill relation files) and mapped columns to node/relationship properties.
Mapped relationships using From/To node-label ID matching on the ESCO concept URIs. Because the importer only supports one filter condition per relationship, coarser filters were used in combination with correct label matching — unresolved rows drop safely since ESCO URIs are namespaced per concept type and never collide across node types.
Ran the import, then verified against the anchor counts above.
Cleaned up leftover Northwind tutorial nodes from the initial Aura walkthrough via DETACH DELETE (tracked in the retrospective — not yet executed at time of writing).


Tutorial — key Cypher patterns
Constraints (string types preserve leading zeros on codes):

CREATE CONSTRAINT occupation_uri IF NOT EXISTS

FOR (o:Occupation) REQUIRE o.uri IS UNIQUE;

CREATE CONSTRAINT skill_uri IF NOT EXISTS

FOR (s:Skill) REQUIRE s.uri IS UNIQUE;

CREATE CONSTRAINT iscogroup_code IF NOT EXISTS

FOR (i:ISCOGroup) REQUIRE i.code IS UNIQUE;

Pillar attachment (organizing principle):

MERGE (p:Pillar {name: "Skills and Competences"})

WITH p

MATCH (sg:SkillGroup) WHERE NOT EXISTS {

  MATCH ()-[:IS_BROADER_THAN]->(sg)

}

MERGE (sg)-[:PART_OF_PILLAR]->(p)

altLabel post-processing (ESCO stores alternate labels newline-delimited in a single CSV cell):

MATCH (n:Skill)

WHERE n.altLabel_en IS NOT NULL

SET n.altLabels = split(n.altLabel_en, '\n')

Definition vs. description: definition is ~0% filled on both Occupation and Skill — it's skipped entirely. description is the 100%-filled human-readable field and is the one actually used in queries.


Example questions answered (Query deliverable)
The full Cypher is in ESCO_KG_Query_Deliverable.md. Summary of what the graph answers:

Question
Query type
Which skills are most in demand across occupations?
Skill-demand ranking
Which occupations share the most essential skills with this one?
Career-transition via shared essential skills (raw count + Jaccard-normalized)
What skills does a person need to add to qualify for occupation X?
Skill-gap analysis
How is a given skill positioned in the taxonomy?
Skill taxonomy browsing



What I learned
Theory
A knowledge graph's value over a relational model shows up exactly where ESCO already lives: multi-hop traversal (occupation → skill → related skill → other occupations) without reconstructing relationships through joins.
MERGE + constraints are what make CSV re-imports idempotent — critical since ESCO ships minor-version updates (like the v1.2 → v1.2.1 jump) that shouldn't duplicate the graph on re-run.
Conceptual model and physical model collapse into one artifact in a property graph — what you sketch in Data Importer is what gets queried, with no separate logical-to-physical translation step.
Practice (ESCO-specific)
ESCO vs. O*NET are not interchangeable — different structures, different keys, different licensing. Confirming the correct dataset before modeling avoided a costly rebuild.
model.rdf is the ESCO ontology (OWL classes/properties) — not instance data. Importing it would not populate actual occupations or skills.
skillSkillRelations.csv uses essential/optional semantics rather than a symmetric skos:related — so reusing REQUIRES_ESSENTIAL_SKILL / MAY_REQUIRE_OPTIONAL_SKILL for skill-to-skill edges was correct; no separate RELATED_TO type was needed.
Data Importer's single-filter-per-relationship limit required coarser filters combined with precise label matching rather than compound conditions.
What was hard
n10s on AuraDB was the initial plan (per early role configuration) — discovered early that Aura only exposes Bolt, no server-side plugins, ruling it out. Corrected to Data Importer / rdflib-neo4j.
Property type drift — code fields needed explicit string typing to avoid losing ISCO-08 leading zeros; this is easy to miss in a CSV-driven import where the importer may infer integer.
Multilingual properties — deciding between language-suffixed keys (prefLabel_en) vs. JSON-string properties; settled on language-suffixed keys for simplicity at v1 scope (English only).


Open issues — sprint retrospective
#
Issue
Status / remediation path
1
Node count discrepancies: Occupation (3,039 vs. expected 3,043), Skill (13,939 vs. expected 13,960)
Root cause not yet identified — likely candidates: filtered/dropped rows during URI-based From/To matching, or version-delta differences in the v1.2.1 source files. Needs row-level diffing against the raw CSVs.
2
SkillGroup code is null across all 640 nodes
Diagnosed as a Data Importer property-mapping error, not missing source data. Remediation: re-examine the skillGroups_en.csv column mapping in the importer and re-run with a MERGE-based LOAD CSV patch to fix existing nodes without duplicating them.
3
Leftover Northwind tutorial data in the Aura instance
Needs a DETACH DELETE cleanup pass before the instance is considered production-clean.



On the horizon
Qualifications pillar (v2) — requires EQF-linked registry data, separate from the core ESCO CSVs used in v1.
Root-cause investigation for the node count discrepancies (#1 above).
SkillGroup code remediation (#2 above).


Attribution (required)
This work includes information from the ESCO classification (European Skills, Competences, Qualifications and Occupations), developed and maintained by the European Commission, Directorate-General for Employment, Social Affairs and Inclusion. ESCO is made available under the Creative Commons Attribution 4.0 International (CC BY 4.0) license.