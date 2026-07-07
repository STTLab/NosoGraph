# kraken2-classify module

A self-contained Nextflow module that classifies one long-read FASTQ against a
pre-built Kraken2 database and emits the standard kraken-style report. It replaces a
dependency on `epi2me-labs/wf-metagenomics` for the NosoGraph pathogen-ID pipeline,
whose KG export consumes only the Kraken2 report.

## Scope

- **In:** one long-read FASTQ(.gz) (`--long_reads`) + a pre-built Kraken2 DB
  directory (`--kraken2_db`, containing `hash.k2d` / `opts.k2d` / `taxo.k2d`).
- **Out:**
  - `<outdir>/kraken2/<sample_id>.kraken2.report.txt` — 6-column kraken report
  - `<outdir>/kraken2/<sample_id>.kraken2.output.txt` — per-read classifications
- **Steps:** a single `kraken2` classification.
- **Self-contained:** owns its params, process resources, and conda env (declared
  inline via `${moduleDir}`). No dependency on the parent repo's `nextflow.config`
  or `conda/` dir — the whole `kraken2-classify/` directory is portable.

Not in scope: Bracken abundance re-estimation, host depletion, multi-barcode sample
sheets, real-time mode (all provided by `wf-metagenomics` if you need them). Bracken
is a documented future seam in `report/meta_kg_export.py`.

## Usage

Standalone (the module's `nextflow.config` is auto-loaded):

```bash
nextflow run ./kraken2-classify \
  --sample_id CI16 --long_reads reads.fastq.gz \
  --kraken2_db /path/to/k2_standard
```

> Use `./kraken2-classify` (or an absolute path), **not** `kraken2-classify` —
> a bare name makes Nextflow try to pull it from GitHub.

From the parent repo (runs Kraken2 → KG export in one pipeline):

```bash
nextflow run main.nf --pipeline metagenomics \
  --sample_id CI16 --long_reads reads.fastq.gz \
  --kraken2_db /path/to/k2_standard
```

### Parameters

| Param | Default | Description |
|----|----|----|
| `--sample_id` | _(required)_ | Sample name; scopes outputs and names the report. |
| `--long_reads` | _(required)_ | Long-read FASTQ(.gz). gzip is auto-detected from the name. |
| `--kraken2_db` | _(required)_ | Kraken2 DB directory (`hash.k2d` etc.). |
| `--kraken2_confidence` | `0` | kraken2 `--confidence` threshold. |
| `--kraken2_mem` | `64 GB` | Memory request. Set ≈ the DB size; raise for the full Standard DB. |
| `--threads` | `4` | Threads per job. |
| `--outdir` | `results` | Output directory. |
| `--container_registry` | `ghcr.io/minaminii` | Registry for the `bioinf-*` images (`-profile singularity`). |
| `--container_tag` | `latest` | Image tag; use a git SHA or `@sha256:<digest>` for a locked release. |
| `--singularity_binds` | _(derived)_ | Extra `singularity` bind flags. Defaults to `-B <parent of --kraken2_db>`; override e.g. `-B /db/root` when the DB dir holds outside-pointing symlinks. |

### Profiles

| Profile | Effect |
|----|----|
| `micromamba` | Resolve the inline conda env with micromamba (`conda.useMicromamba`). |
| `singularity` | Run the frozen `bioinf-kraken2` container image instead of solving conda (disables conda; enables Singularity with `autoMounts` + `--singularity_binds`). |
| `test` | Disable conda **and** drop the `kraken2` memory request to 1 GB, so `-stub-run` works on any node with no tools installed. |

### Notes

- **Reproducible distribution = the container image.** `-profile singularity` runs the frozen
  `bioinf-kraken2` image (the conda solve happens once at build time and is frozen in the
  layers). Conda (`-profile micromamba`) re-solves the loose yaml against rolling channels and
  is the best-effort fallback for hosts without Singularity. Build/publish/pin instructions
  live in [`containers/README.md`](../../../containers/README.md).
- **Memory:** Kraken2 loads the DB hash into RAM. The full Standard DB needs tens of
  GB; size `--kraken2_mem` to your DB (or use a capped `*-8` DB on small nodes).
- **AVX2:** `conda/kraken2.yaml` pins `kraken2=2.1.3`, which has no AVX2 requirement and
  runs on the older Xeon E5-2670 v0 test server. Adjust only if a build ever SIGILLs.

## Test — wiring check

No tools needed; validates the channel/process graph end to end:

```bash
nextflow run ./kraken2-classify -profile test -stub-run \
  --sample_id CI16 --long_reads dummy.fq.gz --kraken2_db dummydb
```

Expect `KRAKEN2` to execute as a stub and emit `CI16.kraken2.report.txt`.

## Software dependencies

This pipeline ships each environment as a frozen Singularity/GHCR image (the reproducible
artifact; see [`containers/README.md`](../../../containers/README.md)) and, as a loose
fallback, the Conda environment files in `conda/*.yaml`.

A non-exhaustive list of tools includes Nextflow (Apache 2.0) and Kraken2.

All tools are distributed under their respective licenses. Please consult each tool’s documentation for license information.

---

## License

SPDX-License-Identifier: MPL-2.0

Copyright © 2026 Sara Wattanasombat

This project is licensed under the Mozilla Public License 2.0 (MPL-2.0).
A copy of the license is included in the LICENSE file, or available at https://mozilla.org/MPL/2.0/.
