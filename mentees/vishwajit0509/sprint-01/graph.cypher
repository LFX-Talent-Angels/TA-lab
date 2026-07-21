// Sprint 1 — BLS / SOC Knowledge Graph slice (illustrative sample)
// Source: BLS Employment Projections 2024–34, Table 1.2 (https://www.bls.gov/emp/)
// U.S. government work — public domain. Numbers below are rounded/illustrative;
// the ETL pipeline (main.py) loads the real values for all 832 occupations.
// Standalone: run on a clean Neo4j database.

// ---------- Constraints ----------
CREATE CONSTRAINT occupation_soc IF NOT EXISTS
FOR (o:Occupation) REQUIRE o.soc_code IS UNIQUE;
CREATE CONSTRAINT major_group_soc IF NOT EXISTS
FOR (g:MajorGroup) REQUIRE g.soc_code IS UNIQUE;
CREATE CONSTRAINT minor_group_soc IF NOT EXISTS
FOR (g:MinorGroup) REQUIRE g.soc_code IS UNIQUE;
CREATE CONSTRAINT broad_occupation_soc IF NOT EXISTS
FOR (g:BroadOccupation) REQUIRE g.soc_code IS UNIQUE;
CREATE CONSTRAINT education_level IF NOT EXISTS
FOR (e:EducationLevel) REQUIRE e.level IS UNIQUE;

// ---------- SOC hierarchy: Major -> Minor -> Broad -> Detailed ----------
// The 6-digit SOC code encodes the whole tree (see README):
// first two digits = major group, third = minor group, fourth/fifth = broad.
// e.g. 29-1141 → 29-0000 → 29-1000 → 29-1140.
CREATE (mg15:MajorGroup {source: "bls", source_id: "15-0000", soc_code: "15-0000", title: "Computer and Mathematical Occupations"})
CREATE (mg29:MajorGroup {source: "bls", source_id: "29-0000", soc_code: "29-0000", title: "Healthcare Practitioners and Technical Occupations"})

CREATE (mi152:MinorGroup {source: "bls", source_id: "15-2000", soc_code: "15-2000", title: "Mathematical Science Occupations"})
CREATE (mi291:MinorGroup {source: "bls", source_id: "29-1000", soc_code: "29-1000", title: "Healthcare Diagnosing or Treating Practitioners"})

CREATE (br1520:BroadOccupation {source: "bls", source_id: "15-2050", soc_code: "15-2050", title: "Data Scientists"})
CREATE (br2914:BroadOccupation {source: "bls", source_id: "29-1140", soc_code: "29-1140", title: "Registered Nurses"})
CREATE (br2917:BroadOccupation {source: "bls", source_id: "29-1170", soc_code: "29-1170", title: "Nurse Anesthetists, Nurse Midwives, and Nurse Practitioners"})

// ---------- Occupations: the central hubs ----------
// Scalar facts (wage, employment, projection) are PROPERTIES here, not
// satellite nodes — MERGE-ing satellites by value would fuse unrelated
// occupations that share a coincidental number (the sprint's big lesson).
// Employment is in thousands of jobs, as published in Table 1.2.
CREATE (ds:Occupation {source: "bls", source_id: "15-2051", soc_code: "15-2051",
        title: "Data scientists",
        median_annual_wage: 112590, base_year_emp: 240, projected_year_emp: 322, percent_change: 34.0})
CREATE (rn:Occupation {source: "bls", source_id: "29-1141", soc_code: "29-1141",
        title: "Registered nurses",
        median_annual_wage: 93600, base_year_emp: 3300, projected_year_emp: 3480, percent_change: 5.4})
CREATE (np:Occupation {source: "bls", source_id: "29-1171", soc_code: "29-1171",
        title: "Nurse practitioners",
        median_annual_wage: 129210, base_year_emp: 300, projected_year_emp: 420, percent_change: 40.0})

CREATE (mg15)-[:CONTAINS]->(mi152)
CREATE (mg29)-[:CONTAINS]->(mi291)
CREATE (mi152)-[:CONTAINS]->(br1520)
CREATE (mi291)-[:CONTAINS]->(br2914)
CREATE (mi291)-[:CONTAINS]->(br2917)
CREATE (br1520)-[:CONTAINS]->(ds)
CREATE (br2914)-[:CONTAINS]->(rn)
CREATE (br2917)-[:CONTAINS]->(np)

// ---------- Education levels: correctly SHARED nodes ----------
// Unlike wages/projections, an education level is a real shared entity —
// many occupations genuinely point at the same entry credential.
CREATE (ba:EducationLevel {source: "bls", source_id: "Bachelor's degree", level: "Bachelor's degree"})
CREATE (ma:EducationLevel {source: "bls", source_id: "Master's degree", level: "Master's degree"})

CREATE (ds)-[:REQUIRES_EDUCATION]->(ba)
CREATE (rn)-[:REQUIRES_EDUCATION]->(ba)
CREATE (np)-[:REQUIRES_EDUCATION]->(ma)

// ---------- Crosswalk: SOC is the NATIVE scheme here ----------
// For every other taxonomy the CROSSWALKS_TO edge is a lossy mapping; for
// BLS it is the identity. That makes BLS the hub of the crosswalk layer:
// Lightcast (LOT → SOC), O*NET (O*NET-SOC) and ESCO (via ISCO ↔ SOC) all
// land on these same CrosswalkCode nodes.
CREATE (x1:CrosswalkCode {scheme: "SOC", code: "15-2051", name: "Data Scientists"})
CREATE (x2:CrosswalkCode {scheme: "SOC", code: "29-1141", name: "Registered Nurses"})
CREATE (x3:CrosswalkCode {scheme: "SOC", code: "29-1171", name: "Nurse Practitioners"})

CREATE (ds)-[:CROSSWALKS_TO]->(x1)
CREATE (rn)-[:CROSSWALKS_TO]->(x2)
CREATE (np)-[:CROSSWALKS_TO]->(x3);
