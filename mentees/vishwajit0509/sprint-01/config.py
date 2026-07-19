import os
from dotenv import load_dotenv

load_dotenv()

NEO4J_URI = os.getenv("NEO4J_URI")
NEO4J_USERNAME = os.getenv("NEO4J_USERNAME")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD")

DATA_FILE_PATH = "data/occupation.xlsx"

if not NEO4J_PASSWORD:
    raise ValueError("Missing database password! Check your .env file.")