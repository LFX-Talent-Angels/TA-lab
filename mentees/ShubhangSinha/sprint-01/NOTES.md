# SFIA Knowledge Graph Draft

## Introduction

The **Skills Framework for the Information Age (SFIA)** is a globally recognized framework used to define professional skills, competencies, and responsibilities within the technology and digital workforce.

SFIA organizes information into:

* Categories
* Subcategories
* Skills
* Responsibility Levels (1–7)

Each skill can exist at one or more responsibility levels, with increasing scope, autonomy, influence, and leadership as the level increases.

| Level | Description                     |
| ----- | ------------------------------- |
| 1     | Follow                          |
| 2     | Assist                          |
| 3     | Apply                           |
| 4     | Enable                          |
| 5     | Ensure, Advise                  |
| 6     | Initiate, Influence             |
| 7     | Set Strategy, Inspire, Mobilise |

---

# Objective

The objective of this draft Knowledge Graph is to represent the hierarchical structure of the SFIA framework and demonstrate how skills are organized and defined across different responsibility levels.

This serves as an initial proof-of-concept before building a complete SFIA Knowledge Graph from the full dataset.

---

# Knowledge Graph Design

The draft graph consists of four node types:

## 1. Category

Represents the highest level grouping of SFIA skills.

Examples:

* Strategy and architecture
* Delivery and operation
* People and skills

---

## 2. Subcategory

Represents subdivisions within a Category.

Examples:

* Strategy and planning
* Security services
* Skills management

Relationship:

```text
(Category)-[:HAS_SUBCATEGORY]->(Subcategory)
```

---

## 3. Skill

Represents an individual SFIA skill.

Examples:

* Strategic planning (ITSP)
* Information systems coordination (ISCO)
* Information management (IRMG)

Relationship:

```text
(Subcategory)-[:HAS_SKILL]->(Skill)
```

---

## 4. SkillLevel

Represents the description of a skill at a particular SFIA responsibility level.

Properties:

```text
level
description
```

Relationship:

```text
(Skill)-[:HAS_LEVEL]->(SkillLevel)
```

---

# Ontology

```text
Category
    │
    └── HAS_SUBCATEGORY
                │
                ▼
          Subcategory
                │
                └── HAS_SKILL
                           │
                           ▼
                          Skill
                           │
                           └── HAS_LEVEL
                                      │
                                      ▼
                                  SkillLevel
```

---

# Example Graph

```text
Strategy and architecture
            │
            ▼
    Strategy and planning
      /        |        \
     /         |         \
  ITSP       ISCO      IRMG
    │          │          │
 Levels     Levels     Levels
```

---

# Sample Skills Used

## ITSP — Strategic Planning

Category:

```text
Strategy and architecture
```

Subcategory:

```text
Strategy and planning
```

Levels:

* Level 4
* Level 5
* Level 6
* Level 7

---

## ISCO — Information Systems Coordination

Category:

```text
Strategy and architecture
```

Subcategory:

```text
Strategy and planning
```

Levels:

* Level 6
* Level 7

---

## IRMG — Information Management

Category:

```text
Strategy and architecture
```

Subcategory:

```text
Strategy and planning
```

Levels:

* Level 3
* Level 4
* Level 5
* Level 6
* Level 7

---

# Cypher Queries Used

## Creating Category and Subcategory

```cypher
MERGE (c:Category {name:"Strategy and architecture"})
MERGE (sc:Subcategory {name:"Strategy and planning"})

MERGE (c)-[:HAS_SUBCATEGORY]->(sc)
```

---

## Creating a Skill

```cypher
CREATE (s:Skill {
    code:"ITSP",
    name:"Strategic planning"
})

CREATE (sc)-[:HAS_SKILL]->(s)
```

---

## Creating a Skill Level

```cypher
CREATE (l4:SkillLevel {
    level:4,
    description:"Contributes to the collection and analysis of information to support strategy development."
})

CREATE (s)-[:HAS_LEVEL]->(l4)
```

---

## Visualising the Graph

```cypher
MATCH p=()-[]->()
RETURN p
```

---

# Conclusion

This draft Knowledge Graph successfully demonstrates the core hierarchical structure of the SFIA framework:

```text
Category
    ↓
Subcategory
    ↓
Skill
    ↓
Skill Level Description
```

The graph serves as a foundational ontology for representing SFIA skills and their progression across responsibility levels.
