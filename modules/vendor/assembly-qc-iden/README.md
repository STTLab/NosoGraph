# assembly-qc-iden module

A self-contained Nextflow module that runs **QUAST**, **CheckM2**, and **BLAST** on one
sample's assembly FASTA and emits QC + identification artefacts in a fixed layout that
NosoGraph's KG exporter consumes. It mirrors the `bacterial-assembly` and
`kraken2-classify` modules and is published as a subtree split branch
(`workflow-assembly-qc-iden`) that NosoGraph imports under `modules/vendor/`.

## Scope

- **In:**
  - `--assembly` — assembler consensus/polished multi-FASTA (required).
  - `--reads` — long-read FASTQ(.gz) for QUAST read-mapping stats (optional).
  - `--reference` — reference FASTA for QUAST reference-based stats (optional).
  - `--checkm2_db` — `uniref100.KO.1.dmnd` (required for CheckM2).
  - `--blast_db` — formatted nucleotide BLAST DB prefix, with `taxdb.bt*` co-located
    (required for BLAST).
- **Out** (all paths relative to `<outdir>`; NosoGraph sets `outdir` to `<outdir>/<sample_id>`):
  - `quast_results/report.tsv` — native QUAST report.
  - `checkm2_results/quality_report.tsv` — native CheckM2 report (`Completeness`,
    `Contamination`).
  - `blast/<sample_id>.blast.outfmt6.tsv` — raw megablast hits (17-column outfmt 6).
  - `blast/<sample_id>.contig_identification.tsv` — normalized best-hit-per-contig table.
  - `versions/<tool>.txt` — captured tool versions, per process.
- **Self-contained:** owns its params, process resources, and conda envs (declared inline
  via `${moduleDir}`). No dependency on the parent repo's `nextflow.config` or `conda/`
  dir — the whole `assembly-qc-iden/` directory is portable.

Not in scope: knowledge-graph CSV emission and Neo4j loading — those stay NosoGraph-owned
(`report/kg_export.py`). This module produces tool outputs only.

## Usage

Standalone (the module's `nextflow.config` is auto-loaded):

```bash
nextflow run ./assembly-qc-iden \
  --sample_id CI16 --assembly contigs.fasta \
  --checkm2_db /path/to/uniref100.KO.1.dmnd \
  --blast_db   /path/to/blastdb/core_nt \
  --reads long_reads.fastq.gz --reference ref.fasta   # both optional
```

> Use `./assembly-qc-iden` (or an absolute path), **not** `assembly-qc-iden` — a bare name
> makes Nextflow try to pull it from GitHub.

### Parameters

| Param | Default | Description |
|----|----|----|
| `--sample_id` | _(required)_ | Sample name; scopes outputs and names the BLAST files. |
| `--assembly` | _(required)_ | Assembler consensus/polished FASTA. |
| `--reads` | _(none)_ | Long-read FASTQ(.gz) for QUAST read-mapping stats. |
| `--reference` | _(none)_ | Reference FASTA for QUAST reference-based stats. |
| `--tech` | `nanopore` | `nanopore` \| `pacbio` — picks the QUAST read flag. |
| `--checkm2_db` | _(required for CheckM2)_ | Path to `uniref100.KO.1.dmnd`. |
| `--blast_db` | _(required for BLAST)_ | Formatted nucleotide DB prefix (`taxdb.bt*` co-located). |
| `--blast_max_target_seqs` | `5` | `blastn -max_target_seqs`. |
| `--blast_evalue` | `1e-10` | `blastn -evalue`. |
| `--threads` | `4` | Threads per process. |
| `--quast_mem` / `--checkm2_mem` / `--blast_mem` | `8 GB` / `32 GB` / `16 GB` | Per-process memory. |
| `--outdir` | `results` | Output directory. |

### Profiles

| Profile | Effect |
|----|----|
| `micromamba` | Resolve the inline conda envs with micromamba (`conda.useMicromamba`). |
| `test` | Disable conda **and** drop all process memory requests to 1 GB, so `-stub-run` works on any node with no tools installed. |

### Output contract notes

- **Join key (critical):** the `contig` value in `contig_identification.tsv` is the FASTA
  header token up to the first whitespace, byte-identical to the input — BLAST's `qseqid`
  is truncated the same way. NosoGraph joins identification onto contig nodes by this exact
  string; any renaming/truncation/re-sorting breaks the join.
- **Empty values:** missing identification fields are the empty string `""`, never
  `NA`/`null`/`-` (NosoGraph's `LOAD CSV` guards on `<> ''`). No-hit contigs still appear,
  with empty fields.
- **Determinism:** best hit per contig is chosen by max bitscore, then min e-value, then
  lexicographically smallest accession.

### Notes

- **AVX2:** the target test server (Xeon E5-2670 v0) lacks AVX2. `conda/quast.yaml`
  (`quast=5.2.0`) and `conda/blast.yaml` (`blast=2.16.0`) have no mandatory AVX2 codepath;
  CheckM2's tensorflow stack lives in its own env (`conda/checkm2.yaml`) for the same
  isolation reason as the `bacterial-assembly` module. Pin to AVX2-safe builds if any tool
  ever SIGILLs.
- **BLAST DB:** written DB-agnostic (`--blast_db` = any formatted nucleotide DB), so you
  can validate against a small DB (e.g. SSU) while production points at core_nt.

## Test — wiring check

No tools or DBs needed; validates the channel/process graph end to end:

```bash
nextflow run ./assembly-qc-iden -profile test -stub-run \
  --sample_id CI16 --assembly dummy.fa \
  --checkm2_db dummydb --blast_db dummydb
```

Expect `QUAST`, `CHECKM2`, and `BLAST` to execute as stubs and emit the §7 filenames
(`quast_results/report.tsv`, `checkm2_results/quality_report.tsv`,
`blast/CI16.blast.outfmt6.tsv`, `blast/CI16.contig_identification.tsv`).

## Software dependencies

This pipeline uses external software managed via Conda environment files located in
`conda/*.yaml`.

A non-exhaustive list of tools includes Nextflow (Apache 2.0), QUAST, CheckM2, and
BLAST+.

All tools are distributed under their respective licenses. Please consult each tool's
documentation for license information.

---

## License

SPDX-License-Identifier: MPL-2.0

Copyright © 2026 Sara Wattanasombat

This project is licensed under the Mozilla Public License 2.0 (MPL-2.0).
A copy of the license is included in the LICENSE file, or available at https://mozilla.org/MPL/2.0/.
