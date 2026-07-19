// Sprint 1 — ESCO Knowledge Graph slice (illustrative sample)
// Distilled from the full AuraDB build (see graph/model_ESCO_01/graph.cypher,
// the real importer script) and the inline sample
// (graph/model_occupations_example/ESCO_KG_Sample_From_Your_Script.cypher).
// Same labels, same relationship types, same essential/optional semantics —
// plus the workspace conventions for the integrated graph:
//   - every node carries `source: "esco"` and a `source_id`
//   - CROSSWALKS_TO edges to shared CrosswalkCode nodes (scheme: "ISCO"),
//     ESCO's bridge to the other taxonomies (ISCO <-> SOC connects to
//     O*NET / BLS).
//
// source_id notes:
//   - ISCOGroup URIs (http://data.europa.eu/esco/isco/C<code>) are the real,
//     deterministic ESCO URIs for ISCO-08 groups.
//   - Occupation/Skill URIs use the real ESCO namespaces
//     (http://data.europa.eu/esco/occupation/... , .../esco/skill/...) but the
//     UUID part here is an illustrative "0000-demo-*" placeholder — swap in
//     the real conceptUri values from the v1.2.1 CSVs before using this
//     beyond learning.
//
// Run on a clean Neo4j database (or re-run safely: MERGE + constraints keep
// it idempotent — the same property that makes ESCO minor-version re-imports
// safe in the full build).

// ---------- Constraints ----------
CREATE CONSTRAINT occupation_source_id IF NOT EXISTS
FOR (o:Occupation) REQUIRE o.source_id IS UNIQUE;
CREATE CONSTRAINT skill_source_id IF NOT EXISTS
FOR (s:Skill) REQUIRE s.source_id IS UNIQUE;
CREATE CONSTRAINT iscogroup_source_id IF NOT EXISTS
FOR (g:ISCOGroup) REQUIRE g.source_id IS UNIQUE;
CREATE CONSTRAINT skillgroup_source_id IF NOT EXISTS
FOR (sg:SkillGroup) REQUIRE sg.source_id IS UNIQUE;
CREATE CONSTRAINT crosswalk_scheme_code IF NOT EXISTS
FOR (x:CrosswalkCode) REQUIRE (x.scheme, x.code) IS UNIQUE;

// ---------- Build (single statement: variables stay bound throughout) ----------

// ISCO-08 hierarchy: major group -> unit groups
MERGE (isco2:ISCOGroup {source_id: "http://data.europa.eu/esco/isco/C2"})
  SET isco2.source = "esco", isco2.code = "2", isco2.prefLabel_en = "Professionals"
MERGE (isco25:ISCOGroup {source_id: "http://data.europa.eu/esco/isco/C25"})
  SET isco25.source = "esco", isco25.code = "25", isco25.prefLabel_en = "Information and communications technology professionals"
MERGE (isco251:ISCOGroup {source_id: "http://data.europa.eu/esco/isco/C251"})
  SET isco251.source = "esco", isco251.code = "251", isco251.prefLabel_en = "Software and applications developers and analysts"
MERGE (isco2511:ISCOGroup {source_id: "http://data.europa.eu/esco/isco/C2511"})
  SET isco2511.source = "esco", isco2511.code = "2511", isco2511.prefLabel_en = "Systems analysts"
MERGE (isco2512:ISCOGroup {source_id: "http://data.europa.eu/esco/isco/C2512"})
  SET isco2512.source = "esco", isco2512.code = "2512", isco2512.prefLabel_en = "Software developers"

MERGE (isco2512)-[:IS_BROADER_THAN]->(isco251)
MERGE (isco2511)-[:IS_BROADER_THAN]->(isco251)
MERGE (isco251)-[:IS_BROADER_THAN]->(isco25)
MERGE (isco25)-[:IS_BROADER_THAN]->(isco2)

// Occupations
MERGE (dev:Occupation {source_id: "http://data.europa.eu/esco/occupation/0000-demo-software-developer"})
  SET dev.source = "esco", dev.prefLabel_en = "software developer",
      dev.iscoGroup = "2512",
      dev.altLabels = ["programmer", "coder"],
      dev.description = "designs, codes, tests and maintains software applications"
MERGE (web:Occupation {source_id: "http://data.europa.eu/esco/occupation/0000-demo-web-developer"})
  SET web.source = "esco", web.prefLabel_en = "web developer",
      web.iscoGroup = "2512",
      web.altLabels = ["frontend developer"],
      web.description = "develops and maintains websites and web applications"
MERGE (ds:Occupation {source_id: "http://data.europa.eu/esco/occupation/0000-demo-data-scientist"})
  SET ds.source = "esco", ds.prefLabel_en = "data scientist",
      ds.iscoGroup = "2511",
      ds.altLabels = [],
      ds.description = "analyses large datasets to extract insights and build predictive models"
MERGE (sa:Occupation {source_id: "http://data.europa.eu/esco/occupation/0000-demo-systems-analyst"})
  SET sa.source = "esco", sa.prefLabel_en = "ICT system analyst",
      sa.iscoGroup = "2511",
      sa.altLabels = ["systems analyst"],
      sa.description = "studies, designs and improves ICT systems and infrastructure"

MERGE (dev)-[:CLASSIFIED_UNDER]->(isco2512)
MERGE (web)-[:CLASSIFIED_UNDER]->(isco2512)
MERGE (ds)-[:CLASSIFIED_UNDER]->(isco2511)
MERGE (sa)-[:CLASSIFIED_UNDER]->(isco2511)

// Skills (skillType / reuseLevel are real ESCO fields)
MERGE (py:Skill {source_id: "http://data.europa.eu/esco/skill/0000-demo-python"})
  SET py.source = "esco", py.prefLabel_en = "Python (computer programming)",
      py.skillType = "skill/competence", py.reuseLevel = "cross-sector"
MERGE (sql:Skill {source_id: "http://data.europa.eu/esco/skill/0000-demo-sql"})
  SET sql.source = "esco", sql.prefLabel_en = "use databases",
      sql.skillType = "skill/competence", sql.reuseLevel = "cross-sector"
MERGE (js:Skill {source_id: "http://data.europa.eu/esco/skill/0000-demo-js"})
  SET js.source = "esco", js.prefLabel_en = "JavaScript",
      js.skillType = "skill/competence", js.reuseLevel = "occupation-specific"
MERGE (git:Skill {source_id: "http://data.europa.eu/esco/skill/0000-demo-git"})
  SET git.source = "esco", git.prefLabel_en = "use version control software",
      git.skillType = "skill/competence", git.reuseLevel = "cross-sector"
MERGE (reqs:Skill {source_id: "http://data.europa.eu/esco/skill/0000-demo-reqs"})
  SET reqs.source = "esco", reqs.prefLabel_en = "analyse software specifications",
      reqs.skillType = "skill/competence", reqs.reuseLevel = "occupation-specific"
MERGE (ml:Skill {source_id: "http://data.europa.eu/esco/skill/0000-demo-ml"})
  SET ml.source = "esco", ml.prefLabel_en = "machine learning",
      ml.skillType = "knowledge", ml.reuseLevel = "sector-specific"
MERGE (stats:Skill {source_id: "http://data.europa.eu/esco/skill/0000-demo-stats"})
  SET stats.source = "esco", stats.prefLabel_en = "statistics",
      stats.skillType = "knowledge", stats.reuseLevel = "cross-sector"

// Skill hierarchy (ESCO S/K pillar branches)
MERGE (sgS4:SkillGroup {source_id: "http://data.europa.eu/esco/skill/0000-demo-sg-s4"})
  SET sgS4.source = "esco", sgS4.code = "S4", sgS4.prefLabel_en = "working with computers"
MERGE (sgK2:SkillGroup {source_id: "http://data.europa.eu/esco/skill/0000-demo-sg-k2"})
  SET sgK2.source = "esco", sgK2.code = "K2", sgK2.prefLabel_en = "engineering, manufacturing and construction"

MERGE (py)-[:PART_OF]->(sgS4)
MERGE (sql)-[:PART_OF]->(sgS4)
MERGE (js)-[:PART_OF]->(sgS4)
MERGE (git)-[:PART_OF]->(sgS4)
MERGE (reqs)-[:PART_OF]->(sgS4)
MERGE (ml)-[:PART_OF]->(sgK2)
MERGE (stats)-[:PART_OF]->(sgK2)

// Occupation -> Skill (ESCO's essential/optional distinction)
MERGE (dev)-[:REQUIRES_ESSENTIAL_SKILL]->(py)
MERGE (dev)-[:REQUIRES_ESSENTIAL_SKILL]->(git)
MERGE (dev)-[:REQUIRES_ESSENTIAL_SKILL]->(reqs)
MERGE (dev)-[:MAY_REQUIRE_OPTIONAL_SKILL]->(sql)
MERGE (dev)-[:MAY_REQUIRE_OPTIONAL_SKILL]->(js)
MERGE (web)-[:REQUIRES_ESSENTIAL_SKILL]->(js)
MERGE (web)-[:REQUIRES_ESSENTIAL_SKILL]->(git)
MERGE (web)-[:MAY_REQUIRE_OPTIONAL_SKILL]->(py)
MERGE (ds)-[:REQUIRES_ESSENTIAL_SKILL]->(py)
MERGE (ds)-[:REQUIRES_ESSENTIAL_SKILL]->(ml)
MERGE (ds)-[:REQUIRES_ESSENTIAL_SKILL]->(stats)
MERGE (ds)-[:MAY_REQUIRE_OPTIONAL_SKILL]->(sql)
MERGE (sa)-[:REQUIRES_ESSENTIAL_SKILL]->(reqs)
MERGE (sa)-[:REQUIRES_ESSENTIAL_SKILL]->(sql)

// Skill -> Skill (skillSkillRelations reuses the same semantics)
MERGE (ml)-[:REQUIRES_ESSENTIAL_SKILL]->(stats)
MERGE (ml)-[:MAY_REQUIRE_OPTIONAL_SKILL]->(py)

// Crosswalk to shared ISCO codes.
// CrosswalkCode nodes are the shared, taxonomy-neutral bridge nodes of the
// integrated graph: ESCO occupations attach here via their ISCO-08 unit
// group, and ISCO <-> SOC crosswalks connect the same nodes to O*NET / BLS.
MERGE (x2511:CrosswalkCode {scheme: "ISCO", code: "2511"})
  SET x2511.name = "Systems analysts"
MERGE (x2512:CrosswalkCode {scheme: "ISCO", code: "2512"})
  SET x2512.name = "Software developers"

MERGE (dev)-[:CROSSWALKS_TO]->(x2512)
MERGE (web)-[:CROSSWALKS_TO]->(x2512)
MERGE (ds)-[:CROSSWALKS_TO]->(x2511)
MERGE (sa)-[:CROSSWALKS_TO]->(x2511);
