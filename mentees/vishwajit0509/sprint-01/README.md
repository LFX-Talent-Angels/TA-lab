# BLS Occupation Knowledge Graph

> A Neo4j-powered knowledge graph built on the **U.S. Bureau of Labor Statistics (BLS) Employment Projections 2024–34** dataset (Table 1.2 from `Occupation.xlsx`), designed to power AI agents for lifelong learning and career navigation in the age of AI.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [BLS Taxonomy: Findings & Structure](#bls-taxonomy-findings--structure)
3. [Graph Architecture](#graph-architecture)
4. [Data Model](#data-model)
5. [What Locator / Connector Agents Need](#what-locator--connector-agents-need)
6. [Example Questions the Graph Can Answer](#example-questions-the-graph-can-answer)
7. [Taxonomy Comparison & Discussion](#taxonomy-comparison--discussion)
8. [How Taxonomy Understanding Adds Value to AI Agents](#how-taxonomy-understanding-adds-value-to-ai-agents)
9. [Tech Stack & Frameworks](#tech-stack--frameworks)
10. [Project Structure](#project-structure)
11. [Setup & Usage](#setup--usage)

---

## Project Overview

This project ingests BLS occupational projection data, cleans it, and constructs a **multi-node property graph** in Neo4j Aura. Each occupation is modelled as a hub node connected to satellite nodes representing its wage, employment trajectory, and required education level. The resulting graph is intended as a structured backbone for AI agents that help humans navigate career transitions, identify skill gaps, and make informed decisions about lifelong learning.

---

## BLS Taxonomy: Findings & Structure

### What BLS / SOC Is

The **Standard Occupational Classification (SOC)** system is the federal taxonomy maintained by the Bureau of Labor Statistics. It classifies *every worker in the U.S. economy* into a four-level hierarchy, making it the canonical reference for occupational labour market data.

```
Major Group  (2-digit)   →  23 groups        e.g., "15-XXXX Computer & Mathematical"
Minor Group  (3-digit)   →  98 groups        e.g., "15-1XXX Computer Occupations"
Broad Occ.   (5-digit)   →  459 groups       e.g., "15-11XX Computer & Info Scientists"
Detailed Occ.(6-digit)   →  867 occupations  e.g., "15-1132 Software Developers"
```

The 6-digit SOC code encodes the entire hierarchy: first two digits = major group, third digit = minor group, fourth and fifth digits = broad occupation, sixth digit = detailed occupation.

### Key Findings from the BLS 2024–34 Projection Cycle

**Macro outlook:**  
Total U.S. employment is projected to grow from **170.0 million to 175.2 million** (+3.1%), a substantially slower pace than the 13.0% growth recorded over 2014–24. The slowdown is driven by an aging population and declining labor force participation rates.

**Fastest growing sectors (by %):**

| Sector | Projected Growth |
|---|---|
| Healthcare & Social Assistance | +8.4% |
| Professional, Scientific & Technical Services | +7.5% |
| Information (AI / data / software) | +6.5% |
| Transportation & Warehousing | +3.0% |

**Occupational group highlights:**

- **Healthcare Support** occupations: +12.4% — the fastest growing group overall, driven by aging population demand.
- **Computer & Mathematical** occupations: +10.1% — more than 3× the economy average. Five of the 15 fastest growing individual occupations fall here, directly linked to AI development, data science, and cybersecurity demand.
- **Community & Social Service** occupations: +6.6%.
- **Office & Administrative Support** and **Sales** occupations: *declining*, as AI and automation take over routine calls, data entry, and analysis tasks.
- **Production** occupations: declining due to continued automation investment.

**AI as a structural signal:**  
BLS explicitly calls out AI as a *dual* force — growing demand for AI builders (data scientists, ML engineers, software developers, information security analysts) while simultaneously contributing to declining demand for office administrators, sales workers, and production workers. BLS notes that technology impacts are historically gradual, not sudden — task composition within occupations shifts before headcount does.

**Notable individual occupations (fastest growth):**  
Wind Turbine Service Technicians and Solar PV Installers rank #1 and #2 in percent growth. Nurse Practitioners is the fastest growing healthcare occupation. Home Health and Personal Care Aides will add the most raw jobs of any of the 832 detailed occupations published.

**Declining occupations:**  
Retail trade is projected to lose the most jobs in absolute terms (-1.2%) due to automation, e-commerce, and consolidation. Mining and extraction sectors decline partly from robotics and drone adoption.

**What this means structurally:**  
The BLS taxonomy is an *employment-centric* classification. It tells you what workers *do* and how many will be needed, at what wage, and with what education entry requirement. It does **not** enumerate the skills, tasks, or knowledge items inside each occupation — that richness lives in complementary taxonomies like O\*NET, ESCO, or Lightcast.

---

## Graph Architecture

### Node Types

```
(:Occupation)
    Properties: soc_code (PK), title

(:EmploymentProjection)
    Properties: base_year_emp, projected_year_emp, percent_change

(:WageData)
    Properties: median_annual_wage

(:EducationLevel)
    Properties: level
```

### Relationship Types

```
(:Occupation)-[:HAS_PROJECTION]->(:EmploymentProjection)
(:Occupation)-[:PAYS_WAGE]->(:WageData)
(:Occupation)-[:REQUIRES_EDUCATION]->(:EducationLevel)
```

### Full Graph Diagram

```
                    ┌─────────────────────────┐
                    │      :EducationLevel      │
                    │  level: "Bachelor's..."   │
                    └─────────────────────────┘
                                ▲
                    [:REQUIRES_EDUCATION]
                                │
┌──────────────────────┐        │        ┌────────────────────────────┐
│   :EmploymentProj.   │        │        │        :WageData            │
│  base_year_emp: X    │◄───────┼───────►│  median_annual_wage: $Y    │
│  proj_year_emp: Z    │        │        └────────────────────────────┘
│  percent_change: %   │   [:HAS_PROJECTION]  [:PAYS_WAGE]
└──────────────────────┘        │
                                │
                    ┌───────────┴────────────┐
                    │      :Occupation        │
                    │  soc_code: "15-2051"   │
                    │  title: "Data Scien..." │
                    └────────────────────────┘
```

### Traversal Patterns

**Top-down (exploring an occupation):**
```
MATCH (o:Occupation {soc_code: "15-2051"})
-[:HAS_PROJECTION]->(p)
-[:PAYS_WAGE]->(w)
-[:REQUIRES_EDUCATION]->(e)
RETURN o, p, w, e
```

**Bottom-up (finding occupations by constraint):**
```
MATCH (e:EducationLevel {level: "Bachelor's degree"})
<-[:REQUIRES_EDUCATION]-(o:Occupation)
-[:HAS_PROJECTION]->(p)
WHERE p.percent_change > 10
RETURN o.title, p.percent_change ORDER BY p.percent_change DESC
```

**Peer discovery (shared wage band):**
```
MATCH (target:Occupation {soc_code: "15-1252"})-[:PAYS_WAGE]->(w:WageData)
<-[:PAYS_WAGE]-(peer:Occupation)
WHERE peer.soc_code <> target.soc_code
RETURN peer.title, w.median_annual_wage
```

---

## Data Model

### Source: Table 1.2 of BLS Occupation.xlsx

| Column | Graph Mapping | Notes |
|---|---|---|
| `2024 National Employment Matrix title` | `Occupation.title` | Human-readable label |
| `2024 National Employment Matrix code` | `Occupation.soc_code` | 6-digit SOC, primary key |
| `Occupation type` | Filter: `Line item` only | Excludes summary rows |
| `Employment, 2024` | `EmploymentProjection.base_year_emp` | Thousands of jobs |
| `Employment, 2034` | `EmploymentProjection.projected_year_emp` | Thousands of jobs |
| `Employment change, percent, 2024–34` | `EmploymentProjection.percent_change` | Float; `—` → NULL |
| `Median annual wage, 2024` | `WageData.median_annual_wage` | USD; `—` → NULL |
| `Typical education needed for entry` | `EducationLevel.level` | Categorical, shared nodes |

### Hard Problems in This Data Model

**1. NULL proliferation.**  
BLS uses `—` to indicate suppressed or unavailable values (e.g., wages for certain aggregated codes, projections for occupations in flux). The ETL pipeline replaces these with Python `None` before writing to Neo4j, and the Cypher `CALL {}` subquery pattern conditionally skips node creation rather than inserting null-valued nodes. This keeps the graph semantically clean but means not all occupations have all satellite nodes.

**2. Shared satellite nodes vs. unique nodes.**  
`EmploymentProjection`, `WageData`, and `EducationLevel` nodes are built with `MERGE` on their property values, so two occupations with identical wages share a single `WageData` node. This is intentional for education levels (e.g., many occupations share `"Bachelor's degree"`) but can be misleading for `EmploymentProjection` nodes where two occupations happen to have the same numeric projection by coincidence. A `projection_id` UUID field should be added in v2.


**3. No skills or tasks layer.**  
BLS/SOC captures *what jobs exist and how many*, not *what knowledge and tasks they require*. The graph currently has no skill nodes. Enrichment from O\*NET, ESCO, or Lightcast is needed before the graph can answer questions like "what skills transfer from occupation A to occupation B."

**4. Temporal snapshot, not time series.**  
The data is a two-point projection (2024 base, 2034 projected). Iterative ingestion across BLS release cycles (2020–30, 2022–32, 2024–34) would enable trend analysis.

---

## What Locator / Connector Agents Need

In the Talent Angels / Learning Tokens architecture, two agent types are most likely to query this graph:

### Locator Agent
The Locator finds occupations matching a user's profile, constraints, or aspirations.

**Needs from this graph:**
- `Occupation` nodes by SOC code or title (full-text or exact match)
- `EducationLevel` filter — "show me occupations accessible with only a high school diploma that are growing > 5%"
- `EmploymentProjection` range filter — identify stable vs. fast-growing vs. declining occupations
- `WageData` range filter — surface roles above a target income threshold
- Peer clusters via shared `WageData` or `EducationLevel` nodes — comparable roles a learner might transition into
- SOC hierarchy traversal (once parent nodes are added) — explore a career family rather than a single occupation

### Connector Agent
The Connector maps a user's current skills and education to target occupations, and identifies learning pathways.

**Needs from this graph:**
- Entry point: `EducationLevel` → `[:REQUIRES_EDUCATION]` → `(:Occupation)` — what is reachable from the user's current credentials?
- Gap analysis: compare the user's current role's `EducationLevel` and `WageData` against a target occupation's — what delta must be bridged?
- Growth signal: `EmploymentProjection.percent_change` as a proxy for job market demand when recommending target roles
- Cross-walk readiness: SOC codes as join keys to O\*NET tasks and ESCO skills, so the Connector can surface which specific skills the user needs to acquire
- "Adjacent possible" pattern: given an occupation X, find occupations reachable in one or two education/skill steps with improving wage trajectory

---

## Example Questions the Graph Can Answer

**1. Which growing occupations require only a high school diploma?**
```cypher
MATCH (e:EducationLevel {level: "High school diploma or equivalent"})
      <-[:REQUIRES_EDUCATION]-(o:Occupation)
      -[:HAS_PROJECTION]->(p:EmploymentProjection)
WHERE p.percent_change > 5
RETURN o.title, p.percent_change
ORDER BY p.percent_change DESC
```

**2. What is the median wage for Software Developers and how is employment expected to change?**
```cypher
MATCH (o:Occupation {soc_code: "15-1252"})
      -[:PAYS_WAGE]->(w:WageData),
      (o)-[:HAS_PROJECTION]->(p:EmploymentProjection)
RETURN o.title, w.median_annual_wage, p.base_year_emp, p.projected_year_emp, p.percent_change
```

**3. Which occupations share the same education requirement as Registered Nurses?**
```cypher
MATCH (rn:Occupation {title: "Registered nurses"})
      -[:REQUIRES_EDUCATION]->(e:EducationLevel)
      <-[:REQUIRES_EDUCATION]-(peer:Occupation)
WHERE peer.soc_code <> rn.soc_code
RETURN peer.title, e.level
```

**4. What is the projected job loss for office and administrative support occupations?**
```cypher
MATCH (o:Occupation)-[:HAS_PROJECTION]->(p:EmploymentProjection)
WHERE p.percent_change < 0
RETURN o.title, p.percent_change, p.base_year_emp, p.projected_year_emp
ORDER BY p.percent_change ASC
LIMIT 20
```

**5. Which high-wage occupations (> $100K) are also high-growth (> 8%)?**
```cypher
MATCH (o:Occupation)-[:PAYS_WAGE]->(w:WageData),
      (o)-[:HAS_PROJECTION]->(p:EmploymentProjection)
WHERE w.median_annual_wage > 100000 AND p.percent_change > 8
RETURN o.title, w.median_annual_wage, p.percent_change
ORDER BY p.percent_change DESC
```

**6. How many occupations at each education level are projected to grow vs. decline?**
```cypher
MATCH (e:EducationLevel)<-[:REQUIRES_EDUCATION]-(o:Occupation)
      -[:HAS_PROJECTION]->(p:EmploymentProjection)
RETURN e.level,
       COUNT(CASE WHEN p.percent_change > 0 THEN 1 END) AS growing,
       COUNT(CASE WHEN p.percent_change < 0 THEN 1 END) AS declining
ORDER BY growing DESC
```

---

## Taxonomy Comparison & Discussion

### The Major Occupational Taxonomies

| Taxonomy | Origin | Primary Focus | Granularity | Skills Layer |
|---|---|---|---|---|
| **BLS / SOC** | US Government | Employment counts, wages, projections | 867 detailed occupations | ❌ None |
| **O\*NET** | US DoL / ONET Center | Tasks, skills, knowledge, abilities per occupation | 1,016 occupation titles (~55,000 job titles) | ✅ Deep — KSAOs, tasks, work context |
| **ESCO** | European Commission | Skills, qualifications, and occupations for EU labor market | 3,007 occupations, 13,939 skills | ✅ Deep — essential + optional skills per occupation |
| **ISCO** | ILO / UN | International comparison standard | 4-digit unit groups | ❌ None (structural only) |
| **SFIA** | SFIA Foundation | IT and digital skills specifically | 120 skills across 7 levels | ✅ IT-specific — proficiency levelled |
| **Lightcast** | Private (Lightcast) | Real-time skill demand from live job postings | Dynamic, constantly updated | ✅ Trending — based on actual job ads |

### Similarities Across Taxonomies

- **Hierarchical structure**: SOC, O\*NET-SOC, ESCO, and ISCO all use nested category trees. SOC and ISCO share alignment at the major group level, and ESCO extends ISCO's 4-digit unit groups to 5-digit codes. O\*NET builds directly on the 2018 SOC structure.
- **Occupation as the common anchor**: Every taxonomy organizes its data *around* occupations as the primary entity, even when the taxonomy's value lies in what hangs off the occupation (skills in ESCO, tasks in O\*NET, proficiency levels in SFIA, demand signals in Lightcast).
- **Education and training crosswalks**: SOC, O\*NET, and ESCO all capture education entry requirements, enabling learner-to-occupation matching.
- **Cross-taxonomy interoperability**: SOC codes serve as the universal join key. O\*NET-SOC codes align to 2018 SOC; ESCO occupations can be mapped to ISCO, which in turn maps to SOC. Lightcast's proprietary taxonomy crosswalks to SOC for standardization.

## How Taxonomy Understanding Adds Value to AI Agents

> **TA Goal**: *"A suite of AI Graph Agents that empower humans to navigate the landscape of skills, tasks, and occupations for lifelong learning in the age of AI."*

Understanding occupational taxonomies is not a prerequisite formality — it is the structural foundation that makes the agents' outputs trustworthy, comparable, and interoperable.

### 1. Structured Vocabulary Enables Precision Retrieval

Without a taxonomy, an AI agent answering "what jobs can I get with Python?" would match on surface keywords. With BLS SOC codes as anchors and O\*NET/ESCO skill mappings, the agent can traverse *semantically structured* relationships: `Python` → `skill node` → `[:REQUIRES_SKILL]` → `{list of SOC-coded occupations}` → `[:HAS_PROJECTION]` → growth data. The result is a ranked, data-grounded recommendation rather than a fuzzy keyword match.

**Example — How BLS specifically improves the Locator Agent:**  
BLS `percent_change` and `median_wage` data, stored as graph nodes, let the Locator rank career recommendations not just by skill match but by economic viability. A user upskilling toward a role that is declining (-8% projected) should know this. Without BLS data in the graph, this signal is invisible.

### 2. SOC Codes as Universal Join Keys for Agent Memory

When an AI agent reasons about a user across sessions (lifelong learning context), it needs a stable, canonical identifier for "the occupation this user is targeting." SOC codes are that identifier. They allow the graph to link BLS wage data, O\*NET task lists, ESCO skill requirements, and Lightcast real-time demand signals into a single traversal — all using the same 6-digit key.

**Example — How ESCO improves the Connector Agent:**  
ESCO explicitly marks skills as *essential* or *optional* for each occupation and provides multilingual labels. A Connector Agent that has ingested ESCO data can tell a learner: "To transition from occupation 15-1132 (Software Developer) to 15-2051 (Data Scientist), you already have 7 of 12 essential skills. Here are the 5 gaps." This kind of gap analysis is impossible without a skills taxonomy attached to occupational nodes.

### 3. O\*NET Tasks Enable Finer-Grained Career Change Reasoning

O\*NET breaks occupations into discrete task lists, which means two occupations that look very different at the SOC title level may share 60% of their underlying tasks. An AI agent that only knows SOC titles would advise a user to start learning from scratch. An agent with O\*NET task overlap in its graph can identify "adjacent" transitions requiring minimal retraining — a critical feature for a lifelong learning platform where user effort is a finite resource.

### 4. Lightcast Prevents the "Stale Taxonomy" Problem

BLS projections update every two years and O\*NET is revised periodically. Lightcast is continuously updated from live job postings, meaning it captures emerging skills (e.g., "prompt engineering," "LLM fine-tuning") before they appear in formal taxonomies. An AI agent that cross-references BLS occupational projections with Lightcast real-time skill demand can surface the gap between what BLS says a Data Scientist needs (entry education: Bachelor's degree) and what employers are *actually* asking for this week.

### 5. SFIA Adds Proficiency Depth for Technical Skill Assessment

For technology-oriented occupations, SFIA's 7-level proficiency scale (Follow → Assist → Apply → Enable → Ensure/Advise → Initiate/Influence → Set Strategy) gives the AI agent a way to assess not just *whether* a user has a skill, but *at what level*. A Connector Agent enriched with SFIA data can present a roadmap: "You're at SFIA Level 3 (Apply) in Cloud Computing. You need Level 5 (Ensure/Advise) for a Cloud Architect role. Here are the specific responsibilities that define that gap."

---

## Tech Stack & Frameworks

| Component | Technology | Purpose |
|---|---|---|
| **Data Source** | BLS Occupation.xlsx (Table 1.2) | 2024–34 employment projections |
| **Data Ingestion** | `pandas` | Read, clean, filter, and transform raw Excel data |
| **Graph Database** | **Neo4j Aura** (cloud-managed) | Persistent property graph storage |
| **Graph Driver** | `neo4j` Python driver | Session management, Cypher execution |
| **ETL** | Custom Python pipeline (`data_loader.py`, `graph_builder.py`) | Extract → Clean → MERGE into Neo4j |
| **Cypher Patterns** | `MERGE`, `CALL {}` subqueries, `UNWIND` | Idempotent node/relationship creation |
| **Config & Secrets** | `python-dotenv` | Secure credential management via `.env` |
| **Graph Query Pattern** | Hub-and-spoke with `MERGE` on satellite values | Shared nodes for categorical data (EducationLevel) |
| **Future: Enrichment** | O\*NET API, ESCO SPARQL endpoint, Lightcast API | Add skills, tasks, and demand signals |
| **Future: Agent Layer** | LangGraph + Neo4j GraphRAG | Multi-agent career navigation on top of this graph |

---

## Project Structure

```
occupation-graph/
│
├── config.py              # Neo4j URI, credentials, data path (loaded from .env)
├── database.py            # Neo4jConnection class — driver, verify, execute_write
├── data_loader.py         # extract_and_clean_data() — pandas ETL from Table 1.2
├── graph_builder.py       # build_occupation_nodes() — Cypher MERGE pipeline
├── main.py                # Orchestration entry point
│
├── data/
│   └── occupation.xlsx    # BLS source data (not committed — add to .gitignore)
│
├── .env                   # NEO4J_URI, NEO4J_USERNAME, NEO4J_PASSWORD (never commit)
├── .env.example           # Template for required environment variables
├── requirements.txt
└── README.md
```

---

## Setup & Usage

### Prerequisites

- Python 3.10+
- A [Neo4j Aura](https://neo4j.com/cloud/platform/aura-graph-database/) free or paid instance
- BLS `occupation.xlsx` downloaded from [bls.gov/emp](https://www.bls.gov/emp/) and placed in `data/`

### Installation

```bash
git clone <repo-url>
cd occupation-graph
pip install -r requirements.txt
```

### Environment Configuration

Create a `.env` file in the project root:

```env
NEO4J_URI=neo4j+s://<your-instance>.databases.neo4j.io
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=<your-password>
```

### Run the Pipeline

```bash
python main.py
```

Expected output:
```
Initiating Database Connection...
Successfully connected to Neo4j Aura!
Reading data from data/occupation.xlsx...
Successfully processed 832 detailed occupations.

🚀 Starting Multi-Node Knowledge Graph construction...
Graph successfully built! Modeled 832 occupations with full taxonomy.
Database connection closed.
```

### Verify in Neo4j Browser

```cypher
// Check node counts
MATCH (n) RETURN labels(n)[0] AS label, COUNT(n) AS count

// Sample traversal
MATCH (o:Occupation)-[:HAS_PROJECTION]->(p)-[:PAYS_WAGE]->()
RETURN o LIMIT 5
```

