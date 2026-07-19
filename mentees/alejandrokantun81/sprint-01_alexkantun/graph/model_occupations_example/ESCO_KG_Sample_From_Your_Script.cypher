// =====================================================================
// ESCO KG — SMALL SAMPLE, built from YOUR real importer script
// =====================================================================
// This is a shrunk-down version of your uploaded
// neo4j_importer_cypher_script_2026-06-23.cypher — same node labels,
// same property names, same relationship-loading logic — but the
// LOAD CSV sources are replaced with inline UNWIND data so you can
// paste this directly into the Aura Query tool with no files needed.
//
// TWO FIXES applied vs. your original script (flagged, not silent):
//   1. Label `Occupation ` (trailing space, your script line 23) -> `Occupation`
//   2. Property `prefLabel_en2` on Skill (your script line 86)   -> `prefLabel_en`
// If your live database was loaded with the original script, check
// whether your real :Occupation nodes actually carry a trailing-space
// label — that would silently break any query assuming a clean label.
// =====================================================================


// ---------------------------------------------------------------------
// 0. CLEANUP (safe to re-run — only removes nodes tagged 'sample-')
// ---------------------------------------------------------------------
MATCH (n) WHERE n.uri STARTS WITH 'sample-' DETACH DELETE n;


// ---------------------------------------------------------------------
// 1. CONSTRAINTS  (identical intent to your script, label space fixed)
// ---------------------------------------------------------------------
CREATE CONSTRAINT uri_Occupation_key IF NOT EXISTS
FOR (n:Occupation) REQUIRE (n.uri) IS NODE KEY;
CREATE CONSTRAINT uri_ISCOGroup_key IF NOT EXISTS
FOR (n:ISCOGroup) REQUIRE (n.uri) IS NODE KEY;
CREATE CONSTRAINT uri_Skill_key IF NOT EXISTS
FOR (n:Skill) REQUIRE (n.uri) IS NODE KEY;
CREATE CONSTRAINT uri_SkillGroup_key IF NOT EXISTS
FOR (n:SkillGroup) REQUIRE (n.uri) IS NODE KEY;


// =====================================================================
// 2. NODE LOAD  — same field names as your CSVs, data inlined via UNWIND
// =====================================================================

// --- file_0 equivalent: occupations_en.csv -> :Occupation ------------
UNWIND [
  {conceptUri:'sample-occ-software-developer', preferredLabel:'software developer', iscoGroup:'2512', description:'designs, codes, tests and maintains software applications', code:'2512.1', naceCode:'62.01', altLabels:'programmer\ncoder', regulatedProfessionNote:'', scopeNote:'', definition:''},
  {conceptUri:'sample-occ-web-developer',       preferredLabel:'web developer',       iscoGroup:'2512', description:'develops and maintains websites and web applications', code:'2512.2', naceCode:'62.01', altLabels:'frontend developer', regulatedProfessionNote:'', scopeNote:'', definition:''},
  {conceptUri:'sample-occ-data-scientist',       preferredLabel:'data scientist',       iscoGroup:'2511', description:'analyses large datasets to extract insights and build predictive models', code:'2511.1', naceCode:'62.02', altLabels:'', regulatedProfessionNote:'', scopeNote:'', definition:''},
  {conceptUri:'sample-occ-systems-analyst',      preferredLabel:'ICT systems analyst',  iscoGroup:'2511', description:'studies, designs and improves ICT systems and infrastructure', code:'2511.2', naceCode:'62.02', altLabels:'', regulatedProfessionNote:'', scopeNote:'', definition:''},
  {conceptUri:'sample-occ-qa-engineer',          preferredLabel:'quality assurance engineer', iscoGroup:'2512', description:'tests software to identify defects before release', code:'2512.3', naceCode:'62.01', altLabels:'QA tester', regulatedProfessionNote:'', scopeNote:'', definition:''}
] AS row
MERGE (n:Occupation {uri: row.conceptUri})
SET n.prefLabel_en = row.preferredLabel,
    n.iscoGroup = row.iscoGroup,
    n.description = row.description,
    n.code = row.code,
    n.naceCode = row.naceCode,
    n.altLabel_en = row.altLabels,
    n.regulatedProfessionNote = row.regulatedProfessionNote,
    n.scopeNote = row.scopeNote,
    n.definition = row.definition;

// --- file_1 equivalent: ISCOGroups_en.csv -> :ISCOGroup ---------------
UNWIND [
  {conceptUri:'sample-isco-2',    preferredLabel:'Professionals',                                              code:'2',    description:'', altLabels:'', status:'released'},
  {conceptUri:'sample-isco-25',   preferredLabel:'Information and communications technology professionals',    code:'25',   description:'', altLabels:'', status:'released'},
  {conceptUri:'sample-isco-251',  preferredLabel:'Software and applications developers and analysts',          code:'251',  description:'', altLabels:'', status:'released'},
  {conceptUri:'sample-isco-2511', preferredLabel:'Systems analysts',                                           code:'2511', description:'', altLabels:'', status:'released'},
  {conceptUri:'sample-isco-2512', preferredLabel:'Software developers',                                        code:'2512', description:'', altLabels:'', status:'released'}
] AS row
MERGE (n:ISCOGroup {uri: row.conceptUri})
SET n.prefLabel_en = row.preferredLabel,
    n.code = row.code,
    n.description = row.description,
    n.altLabel_en = row.altLabels,
    n.status = row.status;

// --- file_2 equivalent: skills_en.csv -> :Skill -----------------------
// NOTE: prefLabel_en2 in your script -> corrected to prefLabel_en here
UNWIND [
  {conceptUri:'sample-skill-python',   preferredLabel:'Python (computer programming)',     skillType:'skill/competence', reuseLevel:'cross-sector', description:'', altLabels:''},
  {conceptUri:'sample-skill-sql',      preferredLabel:'use database management systems',  skillType:'skill/competence', reuseLevel:'cross-sector', description:'', altLabels:''},
  {conceptUri:'sample-skill-js',       preferredLabel:'JavaScript',                        skillType:'skill/competence', reuseLevel:'occupation-specific', description:'', altLabels:''},
  {conceptUri:'sample-skill-git',      preferredLabel:'use version control software',      skillType:'skill/competence', reuseLevel:'cross-sector', description:'', altLabels:''},
  {conceptUri:'sample-skill-testing',  preferredLabel:'perform software testing',           skillType:'skill/competence', reuseLevel:'occupation-specific', description:'', altLabels:''},
  {conceptUri:'sample-skill-reqs',     preferredLabel:'analyse software specifications',    skillType:'skill/competence', reuseLevel:'occupation-specific', description:'', altLabels:''},
  {conceptUri:'sample-skill-ml',       preferredLabel:'machine learning',                  skillType:'knowledge',        reuseLevel:'sector-specific', description:'', altLabels:''},
  {conceptUri:'sample-skill-stats',    preferredLabel:'statistics',                        skillType:'knowledge',        reuseLevel:'cross-sector', description:'', altLabels:''}
] AS row
MERGE (n:Skill {uri: row.conceptUri})
SET n.prefLabel_en = row.preferredLabel,
    n.skillType = row.skillType,
    n.reuseLevel = row.reuseLevel,
    n.description = row.description,
    n.altLabel_en = row.altLabels;

// --- file_3 equivalent: skillGroups_en.csv -> :SkillGroup -------------
UNWIND [
  {conceptUri:'sample-sg-S4', preferredLabel:'working with computers', description:'', scopeNote:'', altLabels:'', status:'released'},
  {conceptUri:'sample-sg-K2', preferredLabel:'engineering, manufacturing and construction', description:'', scopeNote:'', altLabels:'', status:'released'}
] AS row
MERGE (n:SkillGroup {uri: row.conceptUri})
SET n.prefLabel_en = row.preferredLabel,
    n.description = row.description,
    n.scopeNote = row.scopeNote,
    n.altLabel_en = row.altLabels,
    n.status = row.status;


// =====================================================================
// 3. RELATIONSHIP LOAD — same filtering logic as your script,
//    inline data standing in for the broaderRelations / skillRelations files
// =====================================================================

// --- file_4 equivalent (broaderRelationsOccPillar): Occupation -[CLASSIFIED_UNDER]-> ISCOGroup ---
UNWIND [
  {conceptUri:'sample-occ-software-developer', broaderUri:'sample-isco-2512'},
  {conceptUri:'sample-occ-web-developer',       broaderUri:'sample-isco-2512'},
  {conceptUri:'sample-occ-qa-engineer',         broaderUri:'sample-isco-2512'},
  {conceptUri:'sample-occ-data-scientist',      broaderUri:'sample-isco-2511'},
  {conceptUri:'sample-occ-systems-analyst',     broaderUri:'sample-isco-2511'}
] AS row
MATCH (source:Occupation {uri: row.conceptUri})
MATCH (target:ISCOGroup {uri: row.broaderUri})
MERGE (source)-[:CLASSIFIED_UNDER]->(target);

// --- file_4 equivalent: ISCOGroup -[IS_BROADER_THAN]-> ISCOGroup ------
UNWIND [
  {conceptUri:'sample-isco-2512', broaderUri:'sample-isco-251'},
  {conceptUri:'sample-isco-2511', broaderUri:'sample-isco-251'},
  {conceptUri:'sample-isco-251',  broaderUri:'sample-isco-25'},
  {conceptUri:'sample-isco-25',   broaderUri:'sample-isco-2'}
] AS row
MATCH (source:ISCOGroup {uri: row.conceptUri})
MATCH (target:ISCOGroup {uri: row.broaderUri})
MERGE (source)-[:IS_BROADER_THAN]->(target);

// --- file_5 equivalent (occupationSkillRelations), relationType='essential' ---
UNWIND [
  {occupationUri:'sample-occ-software-developer', skillUri:'sample-skill-python'},
  {occupationUri:'sample-occ-software-developer', skillUri:'sample-skill-git'},
  {occupationUri:'sample-occ-software-developer', skillUri:'sample-skill-reqs'},
  {occupationUri:'sample-occ-web-developer',       skillUri:'sample-skill-js'},
  {occupationUri:'sample-occ-web-developer',       skillUri:'sample-skill-git'},
  {occupationUri:'sample-occ-data-scientist',      skillUri:'sample-skill-python'},
  {occupationUri:'sample-occ-data-scientist',      skillUri:'sample-skill-ml'},
  {occupationUri:'sample-occ-data-scientist',      skillUri:'sample-skill-stats'},
  {occupationUri:'sample-occ-systems-analyst',     skillUri:'sample-skill-reqs'},
  {occupationUri:'sample-occ-systems-analyst',     skillUri:'sample-skill-sql'},
  {occupationUri:'sample-occ-qa-engineer',         skillUri:'sample-skill-testing'},
  {occupationUri:'sample-occ-qa-engineer',         skillUri:'sample-skill-reqs'}
] AS row
MATCH (source:Occupation {uri: row.occupationUri})
MATCH (target:Skill {uri: row.skillUri})
MERGE (source)-[:REQUIRES_ESSENTIAL_SKILL]->(target);

// --- file_5 equivalent, relationType='optional' -----------------------
UNWIND [
  {occupationUri:'sample-occ-software-developer', skillUri:'sample-skill-sql'},
  {occupationUri:'sample-occ-software-developer', skillUri:'sample-skill-js'},
  {occupationUri:'sample-occ-web-developer',       skillUri:'sample-skill-python'},
  {occupationUri:'sample-occ-data-scientist',      skillUri:'sample-skill-sql'},
  {occupationUri:'sample-occ-qa-engineer',         skillUri:'sample-skill-git'}
] AS row
MATCH (source:Occupation {uri: row.occupationUri})
MATCH (target:Skill {uri: row.skillUri})
MERGE (source)-[:MAY_REQUIRE_OPTIONAL_SKILL]->(target);

// --- file_7 equivalent (skillSkillRelations), relationType='essential' ---
UNWIND [
  {originalSkillUri:'sample-skill-ml', relatedSkillUri:'sample-skill-stats'}
] AS row
MATCH (source:Skill {uri: row.originalSkillUri})
MATCH (target:Skill {uri: row.relatedSkillUri})
MERGE (source)-[:REQUIRES_ESSENTIAL_SKILL]->(target);

// --- file_7 equivalent, relationType='optional' -----------------------
UNWIND [
  {originalSkillUri:'sample-skill-ml', relatedSkillUri:'sample-skill-python'}
] AS row
MATCH (source:Skill {uri: row.originalSkillUri})
MATCH (target:Skill {uri: row.relatedSkillUri})
MERGE (source)-[:MAY_REQUIRE_OPTIONAL_SKILL]->(target);

// --- file_6 equivalent (broaderRelationsSkillPillar): Skill -[PART_OF]-> SkillGroup ---
UNWIND [
  {conceptUri:'sample-skill-python',  broaderUri:'sample-sg-S4'},
  {conceptUri:'sample-skill-sql',     broaderUri:'sample-sg-S4'},
  {conceptUri:'sample-skill-js',      broaderUri:'sample-sg-S4'},
  {conceptUri:'sample-skill-git',     broaderUri:'sample-sg-S4'},
  {conceptUri:'sample-skill-testing', broaderUri:'sample-sg-S4'},
  {conceptUri:'sample-skill-reqs',    broaderUri:'sample-sg-S4'},
  {conceptUri:'sample-skill-ml',      broaderUri:'sample-sg-K2'},
  {conceptUri:'sample-skill-stats',   broaderUri:'sample-sg-K2'}
] AS row
MATCH (source:Skill {uri: row.conceptUri})
MATCH (target:SkillGroup {uri: row.broaderUri})
MERGE (source)-[:PART_OF]->(target);

// NOTE: omitted from this sample (no representative data needed for a
// "handful of occupations" demo, but present in your full script):
//   - Occupation -[IS_BROADER_THAN]-> Occupation   (file_4, conceptType='Occupation')
//   - SkillGroup -[IS_BROADER_THAN]-> SkillGroup    (file_6, conceptType='SkillGroup')
//   - Skill -[IS_BROADER_THAN]-> Skill               (file_6, conceptType='KnowledgeSkillCompetence')


// =====================================================================
// 4. CHECK IT — visualize the handful of occupations + their skills
// =====================================================================
MATCH (o:Occupation)-[r:REQUIRES_ESSENTIAL_SKILL|MAY_REQUIRE_OPTIONAL_SKILL]->(s:Skill)
WHERE o.uri STARTS WITH 'sample-'
RETURN o, r, s;
