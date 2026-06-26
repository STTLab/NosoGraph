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

First, clone the repository:

```bash
git clone https://github.com/STTLab/NosoGraph.git
cd NosoGraph
```

### NosoGraph pipeline

The NosoGraph sequencing pipeline supports hybrid and long-read bacterial genome assembly (Flye, Canu), iterative polishing (Racon, Pilon), and quality assessment (CheckM2). It is implemented in [Nextflow](https://www.nextflow.io/) DSL2, which manages Conda environments automatically and supports execution on local machines and HPC clusters (SLURM).

#### Requirements

- [Nextflow](https://www.nextflow.io/docs/latest/install.html) ≥ 23.04
- [Conda](https://docs.conda.io/) or [Micromamba](https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html)

Install Nextflow:

```bash
curl -s https://get.nextflow.io | bash
mv nextflow ~/bin/
```

Conda environments are created automatically by Nextflow on first run — no manual setup required. The assembly → polish → QC pipeline is vendored from [bioinformatics-workflows](https://github.com/minaminii/bioinformatics-workflows) under `modules/vendor/bacterial-assembly/`, which owns its own conda env; additional envs live in the top-level `conda/` directory.

| Environment file | Purpose |
|---|---|
| `modules/vendor/bacterial-assembly/conda/bacterial-assembly.yaml` | Assembly, polishing, and QC tools (Flye, Canu, Racon, Pilon, BWA-mem2, SAMtools, CheckM2) |
| `conda/blast.yaml` | BLAST and sequence comparison tools |
| `conda/medaka.yaml` | Medaka neural-network polishing |

---

#### Pipeline parameters

| Parameter | Description | Default |
|---|---|---|
| `--long_reads` | Long-read FASTQ (gzipped or uncompressed) | required |
| `--read1` | Paired-end short reads R1 (required for Pilon) | — |
| `--read2` | Paired-end short reads R2 (required for Pilon) | — |
| `--assembler` | Assembler: `canu` or `flye` | required |
| `--tech` | Sequencing technology: `nanopore`, `nanopore-hq`, or `pacbio` | required |
| `--genome_size` | Genome size (e.g. `5m`, `2.6g`) — required for Canu | — |
| `--outdir` | Output directory | `results` |
| `--threads` | Threads per process | `1` |
| `--racon_iter` | Racon polishing iterations | `1` |
| `--pilon_iter` | Pilon polishing iterations | `1` |
| `--checkm2_db` | Path to CheckM2 database (`uniref100.KO.1.dmnd`) | — |
| `--queue` | SLURM partition name (`-profile slurm` only) | — |

---

#### Running locally

Hybrid assembly with Flye:

```bash
nextflow run main.nf \
    --long_reads reads.fastq.gz \
    --read1 sample_R1.fastq.gz \
    --read2 sample_R2.fastq.gz \
    --assembler flye \
    --tech nanopore \
    --outdir results \
    --threads 16 \
    --racon_iter 2 \
    --pilon_iter 2 \
    --checkm2_db /path/to/uniref100.KO.1.dmnd
```

Long-read-only assembly with Canu:

```bash
nextflow run main.nf \
    --long_reads pacbio_reads.fastq.gz \
    --assembler canu \
    --tech pacbio \
    --genome_size 5m \
    --outdir results \
    --threads 32
```

---

#### Running on SLURM

Add `-profile slurm` to submit each process as an independent SLURM job. Specify your partition with `--queue`:

```bash
nextflow run main.nf \
    -profile slurm \
    --queue normal \
    --long_reads reads.fastq.gz \
    --assembler flye \
    --tech nanopore \
    --outdir results \
    --threads 16 \
    --racon_iter 2 \
    --pilon_iter 1 \
    --checkm2_db /path/to/uniref100.KO.1.dmnd
```

Default resource allocations per process label (adjustable in `modules/vendor/bacterial-assembly/nextflow.config`):

| Process | CPUs | Memory | Time |
|---|---|---|---|
| Assembly (Flye) | `--threads` | 32 GB | 24 h |
| Assembly (Canu) | `--threads` | 32 GB | 24 h |
| Racon iteration | `--threads` | 32 GB | 24 h |
| Pilon iteration | `--threads` | 28 GB | 12 h |
| CheckM2 | `--threads` | 32 GB | 12 h |

To resume a run after a failure:

```bash
nextflow run main.nf -profile slurm -resume ...
```

---

#### Validating pipeline wiring (no data required)

Use `-stub-run` with `-profile test` to verify the full DAG compiles and all process connections are correct without needing real input files or conda environments:

```bash
nextflow run main.nf -stub-run -profile test \
    --assembler flye \
    --tech nanopore \
    --long_reads dummy.fastq.gz \
    --read1 dummy_R1.fastq.gz \
    --read2 dummy_R2.fastq.gz \
    --racon_iter 2 \
    --pilon_iter 2 \
    --checkm2_db dummy.dmnd \
    --outdir /tmp/nf_test
```

Expected output:

```
[PROCESS] AUTO_BACTERIAL_ASSEMBLY:BACTERIAL_ASSEMBLY:ASSEMBLY_FLYE (1)
[PROCESS] AUTO_BACTERIAL_ASSEMBLY:BACTERIAL_ASSEMBLY:RACON_POLISH (1)
[PROCESS] AUTO_BACTERIAL_ASSEMBLY:BACTERIAL_ASSEMBLY:PILON_POLISH (1)
[PROCESS] AUTO_BACTERIAL_ASSEMBLY:BACTERIAL_ASSEMBLY:CHECKM2 (1)

[SUCCESS] completed=4 failed=0 cached=0
```

The `-profile test` flag disables conda so the stub runs locally without any tools installed. Input file paths are not checked for existence in stub mode — any placeholder string works.

### NosoGraph knowledge graph

This repository provides:

- A conceptual schema defining node labels, relationship types, and data domains
- Example CSV files for data import
- Cypher queries demonstrating common operations and analytical use cases
- Guidance for setting up Neo4j as a working environment

Users can adopt the schema as a starting point, extend it to fit their specific use cases, and integrate it with custom pipelines or applications as needed.

We recommend checking out the example directory to get started.

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

## Acknowledgement

This work was supported by the following funding bodies:

- The Fundamental Fund 2025, Chiang Mai University, Chaing Mai, Thailand (Grant number: 214458).
- The Faculty of Medicine Research Fund, Chiang Mai University (Grant No. 099-2563)
- Support the Children Foundation, Chiang Mai, Thailand.
