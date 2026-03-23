# NosoGraph

NosoGraph is a graph database schema designed for representing and integrating clinical, microbiological, and genomic data in a unified framework. Built on graph data modeling principles, it encodes entities, such as patients, specimens, microorganisms, genes, and variants as nodes, and their relationships as edges, enabling explicit and queryable connections across traditionally siloed datasets.

The schema is intended to support the construction of biomedical knowledge graphs, with a focus on infectious diseases and antimicrobial resistance (AMR). By structuring data around relationships rather than isolated records, NosoGraph enables intuitive exploration of complex questions—for example, linking patient context to microbial isolates, genomic variants, and resistance phenotypes within a single query.

This repository provides the core schema design, example data models, and practical resources for implementation using [Neo4j](https://neo4j.com/), including installation guidance, sample CSV files for data import, and example Cypher queries. NosoGraph is designed to be extensible and adaptable to different research and hospital settings, supporting use cases such as outbreak investigation, genomic epidemiology, and integrated clinical-genomic analysis.

## Knowledge Graph Design Overview

The graph is organized into three interoperable domains, each modeling a different layer of clinical–biological knowledge and linked through explicit relationships.

| ![Figure 1: An illustration of entities relationship pattern for managing bacterial whole genome sequencing data and all relevant information by NosoGraph.](./README/Images/figure_1.png?raw=true "Figure 1")
|:--
| *Figure 1:* An illustration of entities relationship pattern for managing bacterial whole genome sequencing data and all relevant information by NosoGraph. A directed arrow indicates a one-way relationship between entities, while an undirected line indicates bi-directional relationships.

1) Clinical terminology
This layer represents standardized clinical concepts using SNOMED CT, including disorders, clinical findings, situations, and morphologic abnormalities.
SNOMED provide a controlled vocabulary for patient conditions, enabling consistent representation, disease grouping, and provide point of reference to external clinical data.

2) Patient and clinical metadata
This layer stores patient metadata and care processes, including patients' information, admissions, wards, specimens, and laboratory results e.g. MICs, CBC. It captures who the patient is, when and why they were admitted, what specimens were collected, and what tests were done, when, and what are the results forming the clinical context for downstream analyses.

3) Microbiology and genomics layer
This layer represents the biological entities and analyses derived from patient specimens, including isolates, organisms, genome assemblies, genes, features, and variants identified through sequencing pipelines.

## Usage

This repository provides:

- A conceptual schema defining node labels, relationship types, and data domains
- Example CSV files for data import
- Cypher queries demonstrating common operations and analytical use cases
- Guidance for setting up Neo4j as a working environment

Users can adopt the schema as a starting point, extend it to fit their specific use cases, and integrate it with custom pipelines or applications as needed.

It is important to note that, **NosoGraph is not a database management system (DBMS)** and does not provide a complete software platform for data ingestion, storage, or analysis. Instead, it defines a blueprint outlining structured conceptual model that guides how clinical, microbiological, and genomic data should be organized and linked within a graph database. The implementation of the underlying infrastructure (e.g., data pipelines, deployment environment, access control, and application interfaces) is intentionally out of scope of this repository. Users are expected to adapt the schema to their own systems and integrate it with existing workflows or tools.

We recommend using Neo4j as the platform offers an intuitive desktop interface, providing ease-of-use for general users and a mature ecosystem for graph-based development.

> [info]
> **Disclaimer:** This project is not affiliated with, endorsed by, or sponsored by Neo4j, Inc. “Neo4j” and related trademarks are the property of Neo4j, Inc. All references to Neo4j within this repository are for informational and implementation purposes only.

### Quick Start (Neo4j Desktop)

#### 1. Install Neo4j Desktop

Download and install Neo4j Desktop from:

[https://neo4j.com/download/](https://neo4j.com/download/)

Follow instructions to download, install, and launch the application.

#### 2. Create a New Database

1. Choose "Local instances" on the sidebar menu
2. Click "Create instance"
3. Fill instance details according to instructions.
4. Set a database name (e.g., nosograph-db)
5. Set a password and store it securely
6. Click “Create”.
7. Connect to the instance through "Query" or "Explore" menu

#### 3. Prepare Data Import

To import data into Neo4j instance, if using CSV files, the file must be put into an import directory within an instance path. The path can be looked up in instances list in the connection screen `Path: C:\Users\<username>\.Neo4jDesktop2\Data\dbmss\dbms-<instance-id>\import`

```Cyppher
LOAD CSV WITH HEADERS FROM 'file:///<file_name>.csv' AS row
RETURN row;
```

#### 4. Explore the Graph

From Query menu after connected to an instance you may use Neo4j Browser to:

- Visualize relationships interactively
- Expand nodes (double-click)
- Run example queries from this repository
