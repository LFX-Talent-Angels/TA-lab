// ============================================================
// SFIA Knowledge Graph - Draft Dataset
// Category: Strategy and architecture
// Subcategory: Strategy and planning
//
// Sample Skills:
//   - ITSP : Strategic planning
//   - ISCO : Information systems coordination
//   - IRMG : Information management
// ============================================================


// ============================================================
// Category and Subcategory
// ============================================================

MERGE (c:Category {
    name: "Strategy and architecture"
});

MERGE (sc:Subcategory {
    name: "Strategy and planning"
});

MERGE (c)-[:HAS_SUBCATEGORY]->(sc);


// ============================================================
// ITSP - Strategic Planning
// ============================================================

CREATE (itsp:Skill {
    code: "ITSP",
    name: "Strategic planning"
});

MERGE (sc)-[:HAS_SKILL]->(itsp);

CREATE (itsp_l4:SkillLevel {
    level: 4,
    description: "Contributes to the collection and analysis of information to support strategy development."
});

CREATE (itsp_l5:SkillLevel {
    level: 5,
    description: "Collates information and creates reports and insights to support strategy management processes."
});

CREATE (itsp_l6:SkillLevel {
    level: 6,
    description: "Sets policies, standards and guidelines for how the organisation conducts strategy development and planning."
});

CREATE (itsp_l7:SkillLevel {
    level: 7,
    description: "Leads the definition, implementation and communication of the organisation's strategic management framework."
});

MERGE (itsp)-[:HAS_LEVEL]->(itsp_l4);
MERGE (itsp)-[:HAS_LEVEL]->(itsp_l5);
MERGE (itsp)-[:HAS_LEVEL]->(itsp_l6);
MERGE (itsp)-[:HAS_LEVEL]->(itsp_l7);


// ============================================================
// ISCO - Information Systems Coordination
// ============================================================

CREATE (isco:Skill {
    code: "ISCO",
    name: "Information systems coordination"
});

MERGE (sc)-[:HAS_SKILL]->(isco);

CREATE (isco_l6:SkillLevel {
    level: 6,
    description: "Maintains awareness of the global needs of the organisation and coordinates implementation of information systems and services."
});

CREATE (isco_l7:SkillLevel {
    level: 7,
    description: "Establishes the organisation's strategy for managing information and coordinates lifecycle management of information systems."
});

MERGE (isco)-[:HAS_LEVEL]->(isco_l6);
MERGE (isco)-[:HAS_LEVEL]->(isco_l7);


// ============================================================
// IRMG - Information Management
// ============================================================

CREATE (irmg:Skill {
    code: "IRMG",
    name: "Information management"
});

MERGE (sc)-[:HAS_SKILL]->(irmg);

CREATE (irmg_l3:SkillLevel {
    level: 3,
    description: "Supports teams and individuals to identify and organise information assets and repositories."
});

CREATE (irmg_l4:SkillLevel {
    level: 4,
    description: "Enables the organisation to organise, control and discover information assets."
});

CREATE (irmg_l5:SkillLevel {
    level: 5,
    description: "Ensures implementation of information and records management policies and standards."
});

CREATE (irmg_l6:SkillLevel {
    level: 6,
    description: "Leads and plans activities to communicate and implement information management strategies."
});

CREATE (irmg_l7:SkillLevel {
    level: 7,
    description: "Establishes and communicates the organisation's information management strategy."
});

MERGE (irmg)-[:HAS_LEVEL]->(irmg_l3);
MERGE (irmg)-[:HAS_LEVEL]->(irmg_l4);
MERGE (irmg)-[:HAS_LEVEL]->(irmg_l5);
MERGE (irmg)-[:HAS_LEVEL]->(irmg_l6);
MERGE (irmg)-[:HAS_LEVEL]->(irmg_l7);


// ============================================================
// Visualisation Query
// ============================================================

MATCH p = ()-[r]->()
RETURN p;
