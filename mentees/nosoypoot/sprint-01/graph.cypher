// Sprint 1 — Lightcast Knowledge Graph slice (illustrative sample)
// Node ids prefixed "demo:" are placeholders, NOT real Lightcast ids.
// Real ids come from the Open Skills API (https://docs.lightcast.io/apis/skills).
// Run on a clean Neo4j database.

// ---------- Constraints ----------
CREATE CONSTRAINT skill_id IF NOT EXISTS
FOR (s:Skill) REQUIRE s.source_id IS UNIQUE;
CREATE CONSTRAINT spec_occ_id IF NOT EXISTS
FOR (o:SpecializedOccupation) REQUIRE o.source_id IS UNIQUE;

// ---------- Skill hierarchy: Category -> Subcategory -> Skill ----------
CREATE (catIT:SkillCategory {source: "lightcast", source_id: "demo:cat-it", name: "Information Technology"})
CREATE (catHW:SkillCategory {source: "lightcast", source_id: "demo:cat-human", name: "Human Skills"})

CREATE (subAI:SkillSubcategory {source: "lightcast", source_id: "demo:sub-ai", name: "Artificial Intelligence"})
CREATE (subDB:SkillSubcategory {source: "lightcast", source_id: "demo:sub-db", name: "Databases"})
CREATE (subPL:SkillSubcategory {source: "lightcast", source_id: "demo:sub-pl", name: "Programming Languages"})
CREATE (subCM:SkillSubcategory {source: "lightcast", source_id: "demo:sub-comm", name: "Communication"})

CREATE (catIT)-[:CONTAINS]->(subAI)
CREATE (catIT)-[:CONTAINS]->(subDB)
CREATE (catIT)-[:CONTAINS]->(subPL)
CREATE (catHW)-[:CONTAINS]->(subCM)

CREATE (ml:Skill {source: "lightcast", source_id: "demo:skill-ml", name: "Machine Learning", type: "Specialized Skill"})
CREATE (py:Skill {source: "lightcast", source_id: "demo:skill-python", name: "Python (Programming Language)", type: "Specialized Skill"})
CREATE (sql:Skill {source: "lightcast", source_id: "demo:skill-sql", name: "SQL (Programming Language)", type: "Specialized Skill"})
CREATE (dl:Skill {source: "lightcast", source_id: "demo:skill-dl", name: "Deep Learning", type: "Specialized Skill"})
CREATE (viz:Skill {source: "lightcast", source_id: "demo:skill-viz", name: "Data Visualization", type: "Specialized Skill"})
CREATE (comm:Skill {source: "lightcast", source_id: "demo:skill-comm", name: "Communication", type: "Common Skill"})
CREATE (awsc:Skill {source: "lightcast", source_id: "demo:skill-awscert", name: "AWS Certified Machine Learning", type: "Certification"})

CREATE (subAI)-[:CONTAINS]->(ml)
CREATE (subAI)-[:CONTAINS]->(dl)
CREATE (subAI)-[:CONTAINS]->(awsc)
CREATE (subPL)-[:CONTAINS]->(py)
CREATE (subDB)-[:CONTAINS]->(sql)
CREATE (subDB)-[:CONTAINS]->(viz)
CREATE (subCM)-[:CONTAINS]->(comm)

// ---------- LOT: CareerArea -> OccupationGroup -> Occupation -> SpecializedOccupation ----------
CREATE (ca:CareerArea {source: "lightcast", source_id: "demo:ca-it", name: "Information Technology and Computer Science"})
CREATE (og:OccupationGroup {source: "lightcast", source_id: "demo:og-swdev", name: "Software Development and Data Science"})
CREATE (occDev:Occupation {source: "lightcast", source_id: "demo:occ-swdev", name: "Software Developer / Engineer"})
CREATE (occAn:Occupation {source: "lightcast", source_id: "demo:occ-danalyst", name: "Data / Business Analyst"})

CREATE (soMLE:SpecializedOccupation {source: "lightcast", source_id: "demo:so-mle", name: "Machine Learning Engineer"})
CREATE (soDE:SpecializedOccupation {source: "lightcast", source_id: "demo:so-de", name: "Data Engineer"})
CREATE (soDA:SpecializedOccupation {source: "lightcast", source_id: "demo:so-da", name: "Data Analyst"})

CREATE (ca)-[:CONTAINS]->(og)
CREATE (og)-[:CONTAINS]->(occDev)
CREATE (og)-[:CONTAINS]->(occAn)
CREATE (occDev)-[:CONTAINS]->(soMLE)
CREATE (occDev)-[:CONTAINS]->(soDE)
CREATE (occAn)-[:CONTAINS]->(soDA)

// ---------- Crosswalk to SOC (bridge to BLS / O*NET) ----------
CREATE (soc1:CrosswalkCode {scheme: "SOC", code: "15-1252", name: "Software Developers"})
CREATE (soc2:CrosswalkCode {scheme: "SOC", code: "15-2051", name: "Data Scientists"})
CREATE (occDev)-[:CROSSWALKS_TO]->(soc1)
CREATE (occAn)-[:CROSSWALKS_TO]->(soc2)

// ---------- Job title normalization layer ----------
CREATE (t1:JobTitle {source: "lightcast", source_id: "demo:title-1", raw: "ML Ninja"})
CREATE (t2:JobTitle {source: "lightcast", source_id: "demo:title-2", raw: "Machine Learning Engineer II"})
CREATE (t3:JobTitle {source: "lightcast", source_id: "demo:title-3", raw: "BI & Data Analyst"})
CREATE (t1)-[:NORMALIZES_TO]->(soMLE)
CREATE (t2)-[:NORMALIZES_TO]->(soMLE)
CREATE (t3)-[:NORMALIZES_TO]->(soDA)

// ---------- Occupation -> Skill (weighted: significance is illustrative) ----------
CREATE (soMLE)-[:REQUIRES {significance: 0.95}]->(ml)
CREATE (soMLE)-[:REQUIRES {significance: 0.90}]->(py)
CREATE (soMLE)-[:REQUIRES {significance: 0.70}]->(dl)
CREATE (soMLE)-[:REQUIRES {significance: 0.40}]->(sql)
CREATE (soMLE)-[:REQUIRES {significance: 0.30}]->(awsc)
CREATE (soDE)-[:REQUIRES {significance: 0.90}]->(sql)
CREATE (soDE)-[:REQUIRES {significance: 0.85}]->(py)
CREATE (soDA)-[:REQUIRES {significance: 0.90}]->(sql)
CREATE (soDA)-[:REQUIRES {significance: 0.75}]->(viz)
CREATE (soDA)-[:REQUIRES {significance: 0.60}]->(py)
CREATE (soDA)-[:REQUIRES {significance: 0.55}]->(comm)
CREATE (soMLE)-[:REQUIRES {significance: 0.50}]->(comm);
