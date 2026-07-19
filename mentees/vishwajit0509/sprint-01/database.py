from neo4j import GraphDatabase

class Neo4jConnection:
    def __init__(self,uri,user,pwd):
        self.driver = GraphDatabase.driver(uri, auth=(user,pwd))
    
    def close(self):
        if self.driver is not None:
            self.driver.close()
    
    def verify_connection(self):
        try:
            self.driver.verify_connectivity()
            print("Successfully connected to Neo4j Aura!")
        except Exception as e:
            print(f"Connection failed: {e}")
    
    def execute_write_query(self,query,parameters=None):
        with self.driver.session() as session:
            session.run(query,parameters)
