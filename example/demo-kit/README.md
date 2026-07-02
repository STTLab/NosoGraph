# NosoGraph demo-kit

A small, self-contained bundle for **demoing the NosoGraph knowledge graph** without running the
pipeline or hosting the reference databases. Load the pre-built CSVs into Neo4j and explore two
real, de-identified clinical *Chryseobacterium indologenes* isolates (**sample_01**, **sample_02**) that tie
a patient's clinical context — comorbidities, admission, labs, antibiotic susceptibility — to the
sequenced isolate and its resistance genotype.

The kit exercises all three NosoGraph layers end to end:

1. **Clinical terminology** — SNOMED CT concepts (disorders, findings, clinical history, devices).
2. **Patient & clinical metadata** — patients, admissions, wards, specimens, samples, MIC/AST and
   CBC lab results, antibiotics.
3. **Microbiology & genomics** — the sequenced isolate, its genome assembly, and AMR genes.

## Contents

| Path | What it is |
|---|---|
| `clinical/` | Clinical-layer CSVs (hospital backbone, patients, admissions, specimens, samples, organisms, antibiotics + drug classes, MIC lab results, CBC haematology, and the SNOMED terminology + patient/admission condition links). |
| `genomics/` | Genome assembly and acquired AMR genes per isolate (`Assembly.csv`, `ResistanceGenes.csv`), the raw-read provenance (`BioDataFiles.csv`, placeholder URIs), plus a curated chromosomal-variant layer: annotated `Features.csv` (resistance-relevant loci incl. `penA`), `VariantCallingRuns.csv` (Snippy), and `Variants.csv`. |
| `nosograph_demo_cypher_templates.csv` | Neo4j Browser saved-queries file — constraints, ordered `LOAD DATA` steps for every CSV, and ready-made demo `QUERIES`. |

## How the layers connect

```
        SNOMED (Disorder / Finding / Situation / Device)      (clinical/Terminology.csv)
          ▲  HAS_DISORDER / HAS_CLINICAL_FINDING / HAS_CLINICAL_HISTORY
Patient ──┼─ HAS_ADMISSION ─▶ Admission ─ ADMITTED_TO ─▶ Ward ─ BELONGS_TO ─▶ Department
   ▲      └─ HAS_PRINCIPAL_DIAGNOSIS / USE_DEVICE ─▶ SNOMED          │ HAS_CBC ▼
   │ COLLECTED_FROM                                           LabResult:CBC  (clinical/CBC.csv)
Specimen ─ TESTED_FOR ─▶ LabResult:BacterialCulture ─ AGAINST ─▶ Antibiotic   (MIC / AST)
   ▲ DERIVED_FROM                          Antibiotic ─ BELONGS_TO ─▶ AntibioticClass
Sample ─ IDENTIFIED_AS ─▶ Organism{taxid}                    ← clinical↔genomic join
   ├ HAS_ASSEMBLY ─▶ Assembly ─ FOUND ─▶ Gene               (genomics/, acquired AMR genes)
   │                    └ ASSEMBLED_FROM ─▶ BioDataFile{uri} (genomics/, raw-read provenance)
   └ HAS ─▶ VariantCallingRun ─ CALLED ─▶ Variant ─ AFFECTS ─▶ Feature{name}
                                                             (genomics/, chromosomal variants incl. penA)
```

`Samples.csv` (`sample_id ↔ specimen_id`) is the bridge that stitches the clinical context onto
the sequenced isolate, so a single query can trace a patient's comorbidities to the resistance
genotype of the organism cultured from them.

## Loading into Neo4j

Everything is driven by [`nosograph_demo_cypher_templates.csv`](./nosograph_demo_cypher_templates.csv)
(import via Neo4j Browser → saved queries):

1. Copy the `clinical/` and `genomics/` folders into your DBMS `import/` directory (keep the
   sub-folder names — the load queries read e.g. `file:///clinical/Patients.csv`).
2. Run **SETUP → 00 Constraints** once.
3. Run the **LOAD DATA** steps in order (`01`–`18`): clinical backbone → terminology → genomics.
4. Get oriented with the **VISUALIZATION — basic relations** folder (each returns a subgraph that
   Neo4j Browser draws): clinical backbone, specimen→susceptibility, patient conditions,
   clinical–genomic spine, resistance genotype, and a full one-isolate ego-network.
5. Then explore the analytical **QUERIES** — **Clinical–genomic spine**, **AMR phenotype vs.
   genotype**, **Patient comorbidity & outcome profile**, **Beta-lactam resistance: MIC phenotype +
   penA genotype**, and **Pan-drug-resistant isolates**.

Requirements: Neo4j 5+/2025 with the **APOC** plugin (used by the CBC loader). All load queries
use `MERGE` and are idempotent, so re-running is safe.

## What's in the demo

Two urine isolates of *C. indologenes* (NCBI taxid 253), both **pan-drug-resistant** across the
9-antibiotic panel and both carrying the same 9 AMR genes (incl. `blaIND-2`, `blaCIA-4`,
`blaOXA-347`). sample_01 — 63 y/o male, private ward, principal diagnosis bacterial pneumonia; sample_02 —
44 y/o male, surgical ward, principal diagnosis malignant neoplasm of rectum. Both admissions
record devices, comorbidities, a CBC, and a fatal outcome — a compact but complete surveillance
vignette.

On the genotype side, both isolates carry the same 9 acquired AMR genes **and** share an
identical chromosomal `penA` (PBP2) missense variant — `p.Gly345Asp` — so the demo can trace a
β-lactam *phenotype* (MIC) to a resistance *genotype* in a single path (see the **Beta-lactam
resistance** query). The variant layer is curated to resistance-relevant loci rather than the full
~5,000-variant Snippy call set.

## ⚠️ Notes

- **This is real, de-identified clinical data**, not synthetic. Patients carry no names or dates
  of birth — only a study code (`P-sample_01`), sex, and age; hospital numbers, admission dates and CBC
  dates are removed or masked at source. Confirm your data-governance/redistribution rights before
  publishing derivatives.
- **Departments are inferred** from the ward context (sample_02's ward is literally *Surgery Male Ward
  2* → Surgery; sample_01's private ward is grouped under Medicine given the pneumonia
  diagnosis). They are an organisational convenience, not a source field.
- **The `FOUND ─▶ Gene` (AMR) edge is a public NosoGraph extension** pending a dedicated AMR
  handler in the interface library; the assembly-level genotype is otherwise schema-compatible.
- Assemblies are the published NCBI genomes (`ASM5082198v1`, `ASM5070351v1`); this kit models them
  at assembly + AMR-gene level and does not ship per-contig FASTA.
- **Raw reads are referenced, not shipped.** `BioDataFiles.csv` records `BioDataFile` nodes with
  **placeholder URIs** (`data/sample_01.long.fq.gz`, `…short_1/2`, `data/sample_02.long.fq.gz`) —
  sample_01 is a hybrid (long + paired short) run, sample_02 is long-only. The `.fq.gz` files
  themselves are intentionally **not committed** (they are ~1.3 GB and are git-ignored). Point the
  URIs at your own copies, or at SRA/ENA run accessions, if you need the reads resolvable at load
  time; they are not required to populate the graph.
