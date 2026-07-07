# Autocycler module

A self-contained Nextflow plugin that runs [Autocycler](https://github.com/rrwick/Autocycler)'s
[fully automated assembly](https://github.com/rrwick/Autocycler/wiki/Fully-automated-assembly):
it assembles a long-read set with multiple assemblers across several read subsamples and
reconciles them into a single consensus assembly.

## Scope

- **In:** one long-read FASTQ(.gz) (`--long_reads`).
- **Out:** `<outdir>/01_assembly/consensus_assembly.fasta` (+ `.gfa`).
- **Steps:** estimate genome size (optional) → subsample → assemble every
  `(assembler × subsample)` in parallel → compress → cluster → trim/resolve each cluster →
  combine.
- **Self-contained:** owns its params, process resources, and conda env (declared inline via
  `${moduleDir}`). No dependency on the parent repo's `nextflow.config` or `conda/` dir — the
  whole `modules/autocycler/` directory is portable.

Not in scope: short-read polishing / QC (those live in the parent pipeline), and the manual
curation steps from Autocycler's wiki (this is the *automated* path).

## Usage

Standalone (the module's `nextflow.config` is auto-loaded):

```bash
nextflow run ./autocycler --long_reads reads.fastq.gz [--genome_size 242000]
```

> Use `./autocycler` (or an absolute path), **not** `autocycler` — a bare name makes Nextflow
> try to pull `nextflow-io/autocycler` from GitHub.

From the parent repo:

```bash
nextflow run main.nf --pipeline autocycler --long_reads reads.fastq.gz
```

### Parameters

| Param | Default | Description |
|----|----|----|
| `--long_reads` | _(required)_ | Long-read FASTQ(.gz). |
| `--genome_size` | `null` | e.g. `5m`, `242000`. If unset, estimated with `autocycler helper genome_size`. |
| `--assemblers` | `flye,miniasm,raven` | Comma-separated. Each must be installed in the conda env. |
| `--subsample_count` | `4` | Number of read subsamples. |
| `--threads` | `4` | Threads per assembly job. |
| `--outdir` | `results` | Output directory. |
| `--container_registry` | `ghcr.io/minaminii` | Registry for the `bioinf-*` images (`-profile singularity`). |
| `--container_tag` | `latest` | Image tag; use a git SHA or `@sha256:<digest>` for a locked release. |
| `--singularity_binds` | _(empty)_ | Extra `singularity` bind flags. Not needed here (no external DB — `autoMounts` covers the work dir + staged reads); set only for unusual layouts. |

### Profiles

| Profile | Effect |
|----|----|
| `micromamba` | Resolve the inline conda env with micromamba (`conda.useMicromamba`). |
| `singularity` | Run the frozen `bioinf-autocycler` container image instead of solving conda (disables conda; enables Singularity with `autoMounts`). |
| `test` | Disable conda so `-stub-run` works with no tools installed. |

### Notes

- **Incremental reuse:** with `-resume` (and an intact `work/`), each `(assembler, subsample)`
  assembly is cached individually, so changing `--assemblers` reuses prior assemblies and only
  recomputes the cheaper compress→combine steps. Reuse breaks if `work/` is cleaned (the
  subsample step is stochastic) or the conda env changes.
- **AVX2:** the conda env pins `racon`, `flye`, and `python` to builds that run on CPUs
  without AVX2 (see `conda/autocycler.yaml`). Relax on modern hardware.
- **Reproducible distribution = the container image.** `-profile singularity` runs the frozen
  `bioinf-autocycler` image (the conda solve happens once at build time and is frozen in the
  layers). Conda (`-profile micromamba`) re-solves the loose yaml against rolling channels and
  is the best-effort fallback for hosts without Singularity. Build/publish/pin instructions
  live in [`containers/README.md`](../../../containers/README.md).
- **`$TMPDIR` under Singularity:** the assembly steps force `TMPDIR=/tmp` inside the container.
  `autocycler helper` and flye's `multiprocessing` build scratch there, and flye's AF_UNIX
  socket path (~108-char cap) overflows if `$TMPDIR` is the long Nextflow work dir; `/tmp` is
  short and Singularity-writable.

## Test — Autocycler demo dataset

A small ONT dataset (~75 Mbp reads, 242 kb genome) from the Autocycler authors.

```bash
# 1. Fetch + unpack the demo reads
curl -L -o autocycler-demo-dataset.tar \
  https://github.com/rrwick/Autocycler/releases/download/v0.1.0/autocycler-demo-dataset.tar
tar -xf autocycler-demo-dataset.tar           # -> reads.fastq.gz, truth.fasta

# 2. Wiring check first (no tools needed)
nextflow run ./autocycler -profile test -stub-run \
  --long_reads reads.fastq.gz --genome_size 242000

# 3. Real run (uses the default flye,miniasm,raven)
nextflow run ./autocycler -profile micromamba \
  --long_reads reads.fastq.gz --genome_size 242000 --threads 16
```

Expected: `results/01_assembly/consensus_assembly.fasta` — a ~242 kb assembly you can compare
against `truth.fasta`.

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

