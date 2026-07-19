// Sprint 1 — Lightcast slice: example questions
// Framed as previews of the three core agents (Locator / Connector / Pathfinder).

// -- Locator: "Where does 'ML Ninja' live in the taxonomy?"
MATCH (t:JobTitle {raw: "ML Ninja"})-[:NORMALIZES_TO]->(so:SpecializedOccupation)
MATCH path = (ca:CareerArea)-[:CONTAINS*]->(so)
RETURN t.raw AS title, so.name AS specialized_occupation,
       [n IN nodes(path) | n.name] AS hierarchy;

// -- Connector: "What skills does a Machine Learning Engineer require,
//    and where does each skill sit in the skill hierarchy?"
MATCH (so:SpecializedOccupation {name: "Machine Learning Engineer"})
      -[r:REQUIRES]->(s:Skill)<-[:CONTAINS]-(sub:SkillSubcategory)<-[:CONTAINS]-(cat:SkillCategory)
RETURN s.name AS skill, s.type AS type, r.significance AS significance,
       sub.name AS subcategory, cat.name AS category
ORDER BY r.significance DESC;

// -- Connector (inverse): "Which occupations ask for SQL?"
MATCH (s:Skill {name: "SQL (Programming Language)"})<-[r:REQUIRES]-(so:SpecializedOccupation)
RETURN so.name AS occupation, r.significance AS significance
ORDER BY r.significance DESC;

// -- Pathfinder: "What connects Data Analyst to Machine Learning Engineer?"
//    Shared skills = the bridge of a possible learning journey.
MATCH (a:SpecializedOccupation {name: "Data Analyst"})-[:REQUIRES]->(s:Skill)
      <-[:REQUIRES]-(b:SpecializedOccupation {name: "Machine Learning Engineer"})
RETURN s.name AS shared_skill;

// -- Pathfinder (gap analysis, Evaluator preview): "What is the Data Analyst missing?"
MATCH (b:SpecializedOccupation {name: "Machine Learning Engineer"})-[r:REQUIRES]->(s:Skill)
WHERE NOT EXISTS {
  MATCH (:SpecializedOccupation {name: "Data Analyst"})-[:REQUIRES]->(s)
}
RETURN s.name AS missing_skill, r.significance AS significance
ORDER BY r.significance DESC;

// -- Crosswalk: "How does this occupation map to SOC (bridge to BLS / O*NET)?"
MATCH (occ:Occupation)-[:CROSSWALKS_TO]->(x:CrosswalkCode {scheme: "SOC"})
RETURN occ.name AS lightcast_occupation, x.code AS soc_code, x.name AS soc_name;
