// Sprint 1 — SFIA slice: example questions
// Framed as previews of the three core agents (Locator / Connector / Pathfinder).
//
// Important limitation: SFIA has NO occupations. Where the other taxonomies
// bridge two occupations through shared skills, here the bridges are shared
// responsibility levels and the category tree. Occupation-mediated journeys
// only become possible once SFIA skills are mapped to an occupation-centric
// taxonomy (see the crosswalk query at the bottom).

// -- Locator: "Where does 'Strategic planning' live in SFIA?"
MATCH (s:Skill {source: "sfia", code: "ITSP"})
      <-[:HAS_SKILL]-(sub:Subcategory)<-[:HAS_SUBCATEGORY]-(cat:Category)
OPTIONAL MATCH (s)-[:HAS_LEVEL]->(l:SkillLevel)
RETURN s.code AS code, s.name AS skill,
       sub.name AS subcategory, cat.name AS category,
       collect(l.level) AS defined_levels;

// -- Connector (outgoing): "What does Information management look like at each
//    responsibility level?" — the progression inside a single skill.
MATCH (s:Skill {source: "sfia", code: "IRMG"})-[:HAS_LEVEL]->(l:SkillLevel)
RETURN l.level AS level, l.description AS description
ORDER BY l.level;

// -- Connector (incoming): "Which skills are defined at responsibility level 6,
//    and where do they sit?" — levels as entry points, which is exactly what
//    modelling SkillLevel as first-class nodes buys us.
MATCH (s:Skill)-[:HAS_LEVEL]->(l:SkillLevel {level: 6})
MATCH (s)<-[:HAS_SKILL]-(sub:Subcategory)<-[:HAS_SUBCATEGORY]-(cat:Category)
RETURN s.code AS code, s.name AS skill,
       sub.name AS subcategory, cat.name AS category;

// -- Pathfinder (shared-level bridge): "What connects Information management to
//    Programming?" — no occupations in SFIA, so shared responsibility levels
//    are the bridge: the levels at which both skills are defined.
MATCH (a:Skill {source: "sfia", code: "IRMG"})-[:HAS_LEVEL]->(la:SkillLevel)
MATCH (b:Skill {source: "sfia", code: "PROG"})-[:HAS_LEVEL]->(lb:SkillLevel)
WHERE la.level = lb.level
RETURN la.level AS shared_level,
       la.description AS irmg_at_level,
       lb.description AS prog_at_level
ORDER BY shared_level;

// -- Pathfinder (category-tree bridge): shortest route between two skills in
//    different categories, walking up and down the hierarchy.
MATCH p = shortestPath(
  (a:Skill {source: "sfia", code: "ITSP"})-[:HAS_SKILL|HAS_SUBCATEGORY*..6]-(b:Skill {source: "sfia", code: "TEST"})
)
RETURN [n IN nodes(p) | coalesce(n.code, n.name)] AS route;

// -- Gap analysis (Evaluator preview): "I hold Information management at
//    level 4 — what is left to reach level 7?" — SFIA's natural gap is
//    vertical (level progression), not a missing-skills list.
MATCH (s:Skill {source: "sfia", code: "IRMG"})-[:HAS_LEVEL]->(l:SkillLevel)
WHERE l.level > 4
RETURN l.level AS level_to_reach, l.description AS what_it_takes
ORDER BY l.level;

// -- Crosswalk: "Which ESCO skills do our SFIA skills hand-map to?" — the only
//    door from occupation-less SFIA into the occupation-centric taxonomies.
MATCH (s:Skill {source: "sfia"})-[r:CROSSWALKS_TO]->(x:CrosswalkCode)
RETURN s.code AS sfia_code, s.name AS sfia_skill,
       x.scheme AS scheme, x.code AS code, x.name AS mapped_skill, r.note AS note;
