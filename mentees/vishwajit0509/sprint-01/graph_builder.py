import pandas as pd


def ensure_constraints(db_connection):
    """Uniqueness constraints so MERGE stays idempotent and lookups stay fast."""
    print("\n🔒 Ensuring uniqueness constraints...")

    constraints = [
        "CREATE CONSTRAINT occupation_soc IF NOT EXISTS FOR (o:Occupation) REQUIRE o.soc_code IS UNIQUE",
        "CREATE CONSTRAINT major_group_soc IF NOT EXISTS FOR (g:MajorGroup) REQUIRE g.soc_code IS UNIQUE",
        "CREATE CONSTRAINT minor_group_soc IF NOT EXISTS FOR (g:MinorGroup) REQUIRE g.soc_code IS UNIQUE",
        "CREATE CONSTRAINT broad_occupation_soc IF NOT EXISTS FOR (g:BroadOccupation) REQUIRE g.soc_code IS UNIQUE",
        "CREATE CONSTRAINT education_level IF NOT EXISTS FOR (e:EducationLevel) REQUIRE e.level IS UNIQUE",
    ]

    for constraint in constraints:
        db_connection.execute_write_query(constraint)


def build_occupation_nodes(db_connection, dataframe):
    print("\n🚀 Starting Multi-Node Knowledge Graph construction...")

    # Modeling rule (the v2 fix flagged in README "Hard Problems" #2):
    # scalar facts of a single occupation — median wage, base/projected
    # employment, percent change — are PROPERTIES of the Occupation node,
    # not satellite nodes. MERGE-ing satellites by value fused unrelated
    # occupations that happened to share the same number.
    # EducationLevel stays a shared node: many occupations genuinely point
    # at the same entry credential, so it has identity of its own.
    cypher_query = """
    UNWIND $rows AS row

    // 1. The Central Hub: Occupation (facts live here as properties)
    MERGE (o:Occupation {soc_code: row.soc_code})
    SET o.title = row.title,
        o.source = "bls",
        o.source_id = row.soc_code,
        o.base_year_emp = toInteger(row.base_employment),
        o.projected_year_emp = toInteger(row.projected_employment),
        o.percent_change = toFloat(row.percent_change),
        o.median_annual_wage = toInteger(row.median_wage)

    // 2. The Education Level Node (correctly shared across occupations)
    WITH o, row
    CALL (o, row) {
        WITH o, row WHERE row.entry_education IS NOT NULL
        MERGE (e:EducationLevel {level: row.entry_education})
        SET e.source = "bls", e.source_id = row.entry_education
        MERGE (o)-[:REQUIRES_EDUCATION]->(e)
    }
    """

    clean_df = dataframe.where(pd.notnull(dataframe), None)
    data_rows = clean_df.to_dict(orient='records')

    try:
        db_connection.execute_write_query(cypher_query, parameters={"rows": data_rows})
        print(f"Graph successfully built! Modeled {len(data_rows)} occupations with full taxonomy.")
    except Exception as e:
        print(f"❌ Failed to execute Cypher query: {e}")


def derive_soc_hierarchy(soc_code):
    """Derive the SOC hierarchy codes encoded in a 6-digit code.

    As documented in the README: the first two digits give the major group,
    the third digit the minor group, and the fourth and fifth digits the
    broad occupation (e.g. 29-1141 → 29-0000 → 29-1000 → 29-1140).

    Note: the 2018 SOC revision has a handful of minor groups that break the
    third-digit rule (e.g. Computer Occupations is 15-1200), so derived codes
    are structural approximations. Ingesting the summary rows of Table 1.2
    (currently dropped by the "Line item" filter) would recover the official
    group codes and titles — a v2 enrichment.
    """
    return {
        "soc_code": soc_code,
        "major_code": f"{soc_code[:2]}-0000",
        "minor_code": f"{soc_code[:4]}000",
        "broad_code": f"{soc_code[:6]}0",
    }


def build_soc_hierarchy(db_connection, dataframe):
    print("\n🌳 Building the SOC hierarchy (Major → Minor → Broad → Detailed)...")

    hierarchy_rows = [
        derive_soc_hierarchy(soc_code)
        for soc_code in dataframe['soc_code'].dropna().unique()
        if isinstance(soc_code, str) and len(soc_code) == 7
    ]

    cypher_query = """
    UNWIND $rows AS row

    MERGE (major:MajorGroup {soc_code: row.major_code})
    SET major.source = "bls", major.source_id = row.major_code

    MERGE (minor:MinorGroup {soc_code: row.minor_code})
    SET minor.source = "bls", minor.source_id = row.minor_code

    MERGE (broad:BroadOccupation {soc_code: row.broad_code})
    SET broad.source = "bls", broad.source_id = row.broad_code

    MERGE (o:Occupation {soc_code: row.soc_code})

    MERGE (major)-[:CONTAINS]->(minor)
    MERGE (minor)-[:CONTAINS]->(broad)
    MERGE (broad)-[:CONTAINS]->(o)
    """

    try:
        db_connection.execute_write_query(cypher_query, parameters={"rows": hierarchy_rows})
        print(f"SOC hierarchy built for {len(hierarchy_rows)} occupations.")
    except Exception as e:
        print(f"❌ Failed to build SOC hierarchy: {e}")
