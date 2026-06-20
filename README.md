# bacterial-assembly module

A self-contained Nextflow module for the classic bacterial assembly →
polish → QC path: a single long-read assembler, optional long-read (Racon)
and short-read (Pilon) polishing, and a CheckM2 completeness/contamination
report.

## Scope

- **In:** one long-read FASTQ(.gz) (`--long_reads`); optionally a paired
  short-read set (`--read1` / `--read2`) for Pilon polishing.
- **Out:**
  - `<outdir>/01_assembly/assembly.contigs.fasta`
  - `<outdir>/02_polish/01_racon/racon_final.fa` (if `--racon_iter > 0`)
  - `<outdir>/02_polish/02_pilon/pilon_final.fasta` (if `--pilon_iter > 0`)
  - `<outdir>/checkm2_results/` (when Pilon runs)
- **Steps:** assemble (`canu` | `flye`) → Racon polish (× `racon_iter`) →
  Pilon polish (× `pilon_iter`) → CheckM2.
- **Self-contained:** owns its params, process resources, and conda env (declared
  inline via `${moduleDir}`). No dependency on the parent repo's `nextflow.config`
  or `conda/` dir — the whole `modules/bacterial-assembly/` directory is portable.

Not in scope: multi-assembler consensus (see the `autocycler` module).

## Usage

Standalone (the module's `nextflow.config` is auto-loaded):

```bash
nextflow run ./bacterial-assembly \
  --long_reads reads.fastq.gz --assembler flye --tech nanopore \
  --read1 r1.fastq.gz --read2 r2.fastq.gz --checkm2_db uniref100.KO.1.dmnd
```

> Use `./bacterial-assembly` (or an absolute path), **not** `bacterial-assembly` —
> a bare name makes Nextflow try to pull it from GitHub.

From the parent repo:

```bash
nextflow run main.nf --pipeline assembly_polish_qc \
  --long_reads reads.fastq.gz --assembler flye --tech nanopore \
  --read1 r1.fastq.gz --read2 r2.fastq.gz --checkm2_db uniref100.KO.1.dmnd
```

### Parameters

| Param | Default | Description |
|----|----|----|
| `--long_reads` | _(required)_ | Long-read FASTQ(.gz). |
| `--assembler` | `flye` | `canu` or `flye`. |
| `--tech` | _(required)_ | `nanopore`, `nanopore-hq`, or `pacbio`. |
| `--genome_size` | `null` | e.g. `5m`, `2.6g`. Required for `canu`; optional for `flye`. |
| `--racon_iter` | `1` | Long-read polish iterations. `0` skips Racon. |
| `--pilon_iter` | `1` | Short-read polish iterations. `0` skips Pilon + CheckM2. |
| `--read1` / `--read2` | `null` | Paired short reads. Required when `pilon_iter > 0`. |
| `--checkm2_db` | `null` | Path to `uniref100.KO.1.dmnd`. Required when CheckM2 runs. |
| `--threads` | `4` | Threads per job. |
| `--outdir` | `results` | Output directory. |

### Profiles

| Profile | Effect |
|----|----|
| `micromamba` | Resolve the inline conda env with micromamba (`conda.useMicromamba`). |
| `test` | Disable conda so `-stub-run` works with no tools installed. |

### Notes

- **AVX2:** the conda env pins `racon`, `flye`, and `python` to builds that run on
  CPUs without AVX2 (see `conda/bacterial-assembly.yaml`). Relax on modern hardware.

## Test — wiring check

No tools needed; validates the channel/process graph end to end:

```bash
nextflow run ./bacterial-assembly -profile test -stub-run \
  --long_reads dummy.fq --assembler flye --tech nanopore \
  --read1 r1.fq.gz --read2 r2.fq.gz --checkm2_db dummy.dmnd
```

Expect FLYE → RACON → PILON → CHECKM2 to execute as stubs. Swap `--assembler canu`
or set `--pilon_iter 0` to exercise the other paths.
