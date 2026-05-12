# Cypher Query Examples

This directory contains example Cypher queries used by the project for interacting with the Neo4j graph database.

The queries are intended as reusable examples and reference implementations for common graph operations such as:

- Creating nodes
- Creating relationships
- Matching/querying entities
- Deleting graph structures
- Defining database constraints

The directory is incomplete and evolving over time. Not every supported entity or operation is necessarily represented here.

## Example Contents

Examples currently include operations related to:

- Patients and admissions
- Wards and hospital structure
- Specimens and samples
- Laboratory results
- Organisms and reference genomes
- Assembly runs and contigs

Notes:

- Some queries assume prerequisite nodes already exist
- Query naming conventions may change as the schema evolves
- Queries are primarily written for Neo4j Community Edition
- Certain schema patterns emulate enterprise features using Community Edition-compatible constraints

## Usage

These `.cypher` files are intended as example queries and templates.

To use them manually in Neo4j Browser or Neo4j Desktop:

1. Open a `.cypher` file
2. Copy and paste the query into the Cypher editor
3. Replace parameter placeholders (variables prefixed with `$`) with actual values
4. Execute the modified query

Example template query:

```cypher
CREATE (:Patient {
    patient_id: $patient_id
})```

Should be used as:
```cypher
CREATE (:Patient {
    patient_id: "P0001"
})```

## Constraints

The _CONSTRAINTS.cypher file contains database constraints and indexes required by the schema.

This file should typically be executed once during initial database setup before running other queries.

Example workflow:

1. Start Neo4j
2. Run _CONSTRAINTS.cypher
3. Run CREATE_* queries
4. Run ASSOCIATE_* queries
5. Use MATCH_* queries for testing and exploration

## File naming Convention

| Prefix         | Purpose                        |
| -------------- | ------------------------------ |
| `CREATE_`      | Create nodes                   |
| `ASSOCIATE_`   | Create relationships           |
| `MATCH_`       | Query graph data               |
| `DELETE_`      | Delete nodes or relationships  |
| `_CONSTRAINTS` | Create constraints and indexes |

