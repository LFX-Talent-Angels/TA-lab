#!/usr/bin/env python3
"""Load a small O*NET 30.3 slice into Neo4j (Model A).

Reads tab-delimited files from data/ (gitignored), filters to OCCUPATIONS,
and MERGEs nodes/relationships for Model A (see NOTES.md).

Data source: https://www.onetcenter.org/dl_files/database/db_30_3_text.zip
License: CC BY 4.0 — https://www.onetcenter.org/license_db.html
"""

from __future__ import annotations

import argparse
import csv
import os
from collections import defaultdict
from pathlib import Path

from dotenv import load_dotenv
from neo4j import GraphDatabase

# --- slice config (expand by adding SOC codes or files for full O*NET later) ---

OCCUPATIONS = frozenset({
    "15-1252.00",  # Software Developers
    "15-1251.00",  # Computer Programmers
    "15-1243.00",  # Database Architects
    "15-1253.00",  # Software Quality Assurance Analysts and Testers
})

DATA_DIR = Path(__file__).parent / "data"
BATCH_SIZE = 500


def read_tsv(filename: str) -> list[dict[str, str]]:
    path = DATA_DIR / filename
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def chunked(items: list, size: int):
    for i in range(0, len(items), size):
        yield items[i : i + size]


def parse_float(value: str) -> float | None:
    value = (value or "").strip()
    if not value or value.lower() == "n/a":
        return None
    return float(value)


def yn_bool(value: str) -> bool:
    return (value or "").strip().upper() == "Y"


class OnetLoader:
    def __init__(self, driver, database: str | None = None, clear: bool = False):
        self.driver = driver
        self.database = database
        self.clear = clear

    def _session(self):
        if self.database:
            return self.driver.session(database=self.database)
        return self.driver.session()

    def run(self) -> dict[str, int]:
        if self.clear:
            self._clear_graph()

        self._create_constraints()
        descriptions = self._load_content_model_reference()
        occ_count = self._load_occupations()
        task_count = self._load_tasks()
        skill_counts = self._load_skills(descriptions)
        sw_count = self._load_software()
        return self._summary(occ_count, task_count, skill_counts, sw_count)

    def _clear_graph(self) -> None:
        with self._session() as session:
            session.run("MATCH (n) DETACH DELETE n")

    def _create_constraints(self) -> None:
        statements = [
            "CREATE CONSTRAINT occupation_code IF NOT EXISTS "
            "FOR (o:Occupation) REQUIRE o.onet_soc_code IS UNIQUE",
            "CREATE CONSTRAINT task_id IF NOT EXISTS "
            "FOR (t:Task) REQUIRE t.task_id IS UNIQUE",
            "CREATE CONSTRAINT skill_element IF NOT EXISTS "
            "FOR (s:Skill) REQUIRE s.element_id IS UNIQUE",
            "CREATE CONSTRAINT software_name IF NOT EXISTS "
            "FOR (sw:Software) REQUIRE sw.name IS UNIQUE",
        ]
        with self._session() as session:
            for stmt in statements:
                session.run(stmt)

    def _load_content_model_reference(self) -> dict[str, str]:
        rows = read_tsv("Content Model Reference.txt")
        return {r["Element ID"]: r["Description"] for r in rows}

    def _load_occupations(self) -> int:
        rows = [
            {
                "onet_soc_code": r["O*NET-SOC Code"],
                "title": r["Title"],
                "description": r["Description"],
            }
            for r in read_tsv("Occupation Data.txt")
            if r["O*NET-SOC Code"] in OCCUPATIONS
        ]
        query = """
        UNWIND $rows AS row
        MERGE (o:Occupation {onet_soc_code: row.onet_soc_code})
        SET o.title = row.title,
            o.description = row.description,
            o.source = "onet",
            o.source_id = row.onet_soc_code
        """
        self._run_batches(query, rows)
        return len(rows)

    def _load_tasks(self) -> int:
        rows = []
        for r in read_tsv("Task Statements.txt"):
            if r["O*NET-SOC Code"] not in OCCUPATIONS:
                continue
            rows.append({
                "onet_soc_code": r["O*NET-SOC Code"],
                "task_id": int(r["Task ID"]),
                "text": r["Task"],
                "task_type": (r.get("Task Type") or "").strip() or None,
                "domain_source": r.get("Domain Source"),
            })
        query = """
        UNWIND $rows AS row
        MERGE (t:Task {task_id: row.task_id})
        SET t.text = row.text,
            t.task_type = row.task_type,
            t.domain_source = row.domain_source,
            t.source = "onet",
            t.source_id = toString(row.task_id)
        WITH t, row
        MATCH (o:Occupation {onet_soc_code: row.onet_soc_code})
        MERGE (o)-[:HAS_TASK]->(t)
        """
        self._run_batches(query, rows)
        return len(rows)

    def _load_skills(self, descriptions: dict[str, str]) -> dict[str, int]:
        totals = {"essential": 0, "transferable": 0}
        for filename, skill_type in (
            ("Essential Skills.txt", "essential"),
            ("Transferable Skills.txt", "transferable"),
        ):
            totals[skill_type] = self._load_skill_file(
                filename, skill_type, descriptions
            )
        return totals

    def _load_skill_file(
        self,
        filename: str,
        skill_type: str,
        descriptions: dict[str, str],
    ) -> int:
        grouped: dict[tuple[str, str], dict] = defaultdict(
            lambda: {"name": None, "importance": None, "level": None,
                     "not_relevant": None, "date": None, "source": None}
        )

        for r in read_tsv(filename):
            code = r["O*NET-SOC Code"]
            if code not in OCCUPATIONS:
                continue
            element_id = r["Element ID"]
            key = (code, element_id)
            entry = grouped[key]
            entry["onet_soc_code"] = code
            entry["element_id"] = element_id
            entry["skill_type"] = skill_type
            entry["name"] = r["Element Name"]
            entry["description"] = descriptions.get(element_id)
            scale = r["Scale ID"]
            if scale == "IM":
                entry["importance"] = parse_float(r["Data Value"])
                entry["date"] = r.get("Date")
                entry["source"] = r.get("Domain Source")
            elif scale == "LV":
                entry["level"] = parse_float(r["Data Value"])
                nr = (r.get("Not Relevant") or "").strip().upper()
                entry["not_relevant"] = nr == "Y"
                if not entry.get("date"):
                    entry["date"] = r.get("Date")
                if not entry.get("source"):
                    entry["source"] = r.get("Domain Source")

        rows = list(grouped.values())
        query = """
        UNWIND $rows AS row
        MERGE (s:Skill {element_id: row.element_id})
        SET s.name = row.name,
            s.description = row.description,
            s.source = "onet",
            s.source_id = row.element_id
        WITH s, row
        MATCH (o:Occupation {onet_soc_code: row.onet_soc_code})
        MERGE (o)-[rel:REQUIRES_SKILL {skill_type: row.skill_type}]->(s)
        SET rel.importance = row.importance,
            rel.level = row.level,
            rel.not_relevant = row.not_relevant,
            rel.date = row.date,
            rel.source = row.source
        """
        self._run_batches(query, rows)
        return len(rows)

    def _load_software(self) -> int:
        rows = []
        for r in read_tsv("Software Skills.txt"):
            if r["O*NET-SOC Code"] not in OCCUPATIONS:
                continue
            rows.append({
                "onet_soc_code": r["O*NET-SOC Code"],
                "name": r["Workplace Example"],
                "category_id": r["Element ID"],
                "category": r["Element Name"],
                "hot_technology": yn_bool(r["Hot Technology"]),
                "in_demand": yn_bool(r["In Demand"]),
            })
        query = """
        UNWIND $rows AS row
        MERGE (sw:Software {name: row.name})
        SET sw.category_id = row.category_id,
            sw.category = row.category,
            sw.source = "onet",
            sw.source_id = row.name
        WITH sw, row
        MATCH (o:Occupation {onet_soc_code: row.onet_soc_code})
        MERGE (o)-[rel:USES_SOFTWARE]->(sw)
        SET rel.hot_technology = row.hot_technology,
            rel.in_demand = row.in_demand,
            rel.category_id = row.category_id,
            rel.category = row.category
        """
        self._run_batches(query, rows)
        return len(rows)

    def _run_batches(self, query: str, rows: list) -> None:
        with self._session() as session:
            for batch in chunked(rows, BATCH_SIZE):
                session.run(query, rows=batch)

    def _summary(
        self,
        occ_count: int,
        task_count: int,
        skill_counts: dict[str, int],
        sw_count: int,
    ) -> dict[str, int]:
        with self._session() as session:
            node_counts = session.run(
                """
                MATCH (n)
                RETURN labels(n)[0] AS label, count(*) AS count
                ORDER BY label
                """
            ).data()
            rel_counts = session.run(
                """
                MATCH ()-[r]->()
                RETURN type(r) AS type, count(*) AS count
                ORDER BY type
                """
            ).data()

        print("\n--- Load complete ---")
        print(f"Occupations loaded: {occ_count}")
        print(f"Tasks linked:       {task_count}")
        print(f"Skill edges (essential):    {skill_counts['essential']}")
        print(f"Skill edges (transferable): {skill_counts['transferable']}")
        print(f"Software links:     {sw_count}")
        print("\nNodes in graph:")
        for row in node_counts:
            print(f"  {row['label']}: {row['count']}")
        print("Relationships in graph:")
        for row in rel_counts:
            print(f"  {row['type']}: {row['count']}")

        return {
            "occupations": occ_count,
            "tasks": task_count,
            "software_links": sw_count,
        }


def neo4j_credentials() -> tuple[str, str, str, str | None]:
    load_dotenv()
    uri = os.getenv("NEO4J_URI")
    if not uri:
        instance_id = os.getenv("AURA_INSTANCEID")
        if instance_id:
            uri = f"neo4j+s://{instance_id}.databases.neo4j.io"
    user = os.getenv("NEO4J_USERNAME", os.getenv("NEO4J_USER", "neo4j"))
    password = os.getenv("NEO4J_PASSWORD")
    database = os.getenv("NEO4J_DATABASE")
    if not uri or not password:
        raise SystemExit(
            "Missing Neo4j credentials. Copy .env.example → .env and set:\n"
            "  Aura:  NEO4J_URI=neo4j+s://<id>.databases.neo4j.io\n"
            "  Local: NEO4J_URI=neo4j://localhost:7687  (docker compose up -d)\n"
            "  NEO4J_USERNAME=neo4j\n"
            "  NEO4J_PASSWORD=<password>\n"
            "Optional: NEO4J_DATABASE=neo4j"
        )
    return uri, user, password, database


def main() -> None:
    parser = argparse.ArgumentParser(description="Load O*NET slice into Neo4j")
    parser.add_argument(
        "--clear",
        action="store_true",
        help="Delete all nodes/relationships before loading",
    )
    args = parser.parse_args()

    uri, user, password, database = neo4j_credentials()
    driver = GraphDatabase.driver(uri, auth=(user, password))
    try:
        loader = OnetLoader(driver, database=database, clear=args.clear)
        loader.run()
    finally:
        driver.close()


if __name__ == "__main__":
    main()