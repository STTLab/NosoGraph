# NosoGraph demo-kit

A small, self-contained bundle for **demoing the NosoGraph knowledge graph** without running
the pipeline or hosting the reference databases. Load the pre-built CSVs into Neo4j and explore
two real clinical *Chryseobacterium* isolates (**CI16**, **CI19**) joined to a synthetic
patient/clinical layer.

## Contents

| Path | What it is |
|---|---|
| `kg_output/<sample>/` | Pipeline-produced, Neo4j-ready KG CSV bundle (7 CSVs/sample: 3 metagenomics + 4 assembly). |
| `patient_metadata/` | **Synthetic** clinical-layer CSVs (hospital backbone + patients, specimens, samples, organisms, antibiotics, MIC lab results). |
| `nosograph_e2e_replication.ipynb` | Optional — how the `kg_output/` bundles were produced from raw reads (edit the config cell for your host). |

## How the layers connect

```
Patient ──┐
          ├─ Admission ─ Ward ─ Department         (patient_metadata/)
Specimen ─┘
   │ Samples.csv: sample_id ↔ specimen_id          ← the join to the pipeline
   ▼
Sample ─ Assembly ─ Contig{accession}              (kg_output/, assembly side)
   │
   └─ TaxonomicClassification ─ Organism{taxid}    (kg_output/, metagenomics side)
LabResult{MIC} ─ Organism{taxid} ─ Antibiotic      (patient_metadata/)
```

The pipeline's `sample_id` (`CI16`, `CI19`) is the key in `patient_metadata/Samples.csv`, so
loading both folders stitches the clinical context onto the sequencing results.

## Loading into Neo4j

Use the saved-query templates in [`../../assets/nosograph_cypher_templates.csv`](../../assets/nosograph_cypher_templates.csv)
(import via Neo4j Browser). Copy `patient_metadata/*.csv` and `kg_output/<sample>/*.csv` into
the database `import/` directory, then run the `LOAD DATA` steps — hospital backbone +
patients/specimens/samples first, then the assembly bundle, then the metagenomics steps.
Finish with **QUERIES → Pathogens detected per sample** to verify.

## ⚠️ Notes

- **`patient_metadata/` is entirely synthetic** — fabricated names, dates, wards and MIC values
  for demonstration only. **Not real patient data.**
- **`BioDataFile` URIs are portable placeholders.** `kg_output/.../biodata_files.csv`,
  `meta_reads.csv` and `taxonomic_classification.csv` reference `data/<sample>.long.fq.gz` and
  `assemblies/<sample>.fasta` rather than absolute host paths. Point them at your own copies of
  the reads/assembly if you need the files resolvable at load time; they are not required to
  populate the graph structure.
- The KG CSVs are bacterial genomic data (no human PII). Confirm redistribution rights for the
  underlying isolate sequences before publishing derivatives.
