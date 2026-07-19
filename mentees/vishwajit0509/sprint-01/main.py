# main.py
from config import NEO4J_URI, NEO4J_USERNAME, NEO4J_PASSWORD, DATA_FILE_PATH
from database import Neo4jConnection
from data_loader import extract_and_clean_data
from graph_builder import ensure_constraints, build_occupation_nodes, build_soc_hierarchy

def main():
    print("Initiating Database Connection...")
    db = Neo4jConnection(NEO4J_URI, NEO4J_USERNAME, NEO4J_PASSWORD)
    db.verify_connection()

    try:
        
        bls_dataframe = extract_and_clean_data(DATA_FILE_PATH)


        ensure_constraints(db)
        build_occupation_nodes(db, bls_dataframe)
        build_soc_hierarchy(db, bls_dataframe)
        
    except Exception as e:
        print(f"Error during execution: {e}")
    
    finally:
        
        db.close()
        print("\nDatabase connection closed.")
    
if __name__ == "__main__":
    main()