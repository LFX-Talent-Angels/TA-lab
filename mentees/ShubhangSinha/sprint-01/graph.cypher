// Sprint 1 — SFIA Knowledge Graph slice (illustrative sample)
//
// Categories in this slice:
//   Strategy and architecture > Strategy and planning  : ITSP, ISCO, IRMG
//   Development and implementation > Systems development : PROG, TEST
//
// ⚠️ LICENSING — why there are no level descriptions here.
// SFIA's free licence covers INTERNAL use only; redistributing SFIA material
// to other organisations requires a fee-bearing licence, and this is a public
// repository under Apache-2.0. So this graph deliberately stores only what is
// factual and unprotected — skill codes, names, level numbers and structure —
// and NOT SFIA's descriptive text for each level.
//
// Look the descriptions up at https://sfia-online.org (free registration) and
// keep them local. This is also the architectural rule for TA-agents with any
// license-gated source: STORE THE POINTER, FETCH THE PAYLOAD AT RUNTIME.
// See NOTES.md for the licensing analysis.
//
// ID conventions:
//   - Every node carries source: "sfia" and a source_id.
//   - SFIA skill codes (ITSP, ISCO, ...) are the natural source_ids for skills.
//   - Skill levels use "<CODE>-<level>" (e.g. "ITSP-4").
//   - Categories/subcategories have no official SFIA codes, so slugs are used.
//   - sfia_ref is a citation, not content: it tells you what to look up.
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
CREATE (itsp:Skill {source: "sfia", source_id: "ITSP", code: "ITSP", name: "Strategic planning", sfia_ref: "SFIA 9 · ITSP"})
CREATE (subSP)-[:HAS_SKILL]->(itsp)

CREATE (itsp_l4:SkillLevel {source: "sfia", source_id: "ITSP-4", level: 4, sfia_ref: "SFIA 9 · ITSP level 4"})
CREATE (itsp_l5:SkillLevel {source: "sfia", source_id: "ITSP-5", level: 5, sfia_ref: "SFIA 9 · ITSP level 5"})
CREATE (itsp_l6:SkillLevel {source: "sfia", source_id: "ITSP-6", level: 6, sfia_ref: "SFIA 9 · ITSP level 6"})
CREATE (itsp_l7:SkillLevel {source: "sfia", source_id: "ITSP-7", level: 7, sfia_ref: "SFIA 9 · ITSP level 7"})

CREATE (itsp)-[:HAS_LEVEL]->(itsp_l4)
CREATE (itsp)-[:HAS_LEVEL]->(itsp_l5)
CREATE (itsp)-[:HAS_LEVEL]->(itsp_l6)
CREATE (itsp)-[:HAS_LEVEL]->(itsp_l7)

// ---------- ISCO — Information systems coordination ----------
// Note the code collision: SFIA's "ISCO" is unrelated to the ILO's ISCO
// occupation classification used by ESCO. This is exactly why every node
// carries source + source_id instead of a bare code.
CREATE (isco:Skill {source: "sfia", source_id: "ISCO", code: "ISCO", name: "Information systems coordination", sfia_ref: "SFIA 9 · ISCO"})
CREATE (subSP)-[:HAS_SKILL]->(isco)

CREATE (isco_l6:SkillLevel {source: "sfia", source_id: "ISCO-6", level: 6, sfia_ref: "SFIA 9 · ISCO level 6"})
CREATE (isco_l7:SkillLevel {source: "sfia", source_id: "ISCO-7", level: 7, sfia_ref: "SFIA 9 · ISCO level 7"})

CREATE (isco)-[:HAS_LEVEL]->(isco_l6)
CREATE (isco)-[:HAS_LEVEL]->(isco_l7)

// ---------- IRMG — Information management ----------
CREATE (irmg:Skill {source: "sfia", source_id: "IRMG", code: "IRMG", name: "Information management", sfia_ref: "SFIA 9 · IRMG"})
CREATE (subSP)-[:HAS_SKILL]->(irmg)

CREATE (irmg_l3:SkillLevel {source: "sfia", source_id: "IRMG-3", level: 3, sfia_ref: "SFIA 9 · IRMG level 3"})
CREATE (irmg_l4:SkillLevel {source: "sfia", source_id: "IRMG-4", level: 4, sfia_ref: "SFIA 9 · IRMG level 4"})
CREATE (irmg_l5:SkillLevel {source: "sfia", source_id: "IRMG-5", level: 5, sfia_ref: "SFIA 9 · IRMG level 5"})
CREATE (irmg_l6:SkillLevel {source: "sfia", source_id: "IRMG-6", level: 6, sfia_ref: "SFIA 9 · IRMG level 6"})
CREATE (irmg_l7:SkillLevel {source: "sfia", source_id: "IRMG-7", level: 7, sfia_ref: "SFIA 9 · IRMG level 7"})

CREATE (irmg)-[:HAS_LEVEL]->(irmg_l3)
CREATE (irmg)-[:HAS_LEVEL]->(irmg_l4)
CREATE (irmg)-[:HAS_LEVEL]->(irmg_l5)
CREATE (irmg)-[:HAS_LEVEL]->(irmg_l6)
CREATE (irmg)-[:HAS_LEVEL]->(irmg_l7)

// ---------- PROG — Programming/software development (second category) ----------
// Only two of PROG's levels (2-6 in SFIA) are modelled here — small slice.
CREATE (prog:Skill {source: "sfia", source_id: "PROG", code: "PROG", name: "Programming/software development", sfia_ref: "SFIA 9 · PROG"})
CREATE (subSD)-[:HAS_SKILL]->(prog)

CREATE (prog_l3:SkillLevel {source: "sfia", source_id: "PROG-3", level: 3, sfia_ref: "SFIA 9 · PROG level 3"})
CREATE (prog_l4:SkillLevel {source: "sfia", source_id: "PROG-4", level: 4, sfia_ref: "SFIA 9 · PROG level 4"})

CREATE (prog)-[:HAS_LEVEL]->(prog_l3)
CREATE (prog)-[:HAS_LEVEL]->(prog_l4)

// ---------- TEST — Testing (second category) ----------
// Only two of TEST's levels (1-6 in SFIA) are modelled here — small slice.
CREATE (test:Skill {source: "sfia", source_id: "TEST", code: "TEST", name: "Testing", sfia_ref: "SFIA 9 · TEST"})
CREATE (subSD)-[:HAS_SKILL]->(test)

CREATE (test_l2:SkillLevel {source: "sfia", source_id: "TEST-2", level: 2, sfia_ref: "SFIA 9 · TEST level 2"})
CREATE (test_l4:SkillLevel {source: "sfia", source_id: "TEST-4", level: 4, sfia_ref: "SFIA 9 · TEST level 4"})

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
