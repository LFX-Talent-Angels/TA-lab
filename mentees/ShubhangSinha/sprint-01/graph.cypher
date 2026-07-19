// Sprint 1 — SFIA Knowledge Graph slice (illustrative sample)
//
// Categories in this slice:
//   Strategy and architecture > Strategy and planning  : ITSP, ISCO, IRMG
//   Development and implementation > Systems development : PROG, TEST
//
// SFIA licensing is restrictive (see NOTES.md): the level descriptions below
// are short paraphrases for learning purposes, NOT verbatim SFIA text.
//
// ID conventions:
//   - Every node carries source: "sfia" and a source_id.
//   - SFIA skill codes (ITSP, ISCO, ...) are the natural source_ids for skills.
//   - Skill levels use "<CODE>-<level>" (e.g. "ITSP-4").
//   - Categories/subcategories have no official SFIA codes, so slugs are used.
//
// Run on a clean Neo4j database.

// ---------- Constraints ----------
CREATE CONSTRAINT sfia_category_id IF NOT EXISTS
FOR (c:Category) REQUIRE c.source_id IS UNIQUE;
CREATE CONSTRAINT sfia_subcategory_id IF NOT EXISTS
FOR (sc:Subcategory) REQUIRE sc.source_id IS UNIQUE;
CREATE CONSTRAINT sfia_skill_id IF NOT EXISTS
FOR (s:Skill) REQUIRE s.source_id IS UNIQUE;
CREATE CONSTRAINT sfia_skill_level_id IF NOT EXISTS
FOR (l:SkillLevel) REQUIRE l.source_id IS UNIQUE;

// ---------- Categories and subcategories ----------
CREATE (catSA:Category {source: "sfia", source_id: "cat:strategy-and-architecture", name: "Strategy and architecture"})
CREATE (catDI:Category {source: "sfia", source_id: "cat:development-and-implementation", name: "Development and implementation"})

CREATE (subSP:Subcategory {source: "sfia", source_id: "sub:strategy-and-planning", name: "Strategy and planning"})
CREATE (subSD:Subcategory {source: "sfia", source_id: "sub:systems-development", name: "Systems development"})

CREATE (catSA)-[:HAS_SUBCATEGORY]->(subSP)
CREATE (catDI)-[:HAS_SUBCATEGORY]->(subSD)

// ---------- ITSP — Strategic planning ----------
CREATE (itsp:Skill {source: "sfia", source_id: "ITSP", code: "ITSP", name: "Strategic planning"})
CREATE (subSP)-[:HAS_SKILL]->(itsp)

CREATE (itsp_l4:SkillLevel {source: "sfia", source_id: "ITSP-4", level: 4,
  description: "Contributes to the collection and analysis of information to support strategy development."})
CREATE (itsp_l5:SkillLevel {source: "sfia", source_id: "ITSP-5", level: 5,
  description: "Collates information and creates reports and insights to support strategy management processes."})
CREATE (itsp_l6:SkillLevel {source: "sfia", source_id: "ITSP-6", level: 6,
  description: "Sets policies, standards and guidelines for how the organisation conducts strategy development and planning."})
CREATE (itsp_l7:SkillLevel {source: "sfia", source_id: "ITSP-7", level: 7,
  description: "Leads the definition, implementation and communication of the organisation's strategic management framework."})

CREATE (itsp)-[:HAS_LEVEL]->(itsp_l4)
CREATE (itsp)-[:HAS_LEVEL]->(itsp_l5)
CREATE (itsp)-[:HAS_LEVEL]->(itsp_l6)
CREATE (itsp)-[:HAS_LEVEL]->(itsp_l7)

// ---------- ISCO - Information systems coordination ----------
CREATE (isco:Skill {source: "sfia", source_id: "ISCO", code: "ISCO", name: "Information systems coordination"})
CREATE (subSP)-[:HAS_SKILL]->(isco)

CREATE (isco_l6:SkillLevel {source: "sfia", source_id: "ISCO-6", level: 6,
  description: "Maintains awareness of the global needs of the organisation and coordinates implementation of information systems and services."})
CREATE (isco_l7:SkillLevel {source: "sfia", source_id: "ISCO-7", level: 7,
  description: "Establishes the organisation's strategy for managing information and coordinates lifecycle management of information systems."})

CREATE (isco)-[:HAS_LEVEL]->(isco_l6)
CREATE (isco)-[:HAS_LEVEL]->(isco_l7)

// ---------- IRMG — Information management ----------
CREATE (irmg:Skill {source: "sfia", source_id: "IRMG", code: "IRMG", name: "Information management"})
CREATE (subSP)-[:HAS_SKILL]->(irmg)

CREATE (irmg_l3:SkillLevel {source: "sfia", source_id: "IRMG-3", level: 3,
  description: "Supports teams and individuals to identify and organise information assets and repositories."})
CREATE (irmg_l4:SkillLevel {source: "sfia", source_id: "IRMG-4", level: 4,
  description: "Enables the organisation to organise, control and discover information assets."})
CREATE (irmg_l5:SkillLevel {source: "sfia", source_id: "IRMG-5", level: 5,
  description: "Ensures implementation of information and records management policies and standards."})
CREATE (irmg_l6:SkillLevel {source: "sfia", source_id: "IRMG-6", level: 6,
  description: "Leads and plans activities to communicate and implement information management strategies."})
CREATE (irmg_l7:SkillLevel {source: "sfia", source_id: "IRMG-7", level: 7,
  description: "Establishes and communicates the organisation's information management strategy."})

CREATE (irmg)-[:HAS_LEVEL]->(irmg_l3)
CREATE (irmg)-[:HAS_LEVEL]->(irmg_l4)
CREATE (irmg)-[:HAS_LEVEL]->(irmg_l5)
CREATE (irmg)-[:HAS_LEVEL]->(irmg_l6)
CREATE (irmg)-[:HAS_LEVEL]->(irmg_l7)

// ---------- PROG — Programming/software development (second category) ----------
// Only two of PROG's levels (2-6 in SFIA) are modelled here — small slice.
CREATE (prog:Skill {source: "sfia", source_id: "PROG", code: "PROG", name: "Programming/software development"})
CREATE (subSD)-[:HAS_SKILL]->(prog)

CREATE (prog_l3:SkillLevel {source: "sfia", source_id: "PROG-3", level: 3,
  description: "Designs, codes, verifies, tests and documents moderately complex programs and scripts from agreed specifications."})
CREATE (prog_l4:SkillLevel {source: "sfia", source_id: "PROG-4", level: 4,
  description: "Designs, codes, verifies, tests and documents complex programs; contributes to the selection of software development methods, tools and techniques."})

CREATE (prog)-[:HAS_LEVEL]->(prog_l3)
CREATE (prog)-[:HAS_LEVEL]->(prog_l4)

// ---------- TEST — Testing (second category) ----------
// Only two of TEST's levels (1-6 in SFIA) are modelled here — small slice.
CREATE (test:Skill {source: "sfia", source_id: "TEST", code: "TEST", name: "Testing"})
CREATE (subSD)-[:HAS_SKILL]->(test)

CREATE (test_l2:SkillLevel {source: "sfia", source_id: "TEST-2", level: 2,
  description: "Executes given test scripts under supervision; records and reports outcomes."})
CREATE (test_l4:SkillLevel {source: "sfia", source_id: "TEST-4", level: 4,
  description: "Selects appropriate testing approaches; designs test cases and test scripts; analyses and reports on test activities and results."})

CREATE (test)-[:HAS_LEVEL]->(test_l2)
CREATE (test)-[:HAS_LEVEL]->(test_l4)

// ---------- Crosswalks (illustrative) ----------
// SFIA publishes NO official crosswalks to ESCO / O*NET / SOC, and it has no
// occupations to crosswalk from. Occupation-less SFIA joins the other
// taxonomies through skill-to-skill mappings — the hand-made, illustrative
// edges below. "demo:" codes are placeholders: look up the real ESCO skill
// URIs before using this beyond learning.
CREATE (xProg:CrosswalkCode {scheme: "ESCO", code: "demo:esco-computer-programming", name: "computer programming"})
CREATE (xInfo:CrosswalkCode {scheme: "ESCO", code: "demo:esco-information-management", name: "manage data, information and digital content"})
CREATE (prog)-[:CROSSWALKS_TO {note: "hand-mapped, illustrative"}]->(xProg)
CREATE (irmg)-[:CROSSWALKS_TO {note: "hand-mapped, illustrative"}]->(xInfo);
