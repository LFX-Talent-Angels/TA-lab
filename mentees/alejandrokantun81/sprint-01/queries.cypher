// Sprint 1 — ESCO slice: example questions
// Framed as previews of the three core agents (Locator / Connector /
// Pathfinder), plus a gap-analysis Evaluator preview and a crosswalk query.
// Run against graph.cypher in this folder; the same queries work on the full
// AuraDB build (graph/model_ESCO_01/) at real scale.

// -- Locator: "I do frontend stuff — where am I in ESCO?"
//    Resolve messy input against prefLabel + altLabels, then anchor the hit
//    in the ISCO-08 hierarchy. (On the full build this is where a full-text
//    index over prefLabel_en / altLabels earns its keep.)
MATCH (o:Occupation)
WHERE toLower(o.prefLabel_en) CONTAINS "developer"
   OR any(a IN o.altLabels WHERE toLower(a) CONTAINS "frontend")
MATCH path = (o)-[:CLASSIFIED_UNDER]->(:ISCOGroup)-[:IS_BROADER_THAN*0..]->(root:ISCOGroup {code: "2"})
RETURN o.prefLabel_en AS occupation, o.source_id AS esco_uri,
       [n IN nodes(path)[1..] | n.code + " " + n.prefLabel_en] AS isco_hierarchy;

// -- Connector (outgoing): "What skills does 'data scientist' require,
//    split by ESCO's essential/optional distinction, and where does each
//    skill sit in the skill hierarchy?"
MATCH (o:Occupation {prefLabel_en: "data scientist"})
      -[r:REQUIRES_ESSENTIAL_SKILL|MAY_REQUIRE_OPTIONAL_SKILL]->(s:Skill)
OPTIONAL MATCH (s)-[:PART_OF]->(sg:SkillGroup)
RETURN s.prefLabel_en AS skill, type(r) AS relation,
       s.skillType AS skill_type, sg.prefLabel_en AS skill_group
ORDER BY relation, skill;

// -- Connector (incoming): "Which occupations need 'Python', and how badly?"
//    Essential vs. optional is the poor man's edge weight ESCO gives us.
MATCH (s:Skill {prefLabel_en: "Python (computer programming)"})
      <-[r:REQUIRES_ESSENTIAL_SKILL|MAY_REQUIRE_OPTIONAL_SKILL]-(o:Occupation)
RETURN o.prefLabel_en AS occupation, type(r) AS relation
ORDER BY relation, occupation;

// -- Pathfinder: "What connects 'web developer' to 'data scientist'?"
//    Shared skills form the bridge of a possible learning journey.
MATCH (a:Occupation {prefLabel_en: "web developer"})
      -[:REQUIRES_ESSENTIAL_SKILL|MAY_REQUIRE_OPTIONAL_SKILL]->(s:Skill)
      <-[:REQUIRES_ESSENTIAL_SKILL|MAY_REQUIRE_OPTIONAL_SKILL]-(b:Occupation {prefLabel_en: "data scientist"})
RETURN s.prefLabel_en AS shared_skill;

// -- Pathfinder (multi-hop): "Any route at all between the two occupations,
//    through skills or skill-to-skill relations?"
MATCH p = allShortestPaths(
  (a:Occupation {prefLabel_en: "web developer"})-[*..6]-(b:Occupation {prefLabel_en: "data scientist"})
)
RETURN [n IN nodes(p) | coalesce(n.prefLabel_en, n.code)] AS route, length(p) AS hops
LIMIT 5;

// -- Gap analysis (Evaluator preview): "What must a web developer still learn
//    to qualify as a data scientist?" Only ESSENTIAL skills count as blockers
//    — exploiting ESCO's essential/optional distinction; a target's optional
//    skills are nice-to-have, not gaps.
MATCH (target:Occupation {prefLabel_en: "data scientist"})-[:REQUIRES_ESSENTIAL_SKILL]->(s:Skill)
WHERE NOT EXISTS {
  MATCH (:Occupation {prefLabel_en: "web developer"})
        -[:REQUIRES_ESSENTIAL_SKILL|MAY_REQUIRE_OPTIONAL_SKILL]->(s)
}
RETURN s.prefLabel_en AS missing_essential_skill, s.skillType AS skill_type
ORDER BY missing_essential_skill;

// -- Crosswalk: "How do these ESCO occupations map to shared ISCO codes
//    (the bridge that connects — via ISCO <-> SOC — to O*NET / BLS)?"
MATCH (o:Occupation)-[:CROSSWALKS_TO]->(x:CrosswalkCode {scheme: "ISCO"})
RETURN o.prefLabel_en AS esco_occupation, x.code AS isco_code, x.name AS isco_name
ORDER BY isco_code, esco_occupation;
