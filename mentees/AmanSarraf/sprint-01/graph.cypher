// =============================================================================
// Sprint 1 — O*NET knowledge graph: standalone illustrative slice (Model A)
//
// Quick-look version of the graph that `load_onet.py` builds from the real
// O*NET 30.3 files. Paste into any empty Neo4j instance — no data download
// needed. The loader remains the real path (758 nodes / 1,703 rels); this
// hand-written slice keeps only a few representative nodes per label.
//
// Conventions (project-wide, for the future integrated graph):
//   - Every node carries `source: "onet"` and a `source_id`.
//   - O*NET-SOC codes (15-1252.00) and Skill Element IDs (2.B.3.e) are real.
//     Task IDs and software categories are plausible placeholders — verify
//     against Task Statements.txt / Software Skills.txt before reusing.
//   - `CROSSWALKS_TO` edges point to shared-scheme codes: the first 7 chars
//     of an O*NET-SOC code ARE the SOC code (15-1252.00 → 15-1252), O*NET's
//     bridge to BLS and (via SOC ↔ ISCO) to ESCO.
//   - Same UNWIND + MERGE pattern as load_onet.py, so re-running is safe.
//
// Data source: O*NET 30.3 Database, USDOL/ETA, CC BY 4.0
// https://www.onetcenter.org/database.html
// =============================================================================

// ---------- Constraints (same as load_onet.py, plus crosswalk) ----------
CREATE CONSTRAINT occupation_code IF NOT EXISTS
FOR (o:Occupation) REQUIRE o.onet_soc_code IS UNIQUE;
CREATE CONSTRAINT task_id IF NOT EXISTS
FOR (t:Task) REQUIRE t.task_id IS UNIQUE;
CREATE CONSTRAINT skill_element IF NOT EXISTS
FOR (s:Skill) REQUIRE s.element_id IS UNIQUE;
CREATE CONSTRAINT software_name IF NOT EXISTS
FOR (sw:Software) REQUIRE sw.name IS UNIQUE;
CREATE CONSTRAINT crosswalk_code IF NOT EXISTS
FOR (x:CrosswalkCode) REQUIRE (x.scheme, x.code) IS UNIQUE;

// ---------- Occupations (the 4-occupation software cluster) ----------
UNWIND [
  {code: "15-1252.00", title: "Software Developers",
   description: "Research, design, and develop computer and network software or specialized utility programs."},
  {code: "15-1251.00", title: "Computer Programmers",
   description: "Create, modify, and test the code and scripts that allow computer applications to run."},
  {code: "15-1243.00", title: "Database Architects",
   description: "Design strategies for enterprise databases, data warehouse systems, and multidimensional networks."},
  {code: "15-1253.00", title: "Software Quality Assurance Analysts and Testers",
   description: "Develop and execute software tests to identify software problems and their causes."}
] AS row
MERGE (o:Occupation {onet_soc_code: row.code})
SET o.title = row.title,
    o.description = row.description,
    o.source = "onet",
    o.source_id = row.code;

// ---------- Skills (real Content Model Element IDs, shared nodes) ----------
UNWIND [
  {element_id: "2.B.3.e", name: "Programming",
   description: "Writing computer programs for various purposes."},
  {element_id: "2.A.2.a", name: "Critical Thinking",
   description: "Using logic and reasoning to identify the strengths and weaknesses of alternative solutions."},
  {element_id: "2.B.2.i", name: "Complex Problem Solving",
   description: "Identifying complex problems and reviewing related information to develop and evaluate options."},
  {element_id: "2.B.4.e", name: "Systems Analysis",
   description: "Determining how a system should work and how changes will affect outcomes."},
  {element_id: "2.B.3.m", name: "Quality Control Analysis",
   description: "Conducting tests and inspections of products, services, or processes to evaluate quality."}
] AS row
MERGE (s:Skill {element_id: row.element_id})
SET s.name = row.name,
    s.description = row.description,
    s.source = "onet",
    s.source_id = row.element_id;

// ---------- REQUIRES_SKILL (IM/LV merged onto one weighted edge) ----------
UNWIND [
  {code: "15-1252.00", element: "2.B.3.e", type: "transferable", im: 4.0,  lv: 4.12},
  {code: "15-1252.00", element: "2.A.2.a", type: "essential",    im: 3.88, lv: 4.0},
  {code: "15-1252.00", element: "2.B.2.i", type: "essential",    im: 3.75, lv: 3.88},
  {code: "15-1251.00", element: "2.B.3.e", type: "transferable", im: 4.12, lv: 4.25},
  {code: "15-1251.00", element: "2.A.2.a", type: "essential",    im: 3.62, lv: 3.75},
  {code: "15-1243.00", element: "2.B.3.e", type: "transferable", im: 3.5,  lv: 3.88},
  {code: "15-1243.00", element: "2.B.4.e", type: "transferable", im: 3.88, lv: 4.0},
  {code: "15-1253.00", element: "2.B.3.e", type: "transferable", im: 3.38, lv: 3.62},
  {code: "15-1253.00", element: "2.B.3.m", type: "transferable", im: 4.0,  lv: 4.12},
  {code: "15-1253.00", element: "2.A.2.a", type: "essential",    im: 3.75, lv: 3.88}
] AS row
MATCH (o:Occupation {onet_soc_code: row.code})
MATCH (s:Skill {element_id: row.element})
MERGE (o)-[rel:REQUIRES_SKILL {skill_type: row.type}]->(s)
SET rel.importance = row.im,
    rel.level = row.lv;

// ---------- Tasks (illustrative; task_id values are placeholders) ----------
UNWIND [
  {code: "15-1252.00", task_id: 21662,
   text: "Analyze user needs and software requirements to determine feasibility of design."},
  {code: "15-1251.00", task_id: 21663,
   text: "Modify existing software to correct errors or improve its performance."},
  {code: "15-1243.00", task_id: 21701,
   text: "Design and implement database structures to meet business requirements."},
  {code: "15-1253.00", task_id: 21745,
   text: "Develop testing programs that address areas such as database impacts and regression testing."}
] AS row
MERGE (t:Task {task_id: row.task_id})
SET t.text = row.text,
    t.source = "onet",
    t.source_id = toString(row.task_id)
WITH t, row
MATCH (o:Occupation {onet_soc_code: row.code})
MERGE (o)-[:HAS_TASK]->(t);

// ---------- Software (tools are their own node type, not skills) ----------
UNWIND [
  {code: "15-1252.00", name: "Python", category: "Object or component oriented development software", hot: true, in_demand: true},
  {code: "15-1252.00", name: "Git", category: "Configuration management software", hot: true, in_demand: true},
  {code: "15-1252.00", name: "Amazon Web Services AWS software", category: "Cloud-based management software", hot: true, in_demand: true},
  {code: "15-1251.00", name: "Python", category: "Object or component oriented development software", hot: true, in_demand: false},
  {code: "15-1243.00", name: "Amazon Web Services AWS software", category: "Cloud-based management software", hot: true, in_demand: false},
  {code: "15-1253.00", name: "Python", category: "Object or component oriented development software", hot: true, in_demand: false}
] AS row
MERGE (sw:Software {name: row.name})
SET sw.category = row.category,
    sw.source = "onet",
    sw.source_id = row.name
WITH sw, row
MATCH (o:Occupation {onet_soc_code: row.code})
MERGE (o)-[rel:USES_SOFTWARE]->(sw)
SET rel.hot_technology = row.hot,
    rel.in_demand = row.in_demand;

// ---------- Crosswalk to SOC (bridge to BLS, and via SOC ↔ ISCO to ESCO) ----------
// The SOC code is derivable: left(onet_soc_code, 7). Materialized as
// CrosswalkCode nodes so cross-taxonomy joins are first-class edges.
MATCH (o:Occupation)
WHERE o.source = "onet"
MERGE (x:CrosswalkCode {scheme: "SOC", code: left(o.onet_soc_code, 7)})
SET x.name = o.title
MERGE (o)-[:CROSSWALKS_TO]->(x);
