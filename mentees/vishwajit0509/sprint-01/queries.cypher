// Sprint 1 — BLS / SOC slice: example questions
// Framed as previews of the three core agents (Locator / Connector / Pathfinder).
// Runnable against graph.cypher (illustrative slice) or the full ETL graph (main.py).

// -- Locator: "Where does 'Data scientists' (15-2051) live in the SOC tree?"
//    Resolve an occupation and walk its full hierarchy path.
MATCH (o:Occupation {soc_code: "15-2051"})
MATCH path = (mg:MajorGroup)-[:CONTAINS*]->(o)
RETURN o.title AS occupation,
       [n IN nodes(path) | n.soc_code] AS hierarchy_codes,
       [n IN nodes(path) | coalesce(n.title, n.soc_code)] AS hierarchy;

// -- Locator (constraint search): "Which growing occupations require only a
//    Bachelor's degree?" — education + growth + wage filters in one traversal.
MATCH (e:EducationLevel {level: "Bachelor's degree"})<-[:REQUIRES_EDUCATION]-(o:Occupation)
WHERE o.percent_change > 5
RETURN o.title, o.percent_change, o.median_annual_wage
ORDER BY o.percent_change DESC;

// -- Connector (downstream): "What sits directly under Healthcare Diagnosing
//    or Treating Practitioners (29-1000)?" — the nodes succeeding a location.
MATCH (mi:MinorGroup {soc_code: "29-1000"})-[:CONTAINS]->(b:BroadOccupation)
OPTIONAL MATCH (b)-[:CONTAINS]->(o:Occupation)
RETURN b.soc_code AS broad_code, coalesce(b.title, b.soc_code) AS broad,
       collect(o.title) AS detailed_occupations;

// -- Connector (upstream): "Which broad / minor / major group contains
//    Registered nurses?" — the nodes preceding a location.
MATCH (o:Occupation {soc_code: "29-1141"})<-[:CONTAINS]-(b:BroadOccupation)
      <-[:CONTAINS]-(mi:MinorGroup)<-[:CONTAINS]-(mg:MajorGroup)
RETURN o.title AS occupation, b.soc_code AS broad, mi.soc_code AS minor, mg.soc_code AS major;

// -- Connector (peers): "Which occupations share Registered nurses' entry
//    education?" — the shared EducationLevel node is the connector.
MATCH (rn:Occupation {soc_code: "29-1141"})-[:REQUIRES_EDUCATION]->(e:EducationLevel)
      <-[:REQUIRES_EDUCATION]-(peer:Occupation)
WHERE peer.soc_code <> rn.soc_code
RETURN peer.title, e.level, peer.median_annual_wage;

// -- Hierarchy analytics (now answerable thanks to the SOC tree):
//    "Fastest-growing occupations inside a major group?"
MATCH (mg:MajorGroup {soc_code: "29-0000"})-[:CONTAINS*]->(o:Occupation)
WHERE o.percent_change IS NOT NULL
RETURN o.title, o.percent_change, o.projected_year_emp - o.base_year_emp AS jobs_added_thousands
ORDER BY o.percent_change DESC
LIMIT 10;

//    "How do wages compare across a major group, broad occupation by broad
//    occupation?" — aggregation over the tree.
MATCH (mg:MajorGroup {soc_code: "29-0000"})-[:CONTAINS*]->(b:BroadOccupation)-[:CONTAINS]->(o:Occupation)
WHERE o.median_annual_wage IS NOT NULL
RETURN b.soc_code AS broad_occupation,
       avg(o.median_annual_wage) AS avg_median_wage,
       count(o) AS occupations
ORDER BY avg_median_wage DESC;

// -- Pathfinder (scoped for BLS): BLS/SOC has NO skills layer, so
//    shared-skill bridges between occupations are out of scope for this
//    taxonomy — that richness comes from O*NET / ESCO / Lightcast. BLS's
//    Pathfinder contribution is (a) the crosswalk below, which lets paths
//    found in skill-rich taxonomies be joined on SOC codes, and (b) economic
//    signals (wage, growth) to rank those paths. The nearest in-graph
//    analogue is an education-level bridge:
//    "Can I move from Registered nurse toward Nurse practitioner, and what
//    education step bridges them?"
MATCH (a:Occupation {soc_code: "29-1141"})-[:REQUIRES_EDUCATION]->(ea:EducationLevel),
      (b:Occupation {soc_code: "29-1171"})-[:REQUIRES_EDUCATION]->(eb:EducationLevel)
RETURN a.title AS from_occupation, ea.level AS current_credential,
       b.title AS to_occupation, eb.level AS required_credential;

// -- Gap analysis (Evaluator preview): "Is the move worth it?" — wage and
//    growth deltas between a current and a target occupation.
MATCH (a:Occupation {soc_code: "29-1141"}), (b:Occupation {soc_code: "29-1171"})
RETURN a.title AS from_occupation, b.title AS to_occupation,
       b.median_annual_wage - a.median_annual_wage AS wage_delta,
       b.percent_change - a.percent_change AS growth_delta;

// -- Crosswalk: "How does this occupation map to the shared SOC scheme?"
//    For BLS this is the identity mapping — SOC is its native scheme — which
//    makes BLS the hub that Lightcast, O*NET, and ESCO crosswalk into.
MATCH (o:Occupation)-[:CROSSWALKS_TO]->(x:CrosswalkCode {scheme: "SOC"})
RETURN o.title AS bls_occupation, x.code AS soc_code, x.name AS soc_name;
