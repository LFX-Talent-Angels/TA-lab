# Talent Angels — One Pager

**Aman Kumar Sarraf**

---

## Recommendation

Talent Angels should work as **one assistant** over a map of skills, tasks, and occupations. It understands the user’s goal, looks up facts on that map, and returns **one** clear answer with evidence. Technology is chosen only to support that design.

**Locator**, **Connector**, and **Pathfinder** are three kinds of map work—find a place, look around, suggest a route—not three separate assistants that hand the user between them.

---

## Problem

People struggle to see where they stand among real occupations, skills, and tasks, and what to learn or try next with evidence they can trust—not marketing and not pure guesswork.

---

## How the system is structured

From that problem, useful work on the map has three steps:

1. **Find the right place** — turn the person’s words into a precise point on the map  
2. **Look around** — show what sits next to that point  
3. **Suggest a route** — propose steps between two points using clear rules, not “shortest path only”  

| Piece | What it is | What it does |
|-------|------------|--------------|
| **Main assistant** | The only conversation partner | Owns the user’s goal from start to finish; decides which map steps are needed; writes the final answer; remembers the conversation |
| **Locate** | Map lookup | Finds the right skills, tasks, or occupations for the user’s words, with a confidence level |
| **Connect** | Map lookup | Shows relationships, comparisons, and gaps |
| **Pathfind** | Map lookup | Proposes routes under stated rules |
| **Skills and occupation maps** | Trusted reference data | Source of facts and citations (for example O\*NET; other maps such as ESCO or SFIA use the same pattern) |
| **Conversation memory and activity log** | Bookkeeping | Remembers constraints across turns and records what was looked up |

Several official maps can be used. The assistant uses the **same kind of plan** for each map and combines the results. If two maps disagree or have no link, it says so—it does not invent a match. A separate “scoring judge” product is not part of this proposal; the activity log leaves room for quality review later.

---

## Why the main lines are drawn this way

| Design choice | Why |
|---------------|-----|
| The user talks only to the main assistant | One place holds the full goal across every step of the conversation |
| Locate, Connect, and Pathfind do not answer the user on their own | If three parties answer, context is lost and advice can conflict |
| Map lookups are helpers, not separate bosses | Looking up facts is mechanical; deciding what helps the user stays with the main assistant |
| Facts come from the map | Claims must be checkable; guesses by the language model are labeled as such |
| Same pattern for every skills map; no invented links between maps | Different official sources stay honest when they disagree or do not connect |
| Confidence is carried forward; important matches can be confirmed with the user | A wrong starting point would silently ruin everything that follows |

---

## What the user should understand

The product is a **map guide**: find a place, look around, plot a route. It shows sources, admits uncertainty, and lets the user correct it. It does not replace the user’s judgment about their own life.

---

## Technology choices

| Choice | Why this design needs it |
|--------|---------------------------|
| **Graph database (Neo4j)** | Skills and jobs form a network of connections that must be inspected and followed reliably |
| **Loading data into each map before chat** | Structure and names are prepared up front, not invented mid-conversation |
| **Workflow engine (LangGraph)** | Keeps one assistant in control of the goal, the plan, and the lookups |
| **Language model** | Understands questions, handles ambiguity, chooses a plan, and writes the answer—only where judgment is needed |
| **Structured outputs (Pydantic)** | Answers and lookup results have a fixed shape so they can be checked |
| **Optional meaning-based search** | Helps when the user’s wording does not exactly match map labels |

**Not in this proposal:** three equal product assistants, treating “shortest path” as success, inventing links between official maps, or building accounts and billing systems.

---

## Risks

A risk is something that **might happen later** and would hurt delivery if it does—not a problem we already accept as fact. We capture these early and revisit them as we build.

| Risk | If it happens | What we do to reduce it |
|------|----------------|-------------------------|
| We treat Locate, Connect, and Pathfind as three equal assistants with no single owner | We redesign and rewrite before anything useful ships | One main assistant owns the answer; the three names are map lookups under it |
| We pick tools before we agree the design | We rebuild connections, data stores, and workflows | Every tool on this page must be forced by a design choice above |
| Each skills map is integrated in its own one-off way | We cannot combine multiple official maps without costly custom work for each | Same plan pattern for every map; combine results honestly |
| The system pretends two concepts on different maps are the same without a real link | Users get wrong advice; trust collapses | Only link maps when a real mapping exists; otherwise say “no link” |
| We try to build too much at once (extra judges, many agents, vanity metrics) | The basic “question → map → one grounded answer” loop never ships | Clear “not now” list; keep an activity log so quality review can come later |
| The system pins the wrong place on the map and builds on that error | Users get confident wrong paths | Show confidence; confirm important matches; let users correct without starting over |

---
