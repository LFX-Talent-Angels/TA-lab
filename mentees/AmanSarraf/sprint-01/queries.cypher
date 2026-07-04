// =============================================================================
// Sprint 1 — O*NET knowledge graph example queries (Model A, 4-occupation slice)
// Run in Neo4j Aura Browser (Query / Explore) or via: python run_queries.py
// =============================================================================

// -----------------------------------------------------------------------------
// Q0: Find occupation by title (no SOC code needed)
// Use when you remember the job name, not the ID.
// -----------------------------------------------------------------------------
MATCH (o:Occupation)
WHERE toLower(o.title) CONTAINS "software developer"
RETURN o.title AS title, o.onet_soc_code AS code, o.description AS description;

// -----------------------------------------------------------------------------
// Q1: What skills does Software Developers require?
// Returns all skills with type, importance (IM), and level (LV).
// -----------------------------------------------------------------------------
MATCH (o:Occupation {onet_soc_code: "15-1252.00"})-[r:REQUIRES_SKILL]->(s:Skill)
RETURN s.name AS skill,
       r.skill_type AS type,
       r.importance AS importance,
       r.level AS level
ORDER BY r.importance DESC, s.name;

// -----------------------------------------------------------------------------
// Q1b: Same as Q1 but by title — more intuitive for humans
// -----------------------------------------------------------------------------
MATCH (o:Occupation)
WHERE toLower(o.title) = "software developers"
MATCH (o)-[r:REQUIRES_SKILL]->(s:Skill)
RETURN o.title AS occupation,
       s.name AS skill,
       r.skill_type AS type,
       r.importance AS importance,
       r.level AS level
ORDER BY r.importance DESC, s.name;

// -----------------------------------------------------------------------------
// Q2: Which occupations share the skill "Programming"?
// Same Skill node, different REQUIRES_SKILL edges with per-occupation scores.
// -----------------------------------------------------------------------------
MATCH (o:Occupation)-[r:REQUIRES_SKILL]->(s:Skill {name: "Programming"})
RETURN o.title AS occupation,
       o.onet_soc_code AS code,
       r.skill_type AS type,
       r.importance AS importance,
       r.level AS level
ORDER BY r.importance DESC;

// -----------------------------------------------------------------------------
// Q3: What tasks does Software Developers perform?
// -----------------------------------------------------------------------------
MATCH (o:Occupation {onet_soc_code: "15-1252.00"})-[:HAS_TASK]->(t:Task)
RETURN t.task_type AS type,
       t.text AS task
ORDER BY t.task_type, t.text;

// -----------------------------------------------------------------------------
// Q4: Which occupations use Python?
// -----------------------------------------------------------------------------
MATCH (o:Occupation)-[r:USES_SOFTWARE]->(sw:Software {name: "Python"})
RETURN o.title AS occupation,
       r.hot_technology AS hot,
       r.in_demand AS in_demand
ORDER BY o.title;

// -----------------------------------------------------------------------------
// Q5: In-demand software for Software Developers
// -----------------------------------------------------------------------------
MATCH (o:Occupation {onet_soc_code: "15-1252.00"})-[r:USES_SOFTWARE {in_demand: true}]->(sw:Software)
RETURN sw.name AS software,
       sw.category AS category,
       r.hot_technology AS hot
ORDER BY sw.name;

// -----------------------------------------------------------------------------
// Q6: Graph health check (node and relationship counts)
// -----------------------------------------------------------------------------
MATCH (n)
RETURN labels(n)[0] AS label, count(*) AS count
ORDER BY label;

// -----------------------------------------------------------------------------
// Q7: Top 10 most important transferable skills for SW Dev
// -----------------------------------------------------------------------------
MATCH (o:Occupation {onet_soc_code: "15-1252.00"})
      -[r:REQUIRES_SKILL {skill_type: "transferable"}]->(s:Skill)
RETURN s.name AS skill, r.importance AS importance, r.level AS level
ORDER BY r.importance DESC
LIMIT 10;

// -----------------------------------------------------------------------------
// Q8: Occupations most similar by shared skill count (all 4 in slice)
// -----------------------------------------------------------------------------
MATCH (o:Occupation)-[:REQUIRES_SKILL]->(s:Skill)<-[:REQUIRES_SKILL]-(other:Occupation)
WHERE o.onet_soc_code < other.onet_soc_code
RETURN o.title AS occupation_a,
       other.title AS occupation_b,
       count(s) AS shared_skills
ORDER BY shared_skills DESC;

// -----------------------------------------------------------------------------
// Q9: Graph view for one occupation by title (no SOC code) — use Graph tab
// CONTAINS is forgiving; exact match: toLower(o.title) = "software developers"
// -----------------------------------------------------------------------------
MATCH (o:Occupation)
WHERE toLower(o.title) CONTAINS "software developer"
OPTIONAL MATCH (o)-[t:HAS_TASK]->(task:Task)
OPTIONAL MATCH (o)-[sk:REQUIRES_SKILL]->(skill:Skill)
OPTIONAL MATCH (o)-[sw:USES_SOFTWARE]->(soft:Software)
RETURN o, t, task, sk, skill, sw, soft
LIMIT 80;