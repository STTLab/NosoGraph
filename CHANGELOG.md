<!-- SPDX-License-Identifier: MPL-2.0 -->
# Changelog

All notable changes to NosoGraph are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/). Prereleases
carry a suffix: `-demo.N` for demo builds, `-rc.N` for release candidates.

## [0.3.0-rc.1] - 2026-08-15

Minor bump from `0.2.1-demo.1`, first release candidate of the 0.3 line. The
`--pipeline` selector `metagenomics` is **renamed** to `kraken2-classify`,
aligning the user-facing choice with the vendored module (`KRAKEN2_CLASSIFY`,
`modules/vendor/kraken2-classify/`) that has always backed it.

> **Breaking CLI change.** `--pipeline metagenomics` no longer runs — it now
> errors with *"Unknown --pipeline 'metagenomics'. Use: bacterial-assembly,
> autocycler, kraken2-classify"*. Update any scripts, scheduler jobs, or
> saved commands to `--pipeline kraken2-classify`. No alias is kept.

### Changed
- **`--pipeline metagenomics` renamed to `--pipeline kraken2-classify`** across
  the workflow (`main.nf`, `nextflow.config`) and documentation (`README.md`,
  wiki Pipeline/Knowledge-graph tutorials). The pipeline's behaviour, outputs,
  and KG schema are unchanged; only the selector token changed. Domain terms —
  the KG "metagenomics public extension", the `TaxonomicClassification` node
  label, and the historical `wf-metagenomics` references — are left as-is.

### Fixed
- **Cypher load templates updated for Neo4j 2025 / Desktop 2**
  (`assets/nosograph_cypher_templates.csv`). Every LOAD DATA query now uses the
  variable-scope `CALL (rec) { … }` subquery form — the scope-less
  `CALL { WITH rec … }` is deprecated — and drops the obsolete `:auto`
  implicit-transaction prefix, which errors in Neo4j Desktop 2. Load behaviour
  is unchanged; `… IN TRANSACTIONS OF N ROWS` still batches as before.

## [0.2.1-demo.1] - 2026-07-14

Patch bump from `0.2.0-demo.1`: a refresh of the vendored modules, plus the
call-site fix that the refresh turned out to require.

> **Behaviour change on the default invocation.** A long-read-only run (no
> `--read1`/`--read2`) previously failed with *"Pilon polishing (pilon_iter > 0)
> requires --read1 and --read2"*, because `pilon_iter` defaults to `1`. It now
> succeeds: the short-read polish is skipped and CheckM2 still runs, so these
> runs gain a `checkm2` QC result — and a populated `Assembly` QC block in the
> exported knowledge graph — where they previously produced nothing at all.

### Fixed
- **`main.nf` failed to compile against the refreshed `bacterial-assembly`.**
  The module's `BACTERIAL_ASSEMBLY` workflow gained a fourth input,
  `pilon_iter`, but `main.nf` still called it with three arguments. Because
  `main.nf` is a single script, the compile error aborted **every** pipeline,
  not just `bacterial-assembly` — `autocycler` and `metagenomics` were equally
  unrunnable. ([#17](https://github.com/STTLab/NosoGraph/pull/17))

### Changed
- **Long-read-only assembly is now a first-class mode.** `main.nf` mirrors the
  vendored `AUTO_BACTERIAL_ASSEMBLY` wrapper: with no short reads supplied it
  drops the Pilon polish and logs the decision, rather than erroring out.
- **CheckM2 always runs**, on whichever assembly comes out last, instead of only
  when Pilon ran. The `NO_CHECKM2` sentinel is retained as a guard but is no
  longer reached on the `bacterial-assembly` path.
- **Vendored modules refreshed** — `autocycler` (`48ef4ee`),
  `bacterial-assembly` (`0dc6c70`), `kraken2-classify` (`3d43a35`) and
  `assembly-qc-iden` (`3703061`). The `assembly-qc-iden` BLAST step moved from a
  `shell:` block to a `script:` block with escaped bash/awk fields; behaviour is
  unchanged.

## [0.2.0-demo.1] - 2026-07-09

Minor bump from `0.1.1-demo.1`. The headline change is a new default runtime:
the pipeline now executes in **containers** rather than conda. This changes the
behaviour of the default invocation, hence the minor bump on the `0.x` line.

> **Compatibility — minimum Nextflow raised.** The local KG exporter modules now
> use Nextflow **static typing** (`nextflow.enable.types`), a **preview feature**.
> Older Nextflow releases will fail to parse `modules/local/*.nf`, so this release
> requires **Nextflow ≥ 26.04.4** (the version it is verified against; being a
> preview, syntax/behaviour may still change in future Nextflow releases).

### Added
- **Version manifest.** NosoGraph now declares its own `manifest.version` in
  `nextflow.config` (previously only the vendored modules carried a version).
  Placed after the vendored `includeConfig` lines so a module's re-asserted
  `manifest{}` cannot clobber it.
- **Container-based execution as the default engine** (singularity), selectable
  via profiles; conda becomes opt-in (`-profile micromamba`), `none` for stubs.
- **Clinical CSV templates and expanded Cypher load templates** for the
  knowledge-graph import step.
- **Vendor-bump CI workflow** (`.github/workflows/bump-vendored-modules.yml`) to
  pull vendored Nextflow modules from the upstream monorepo via git subtree,
  with auto-resolution of conflicts in favour of upstream.
- **Demo-kit** (`example/demo-kit/`, release branch only): de-identified clinical
  + genomics CSVs with SNOMED/CBC/variant layers and demo Cypher templates.

### Changed
- **KG exporters (`KG_EXPORT` / `META_KG_EXPORT`) run on host Python** (pandas)
  instead of a conda environment; only the vendored bioinformatics tools are
  containerised.
- **KG exporter modules migrated to typed-DSL process I/O** — `nextflow.enable.types`
  with typed `: Path` inputs and `files()` outputs (`files()`, not `file()`, since
  the `kg/*.csv` output glob yields multiple files). Vendored modules are left
  untyped (owned upstream). See the compatibility note above re: minimum Nextflow.
- Vendored modules bumped from upstream (assembly-qc-iden, autocycler,
  bacterial-assembly, kraken2-classify); kraken2-classify conda pin updated.

### Fixed
- `pilon` polish step corrected in the bacterial-assembly module.
- Micromamba usage enabled in the standard profile.
- Vendor-fetch CI auth now uses a token-in-URL instead of the persisted
  `GITHUB_TOKEN`, so fetches from the separate private vendor repo no longer 404.

### Removed
- Stale root conda environment files and `docker-compose.yml`.

> **Note on the release branch.** `main` is the mainline and does **not** carry
> the demo-kit; the tagged `v0.2.0-demo.1` release lives on the `v0.2.x-demo.1`
> branch, which is `main` plus `example/demo-kit/`.

## [0.1.1-demo.1] - 2026-07-03

Demo prerelease. Metagenomics switched to the vendored `kraken2-classify`
module (single-step, in-pipeline Kraken2 classification); the epi2me-labs
`wf-metagenomics` git submodule was removed.

### Why `wf-metagenomics` was dropped

Beyond the functional simplification (two external steps + a `--meta_results`
hand-off collapsed into one in-pipeline module), `wf-metagenomics` imposed a
**constrained, incompatible toolchain** on the whole project: it ran only under
a **pinned Nextflow (v24.x)** and required **Java 17–20** — it would not run on
**Java 21+**, whose newer runtime broke the Groovy that Nextflow/the pipeline's
DSL relied on. Bringing NosoGraph up on a current JDK meant downgrading Java
back into the 17–20 window and holding Nextflow at v24 just to keep
`wf-metagenomics` working.

Replacing it with a lightweight, single-step `kraken2-classify` module (in the
same conda/container-first style as the other modules) removed that Java/Nextflow
version lock, freeing NosoGraph to track a current toolchain. The KG exporter is
unchanged — it still consumes a standard 6-column Kraken2 report.

## [0.1.0-demo.1] - 2026-07-02

Initial demo prerelease.

[0.3.0-rc.1]: https://github.com/STTLab/NosoGraph/releases/tag/v0.3.0-rc.1
[0.2.1-demo.1]: https://github.com/STTLab/NosoGraph/releases/tag/v0.2.1-demo.1
[0.2.0-demo.1]: https://github.com/STTLab/NosoGraph/releases/tag/v0.2.0-demo.1
[0.1.1-demo.1]: https://github.com/STTLab/NosoGraph/releases/tag/v0.1.1-demo.1
[0.1.0-demo.1]: https://github.com/STTLab/NosoGraph/releases/tag/v0.1.0-demo.1
