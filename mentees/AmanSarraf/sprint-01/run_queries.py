#!/usr/bin/env python3
"""Run and verify queries.cypher against Neo4j (Aura or local Docker)."""

from __future__ import annotations

import re
from pathlib import Path

from load_onet import neo4j_credentials
from neo4j import GraphDatabase

QUERIES_FILE = Path(__file__).parent / "queries.cypher"

# Named checks with expected shape (not exact row counts — data can vary slightly)
CHECKS = {
    "Q0": {"min_rows": 1, "must_have_column": "code"},
    "Q1": {"min_rows": 30, "must_have_column": "skill"},
    "Q1b": {"min_rows": 30, "must_have_column": "skill"},
    "Q2": {"min_rows": 4, "must_have_column": "occupation"},
    "Q3": {"min_rows": 10, "must_have_column": "task"},
    "Q4": {"min_rows": 4, "must_have_column": "occupation"},
    "Q5": {"min_rows": 1, "must_have_column": "software"},
    "Q6": {"min_rows": 4, "must_have_column": "label"},
    "Q7": {"min_rows": 10, "must_have_column": "skill"},
    "Q8": {"min_rows": 1, "must_have_column": "shared_skills"},
}


CYPHER_START = re.compile(
    r"^\s*(MATCH|OPTIONAL|WITH|CALL|RETURN|CREATE|MERGE|UNWIND|//)",
    re.IGNORECASE,
)


def parse_queries(text: str) -> list[tuple[str, str]]:
    blocks = re.split(r"// -{10,}\n// (Q\d+):", text)
    queries = []
    for i in range(1, len(blocks), 2):
        label = blocks[i].strip()
        body = blocks[i + 1]
        lines = body.strip().splitlines()
        cypher_lines = []
        started = False
        for line in lines:
            if not started:
                if CYPHER_START.match(line) and not line.strip().startswith("//"):
                    started = True
                    cypher_lines.append(line)
                continue
            if line.strip().startswith("//"):
                break  # next section comments inside block
            cypher_lines.append(line)
        cypher = "\n".join(cypher_lines).strip().rstrip(";")
        if cypher:
            queries.append((label, cypher))
    return queries


def main() -> None:
    uri, user, password, database = neo4j_credentials()
    driver = GraphDatabase.driver(uri, auth=(user, password))
    text = QUERIES_FILE.read_text(encoding="utf-8")
    queries = parse_queries(text)

    print(f"Running {len(queries)} queries from {QUERIES_FILE.name}\n")
    failed = 0

    try:
        for label, cypher in queries:
            session_kwargs = {"database": database} if database else {}
            with driver.session(**session_kwargs) as session:
                result = session.run(cypher)
                rows = result.data()

            check = CHECKS.get(label, {})
            min_rows = check.get("min_rows", 1)
            col = check.get("must_have_column")
            ok = len(rows) >= min_rows and (not col or col in (rows[0] if rows else {}))

            status = "PASS" if ok else "FAIL"
            if not ok:
                failed += 1
            print(f"[{status}] {label}: {len(rows)} rows")
            for row in rows[:3]:
                print(f"       {row}")
            if len(rows) > 3:
                print(f"       ... +{len(rows) - 3} more")
            print()
    finally:
        driver.close()

    if failed:
        raise SystemExit(f"{failed} query check(s) failed")
    print("All query checks passed.")


if __name__ == "__main__":
    main()