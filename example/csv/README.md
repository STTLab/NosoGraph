# Example CSV files

## Important information about IDs

IDs are used to uniquely identify records and link data together (for example, connecting a patient to their admissions or a ward to a department).

- An ID must uniquely identify one record (no duplicates).
- If your data already includes IDs, you can use them directly.
- If not, you can create your own IDs—there’s no single “correct” format.

If the database is to be used by multiple users or integrate data accross projects,
users should agree on a consistent format for IDs before starting, and make sure
everyone follows the same approach to avoid duplicates or broken links

Examples of creating IDs:

| ID           | Recommendation               | Example                          |
| :----------- | :--------------------------- | :------------------------------- |
| patient_id   | Directly use HN              | P001, P002                       |
| ward_id      | -                            | W01, ICU_01                      |
| admission_id | Obtain form admission record | patient_id + ward_id + date      |
| specimen_id  | Obtain form lab barcode no.  | patient_id + sample_type + date  |

> [!NOTE]
> Beware when combining data from multiple sources.
>
> The same ID may refer to different entities in different systems.
>
> For example, HN:0001 from Hospital A is not the same as HN:0001 from Hospital B
> Using them as-is could lead to overwriting or merging unrelated records

## Setting up our hospital

Before loading patients and clinical events, we first establish a core hospital backbone.
This includes static reference data such as departments and wards,
which other entities (patients, admissions, transfers) will link to.

### Departments.csv

Defines the high-level organizational units within the hospital.

| Property      | Type   | Required | Description                            | Example            |
| ------------- | ------ | -------- | -------------------------------------- | ------------------ |
| department_id | String | ☑        | Unique identifier for the department   | D01                |
| name          | String | ☑        | Department name                        | Cardiology         |
| description   | String | ☐        | Optional description of the department | Heart-related care |

### Wards.csv

Defines physical wards within departments. Each ward typically belongs to a department.

| ![Nodes and relationships from Wards table](/README/Images/csv_example_ward-dept.jpg?raw=false "")

| Property      | Type   | Required | Description                                                              | Example                     |
| ------------- | ------ | -------- | ------------------------------------------------------------------------ | --------------------------- |
| ward_id       | String | ☑        | Unique identifier for the ward                                           | W05                         |
| department_id | String | ☑        | Reference to the department                                              | D03                         |
| name          | String | ☑        | Ward name                                                                | Male Surgical               |
| ward_type     | String | ☐        | Category of care level or function of the ward (e.g., General, ICU, CCU) | General                     |
| description   | String | ☐        | Optional description of the ward                                         | General post-operative ward |

### Antibiotic.csv

Defines standardized antibiotic medications that can later be referenced in lab result or treatment records.

| Property      | Type   | Required | Description                          | Example                     |
| ------------- | ------ | -------- | ------------------------------------ | --------------------------- |
| antibiotic_id | String | ☑        | Unique identifier for the antibiotic | A001                        |
| name          | String | ☑        | Generic name of the antibiotic       | Amoxicillin                 |
| abbreviation  | String | ☐        | Common short form or abbreviation    | AMX                         |
| class         | String | ☑        | Antibiotic class                     | Penicillin                  |
| description   | String | ☐        | Additional notes                     | Treats bacterial infections |

## Patient metadata

### Patients.csv

This file outline properties of Patient nodes.

| Property      | Type   | Required | Description                                                                     | Example    |
| ------------- | ------ | -------- | ------------------------------------------------------------------------------- | ---------- |
| patient_id    | String | ☑        | Unique identifier for the patient (primary key used for matching/merging nodes) | P001       |
| firstname     | String | ☑        | Patient’s given name                                                            | John       |
| lastname      | String | ☑        | Patient’s family name                                                           | Doe        |
| sex           | String | ☐        | Biological sex of the patient (e.g., "M", "F", "Other")                         | M          |
| date_of_birth | Date   | ☐        | Patient’s date of birth (ISO format: YYYY-MM-DD)                                | 1985-06-15 |

## Admissions

### Admissions.csv

This file outlines properties of Admission nodes (or events).

| ![Nodes and relationships from Admissions table](/README/Images/csv_example_admission.jpg?raw=true "")

| Property          | Type     | Required | Description                                                       | Example             |
| ----------------- | -------- | -------- | ----------------------------------------------------------------- | ------------------- |
| patient_id        | String   | ☑        | Reference to the patient                                          | P001                |
| admission_id      | String   | ☐        | Unique identifier for the admission (can be generated if missing) | A1001               |
| ward_id           | String   | ☑        | Identifier for the ward                                           | W01                 |
| room_no           | String   | ☐        | Room number within the ward                                       | 101                 |
| bed_no            | String   | ☐        | Bed number within the room                                        | B1                  |
| date_of_admission | DateTime | ☑        | Admission timestamp                                               | 2025-01-10T14:00:00 |
| date_of_discharge | DateTime | ☐        | Discharge timestamp                                               | 2025-01-15T10:00:00 |
| length_of_stay    | Integer  | ☐        | Duration of stay in days (used if discharge date is unavailable)  | 5                   |

> [!NOTE]
> **Admission ID generation**
>
> `admission_id` is requried to maintain uniqueness of a node
> can be user generated if missing e.g.:
>
> `admission_id = patient_id + "_" + ward_id + "_" + date_of_admission`
> `admission_id = P001_W01_2025-01-10`

## Transfers

| ![Nodes and relationships from Transfers table](/README/Images/csv_example_admission_transfers.jpg?raw=true "")

### Transfers_option_A.csv

This approach links admissions directly.

| Property          | Type     | Required | Description              | Example             |
| ----------------- | -------- | -------- | ------------------------ | ------------------- |
| patient_id        | String   | ☑        | Reference to the patient | P001                |
| from_admission_id | String   | ☑        | Source admission         | A1001               |
| to_admission_id   | String   | ☑        | Target admission         | A1002               |
| date_of_transfer  | DateTime | ☑        | Transfer timestamp       | 2025-01-12T09:30:00 |

### Transfers_option_B.csv

This approach captures full movement details without relying strictly on admission IDs.

| Property          | Type     | Required | Description                                           | Example             |
| ----------------- | -------- | -------- | ----------------------------------------------------- | ------------------- |
| patient_id        | String   | ☑        | Reference to the patient                              | P001                |
| from_admission_id | String   | ☐        | Source admission (if available)                       | A1001               |
| from_ward_id      | String   | ☑        | Origin ward                                           | W01                 |
| from_room_no      | String   | ☐        | Origin room                                           | 101                 |
| from_bed_no       | String   | ☐        | Origin bed                                            | B1                  |
| date_of_admission | DateTime | ☑        | Start time of stay in origin location                 | 2025-01-10T14:00:00 |
| date_of_transfer  | DateTime | ☑        | Transfer timestamp                                    | 2025-01-12T09:30:00 |
| to_admission_id   | String   | ☐        | Target admission (if available)                       | A1002               |
| to_ward_id        | String   | ☑        | Destination ward                                      | W02                 |
| to_room_no        | String   | ☐        | Destination room                                      | 202                 |
| to_bed_no         | String   | ☐        | Destination bed                                       | B2                  |
| date_of_discharge | DateTime | ☐        | End time of stay in destination location              | 2025-01-15T10:00:00 |
| length_of_stay    | Integer  | ☐        | Duration in days (fallback if discharge date missing) | 5                   |

## Sequencing data

### Sequnencing_Runs.csv

### Variants.csv

This file outlines properties of variant calls generated by Snippy for a single sample, with an additional REF_ACC column added to uniquely identify the reference assembly accession, particularly in cases where the reference genome consists of multiple contigs or chromosomes.

The combination of REF_ACC, REF, ALT, and POS acts as a composite key for identifying unique variants across samples. In Neo4j, this enables multiple sample nodes to connect to the same variant node when the exact same mutation is observed against the same reference genome/assembly.

| Property  | Type    | Required | Description                                                                                                                                     | Example            |
| --------- | ------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| REF_ACC   | String  | ☑        | Primary reference assembly accession used to distinguish variants across assemblies or multi-contig genomes. Part of the composite variant key. | NZ_CP023401.1      |
| CHROM     | String  | ☑        | Reference contig/chromosome identifier where the variant occurs.                                                                                | NZ_CP023401        |
| POS       | Integer | ☑        | 1-based genomic coordinate of the variant on the reference sequence. Part of the composite variant key.                                         | 930                |
| TYPE      | String  | ☑        | Variant type reported by Snippy (e.g., `snp`, `complex`, `ins`, `del`).                                                                         | snp                |
| REF       | String  | ☑        | Reference allele/base(s). Part of the composite variant key.                                                                                    | C                  |
| ALT       | String  | ☑        | Alternate allele/base(s) observed in the sample. Part of the composite variant key.                                                             | T                  |
| EFFECT    | String  | ☐        | Predicted functional consequence of the variant.                                                                                                | synonymous_variant |
| IMPACT    | String  | ☐        | Predicted severity of the variant effect (`LOW`, `MODERATE`, `HIGH`, `MODIFIER`).                                                               | LOW                |
| LOCUS_TAG | String  | ☐        | Gene or locus associated with the variant.                                                                                                      | BAZ09_RS00005      |
| HGVS_C    | String  | ☐        | HGVS coding DNA notation describing the nucleotide-level change.                                                                                | c.765C>T           |
| HGVS_P    | String  | ☐        | HGVS protein-level annotation describing the amino acid change.                                                                                 | p.Ser255Ser        |

## Microbiology

### Organisms.csv

Reference list of organisms, keyed by NCBI taxonomy id.

| Property | Type   | Required | Description                          | Example               |
| -------- | ------ | -------- | ------------------------------------ | --------------------- |
| taxid    | String | ☑        | NCBI Taxonomy id (Organism identity) | 573                   |
| sciname  | String | ☑        | Scientific name                      | Klebsiella pneumoniae |
| strain   | String | ☐        | Strain designation                   | KP-1                  |

### ReferenceGenomes.csv

Reference genomes used for variant calling / typing. `ReferenceGenome -[:REFERENCE_GENOME_OF]-> Organism`.

| Property       | Type   | Required | Description                                | Example                      |
| -------------- | ------ | -------- | ------------------------------------------ | ---------------------------- |
| accession_no   | String | ☑        | Accession (ReferenceGenome identity)       | NZ_CP023401.1                |
| name           | String | ☐        | Human-readable genome name                 | Klebsiella pneumoniae chrom. |
| molecular_type | String | ☐        | Molecule type                              | DNA                          |
| strain         | String | ☐        | Strain designation                         | KP-1                         |
| taxid          | String | ☐        | Links the genome to an Organism by `taxid` | 573                          |

### Specimens.csv

Specimens collected from patients. `Specimen -[:COLLECTED_FROM]-> Patient`.

| Property        | Type   | Required | Description                                    | Example           |
| --------------- | ------ | -------- | ---------------------------------------------- | ----------------- |
| specimen_id     | String | ☑        | Unique identifier for the specimen             | SP001             |
| patient_id      | String | ☑        | Reference to the patient the specimen was from | P001              |
| specimen_type   | String | ☐        | Sample type                                    | blood             |
| specimen_class  | String | ☐        | High-level class                               | biological        |
| category        | String | ☐        | Test/handling category                         | bacterial culture |
| collection_date | Date   | ☐        | Collection date (ISO YYYY-MM-DD)               | 2025-01-11        |

### Samples.csv

The clinical-to-genomic bridge: maps a sequencing **sample_id** (produced by the pipeline) to the
**specimen** it was sequenced from. `Sample -[:DERIVED_FROM]-> Specimen`.

| Property    | Type   | Required | Description                          | Example  |
| ----------- | ------ | -------- | ------------------------------------ | -------- |
| sample_id   | String | ☑        | Pipeline sample id (Sample identity) | BAC_S001 |
| specimen_id | String | ☑        | The specimen the sample derives from | SP003    |

### LabResults.csv — antibiotic susceptibility (MIC/AST)

Antibiotic susceptibility results, modelled as `:LabResult:BacterialCulture` and wired
`Specimen -[:TESTED_FOR]-> LabResult -[:AGAINST]-> Antibiotic`.

> **Note:** `:LabResult` and its `lab_id` identity are part of the core NosoGraph schema, but the
> `-[:AGAINST]-> Antibiotic` edge and the AST-specific properties (`interpretation`, `organism_taxid`,
> `antibiotic_id`) are a **public NosoGraph extension** pending a dedicated AMR handler in the
> interface library. The lab-result node itself stays schema-compatible.

| Property       | Type   | Required | Description                                     | Example    |
| -------------- | ------ | -------- | ----------------------------------------------- | ---------- |
| lab_id         | String | ☑        | Unique identifier for the result (LabResult id) | LR001      |
| specimen_id    | String | ☑        | Specimen tested                                 | SP001      |
| result_type    | String | ☐        | Result type                                     | MIC        |
| test_date      | Date   | ☐        | Test date (ISO YYYY-MM-DD)                      | 2025-01-12 |
| value          | String | ☐        | Measured value (e.g. MIC)                       | 4          |
| unit           | String | ☐        | Unit of the value                               | mg/L       |
| notes          | String | ☐        | Free-text notes                                 |            |
| organism_taxid | String | ☐        | Organism tested (links to Organisms.csv)        | 573        |
| antibiotic_id  | String | ☐        | Antibiotic tested (links to Antibiotic.csv)     | A006       |
| interpretation | String | ☐        | Clinical interpretation (`S` / `I` / `R`)       | S          |

## Pipeline-produced genomic CSVs (`<sample_id>/kg/`)

The remaining nodes (Sample assembly/contig provenance) are **not** hand-authored — the assembly
pipeline writes them per sample to `<outdir>/<sample_id>/kg/` (`sample.csv`, `assembly.csv`,
`biodata_files.csv`, `contigs.csv`) via `report/kg_export.py`. Copy that `kg/` directory into the
Neo4j import directory next to these clinical CSVs and load it with the `10`–`15` templates in
`assets/nosograph_cypher_templates.csv`.
