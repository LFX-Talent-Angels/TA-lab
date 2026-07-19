// NOTE: The following script syntax is valid for database version 5.0 and above.

:param {
  // Define the file path root and the individual file names required for loading.
  // https://neo4j.com/docs/operations-manual/current/configuration/file-locations/
  file_path_root: 'file:///', // Change this to the folder your script can access the files at.
  file_0: 'occupations_en.csv',
  file_1: 'ISCOGroups_en.csv',
  file_2: 'skills_en.csv',
  file_3: 'skillGroups_en.csv',
  file_4: 'broaderRelationsOccPillar_en.csv',
  file_5: 'occupationSkillRelations_en.csv',
  file_6: 'broaderRelationsSkillPillar_en.csv',
  file_7: 'skillSkillRelations_en.csv'
};

// CONSTRAINT creation
// -------------------
//
// Create key and uniqueness constraints for node labels and relationship types. This ensures ID property uniqueness and prevents duplicate entries from being introduced.
//
CREATE CONSTRAINT `uri_Occupation__key` IF NOT EXISTS
FOR (n: `Occupation `)
REQUIRE (n.`uri`) IS NODE KEY;
CREATE CONSTRAINT `uri_ISCOGroup_key` IF NOT EXISTS
FOR (n: `ISCOGroup`)
REQUIRE (n.`uri`) IS NODE KEY;
CREATE CONSTRAINT `uri_Skill_key` IF NOT EXISTS
FOR (n: `Skill`)
REQUIRE (n.`uri`) IS NODE KEY;
CREATE CONSTRAINT `uri_SkillGroup_key` IF NOT EXISTS
FOR (n: `SkillGroup`)
REQUIRE (n.`uri`) IS NODE KEY;

:param {
  idsToSkip: [],
  bracketPairs: [["{","}"],["<",">"],["[","]"],["(",")"]]
};

// NODE load
// ---------
//
// Load nodes in batches, one node label at a time. Nodes will be created using a MERGE statement to ensure a node with the same label and ID property remains unique. Pre-existing nodes found by a MERGE statement will have their other properties set to the latest values encountered in a load file.
//
// NOTE: Any nodes with IDs in the 'idsToSkip' list parameter will not be loaded.
LOAD CSV WITH HEADERS FROM ($file_path_root + $file_0) AS row
WITH row
WHERE NOT row.`conceptUri` IN $idsToSkip AND NOT row.`conceptUri` IS NULL
CALL (row) {
  MERGE (n: `Occupation ` { `uri`: row.`conceptUri` })
  SET n.`uri` = row.`conceptUri`
  SET n.`prefLabel_en` = row.`preferredLabel`
  SET n.`iscoGroup` = row.`iscoGroup`
  SET n.`description` = row.`description`
  SET n.`code` = row.`code`
  SET n.`naceCode` = row.`naceCode`
  SET n.`modifiedDate` = row.`modifiedDate`
  SET n.`altLabel_en` = row.`altLabels`
  SET n.`regulatedProfessionNote` = row.`regulatedProfessionNote`
  SET n.`scopeNote` = row.`scopeNote`
  SET n.`definition` = row.`definition`
  SET n.`inScheme` = row.`inScheme`
  SET n.`hiddenLabels` = row.`hiddenLabels`
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_1) AS row
WITH row
WHERE NOT row.`conceptUri` IN $idsToSkip AND NOT row.`conceptUri` IS NULL
CALL (row) {
  MERGE (n: `ISCOGroup` { `uri`: row.`conceptUri` })
  SET n.`uri` = row.`conceptUri`
  SET n.`prefLabel_en` = row.`preferredLabel`
  SET n.`code` = row.`code`
  SET n.`description` = row.`description`
  SET n.`altLabel_en` = row.`altLabels`
  SET n.`status` = row.`status`
  SET n.`inScheme` = row.`inScheme`
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_2) AS row
WITH row
WHERE NOT row.`conceptUri` IN $idsToSkip AND NOT row.`conceptUri` IS NULL
CALL (row) {
  MERGE (n: `Skill` { `uri`: row.`conceptUri` })
  SET n.`uri` = row.`conceptUri`
  SET n.`prefLabel_en2` = row.`preferredLabel`
  SET n.`skillType` = row.`skillType`
  SET n.`reuseLevel` = row.`reuseLevel`
  SET n.`description` = row.`description`
  SET n.`altLabel_en` = row.`altLabels`
  // Your script contains the datetime datatype. Our app attempts to convert dates to ISO 8601 date format before passing them to the Cypher function.
  // This conversion cannot be done in a Cypher script load. Please ensure that your CSV file columns are in ISO 8601 date format to ensure equivalent loads.
  SET n.`modifiedDate` = datetime(trim(row.`modifiedDate`))
  SET n.`status` = row.`status`
  SET n.`scopeNote` = row.`scopeNote`
  SET n.`definition` = row.`definition`
  SET n.`hiddenLabels` = row.`hiddenLabels`
  SET n.`inScheme` = row.`inScheme`
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_3) AS row
WITH row
WHERE NOT row.`conceptUri` IN $idsToSkip AND NOT row.`conceptUri` IS NULL
CALL (row) {
  MERGE (n: `SkillGroup` { `uri`: row.`conceptUri` })
  SET n.`uri` = row.`conceptUri`
  SET n.`prefLabel_en` = row.`preferredLabel`
  SET n.`description` = row.`description`
  SET n.`scopeNote` = row.`scopeNote`
  SET n.`altLabel_en` = row.`altLabels`
  SET n.`modifiedDate` = row.`modifiedDate`
  SET n.`status` = row.`status`
  SET n.`hiddenLabels` = row.`hiddenLabels`
  SET n.`inScheme` = row.`inScheme`
} IN TRANSACTIONS OF 10000 ROWS;


// RELATIONSHIP load
// -----------------
//
// Load relationships in batches, one relationship type at a time. Relationships are created using a MERGE statement, meaning only one relationship of a given type will ever be created between a pair of nodes.
LOAD CSV WITH HEADERS FROM ($file_path_root + $file_4) AS row
WITH row 
WHERE row.`broaderType` = 'ISCOGroup'
CALL (row) {
  MATCH (source: `Occupation ` { `uri`: row.`conceptUri` })
  MATCH (target: `ISCOGroup` { `uri`: row.`broaderUri` })
  MERGE (source)-[r: `CLASSIFIED_UNDER`]->(target)
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_4) AS row
WITH row 
WHERE row.`conceptType` = 'ISCOGroup'
CALL (row) {
  MATCH (source: `ISCOGroup` { `uri`: row.`conceptUri` })
  MATCH (target: `ISCOGroup` { `uri`: row.`broaderUri` })
  MERGE (source)-[r: `IS_BROADER_THAN`]->(target)
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_5) AS row
WITH row 
WHERE row.`relationType` = 'essential'
CALL (row) {
  MATCH (source: `Occupation ` { `uri`: row.`occupationUri` })
  MATCH (target: `Skill` { `uri`: row.`skillUri` })
  MERGE (source)-[r: `REQUIRES_ESSENTIAL_SKILL`]->(target)
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_7) AS row
WITH row 
WHERE row.`relationType` = 'optional'
CALL (row) {
  MATCH (source: `Skill` { `uri`: row.`originalSkillUri` })
  MATCH (target: `Skill` { `uri`: row.`relatedSkillUri` })
  MERGE (source)-[r: `MAY_REQUIRE_OPTIONAL_SKILL`]->(target)
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_5) AS row
WITH row 
WHERE row.`relationType` = 'optional'
CALL (row) {
  MATCH (source: `Occupation ` { `uri`: row.`occupationUri` })
  MATCH (target: `Skill` { `uri`: row.`skillUri` })
  MERGE (source)-[r: `MAY_REQUIRE_OPTIONAL_SKILL`]->(target)
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_4) AS row
WITH row 
WHERE row.`conceptType` = 'Occupation'
CALL (row) {
  MATCH (source: `Occupation ` { `uri`: row.`conceptUri` })
  MATCH (target: `Occupation ` { `uri`: row.`broaderUri` })
  MERGE (source)-[r: `IS_BROADER_THAN`]->(target)
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_6) AS row
WITH row 
WHERE row.`broaderType` = 'SkillGroup'
CALL (row) {
  MATCH (source: `Skill` { `uri`: row.`conceptUri` })
  MATCH (target: `SkillGroup` { `uri`: row.`broaderUri` })
  MERGE (source)-[r: `PART_OF`]->(target)
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_6) AS row
WITH row 
WHERE row.`conceptType` = 'SkillGroup'
CALL (row) {
  MATCH (source: `SkillGroup` { `uri`: row.`conceptUri` })
  MATCH (target: `SkillGroup` { `uri`: row.`broaderUri` })
  MERGE (source)-[r: `IS_BROADER_THAN`]->(target)
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_7) AS row
WITH row 
WHERE row.`relationType` = 'essential'
CALL (row) {
  MATCH (source: `Skill` { `uri`: row.`originalSkillUri` })
  MATCH (target: `Skill` { `uri`: row.`relatedSkillUri` })
  MERGE (source)-[r: `REQUIRES_ESSENTIAL_SKILL`]->(target)
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_6) AS row
WITH row 
WHERE row.`conceptType` = 'KnowledgeSkillCompetence'
CALL (row) {
  MATCH (source: `Skill` { `uri`: row.`conceptUri` })
  MATCH (target: `Skill` { `uri`: row.`broaderUri` })
  MERGE (source)-[r: `IS_BROADER_THAN`]->(target)
} IN TRANSACTIONS OF 10000 ROWS;
