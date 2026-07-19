import pandas as pd

def build_occupation_nodes(db_connection, dataframe):
    print("\n🚀 Starting Multi-Node Knowledge Graph construction...")

    
    cypher_query = """
    UNWIND $rows AS row

    // 1. The Central Hub: Occupation
    MERGE (o:Occupation {soc_code: row.soc_code})
    SET o.title = row.title

    // 2. The Employment Projection Node
    
    WITH o, row,
         toInteger(row.base_employment) AS base_emp,
         toInteger(row.projected_employment) AS proj_emp,
         toFloat(row.percent_change) AS pct_change
    CALL (o, base_emp, proj_emp, pct_change) {
        WITH o, base_emp, proj_emp, pct_change
        WHERE base_emp IS NOT NULL AND proj_emp IS NOT NULL AND pct_change IS NOT NULL
        MERGE (p:EmploymentProjection {
            base_year_emp: base_emp,
            projected_year_emp: proj_emp,
            percent_change: pct_change
        })
        MERGE (o)-[:HAS_PROJECTION]->(p)
    }

    // 3. The Wage Data Node
    WITH o, row, toInteger(row.median_wage) AS wage
    CALL (o, wage) {
        WITH o, wage WHERE wage IS NOT NULL
        MERGE (w:WageData {median_annual_wage: wage})
        MERGE (o)-[:PAYS_WAGE]->(w)
    }

    // 4. The Education Level Node
    WITH o, row
    CALL (o, row) {
        WITH o, row WHERE row.entry_education IS NOT NULL
        MERGE (e:EducationLevel {level: row.entry_education})
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