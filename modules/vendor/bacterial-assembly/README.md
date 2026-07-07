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
| `--container_registry` | `ghcr.io/minaminii` | Registry for the `bioinf-*` images (`-profile singularity`). |
| `--container_tag` | `latest` | Image tag; use a git SHA or `@sha256:<digest>` for a locked release. |
| `--singularity_binds` | _(derived)_ | Extra `singularity` bind flags. Defaults to `-B <parent of --checkm2_db>`; override e.g. `-B /db/root`. |

### Profiles

| Profile | Effect |
|----|----|
| `micromamba` | Resolve the inline conda env with micromamba (`conda.useMicromamba`). |
| `singularity` | Run the frozen `bioinf-*` container images instead of solving conda (disables conda; enables Singularity with `autoMounts` + `--singularity_binds`). |
| `test` | Disable conda so `-stub-run` works with no tools installed. |

### Notes

- **Reproducible distribution = the container images.** `-profile singularity` runs the
  frozen `bioinf-bacterial-assembly` / `bioinf-checkm2` images (the conda solve happens once
  at build time and is frozen in the layers). Conda (`-profile micromamba`) re-solves the
  loose yamls against rolling channels and is the best-effort fallback for hosts without
  Singularity. Build/publish/pin instructions live in [`containers/README.md`](../../../containers/README.md).
- **Conda envs:** assembly + polishing share `conda/bacterial-assembly.yaml`; CheckM2
  uses `conda/qc.yaml`. They are split because CheckM2's stack (newer python + tensorflow
  + zlib) cannot co-solve with the AVX2-safe assembler pins. `conda/qc.yaml` pins `numpy <2`
  (tensorflow 2.17's C-extensions crash on numpy ≥2.1) — keep it in sync with
  `assembly-qc-iden/conda/checkm2.yaml`, the shared build source for `bioinf-checkm2`.
- **AVX2:** `conda/bacterial-assembly.yaml` pins `flye=2.9.5`, `racon=1.4.20`, and
  `python=3.9` to builds that run on CPUs without AVX2 (newer builds SIGILL on e.g. the
  Xeon E5-2670 v0). AVX2 safety is set by the tool *version*, so images built from these
  loose specs are AVX2-safe too. Relax on AVX2-capable hardware.

## Test — wiring check

No tools needed; validates the channel/process graph end to end:

```bash
nextflow run ./bacterial-assembly -profile test -stub-run \
  --long_reads dummy.fq --assembler flye --tech nanopore \
  --read1 r1.fq.gz --read2 r2.fq.gz --checkm2_db dummy.dmnd
```

Expect FLYE → RACON → PILON → CHECKM2 to execute as stubs. Swap `--assembler canu`
or set `--pilon_iter 0` to exercise the other paths.

## Software dependencies

This pipeline ships each environment as a frozen Singularity/GHCR image (the reproducible
artifact; see [`containers/README.md`](../../../containers/README.md)) and, as a loose
fallback, the Conda environment files in `conda/*.yaml`.

A non-exhaustive list of tools includes Nextflow (Apache 2.0) and other bioinformatics tools defined in the Conda environment specifications.

All tools are distributed under their respective licenses. Please consult each tool’s documentation for license information.

---

## License

SPDX-License-Identifier: MPL-2.0

Copyright © 2026 Sara Wattanasombat

This project is licensed under the Mozilla Public License 2.0 (MPL-2.0).
A copy of the license is included in the LICENSE file, or available at https://mozilla.org/MPL/2.0/.
