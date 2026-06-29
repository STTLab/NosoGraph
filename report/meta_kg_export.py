#!/usr/bin/env python3
# SPDX-License-Identifier: MPL-2.0
"""NosoGraph metagenomics knowledge-graph CSV exporter.

Reads one sample's Kraken2 report (produced by the vendored ``kraken2-classify``
module) and writes flat CSVs for manual bulk import into Neo4j via the LOAD DATA templates in
``assets/nosograph_cypher_templates.csv``. The node labels, property names and
relationship types match the migrated ``nosograph`` graph schema; the
taxonomic-classification subgraph is a public NosoGraph extension built on the generic
``ProcessRun`` pattern (mirrors ``VariantCallingRun:ProcessRun``, keyed on
``process_run_id``).

Target subgraph:

  (Sample)-[:CLASSIFIED_IN]->(:ProcessRun:TaxonomicClassification)
          -[:CLASSIFIED_FROM]->(:BioDataFile{FASTQ})
  (:TaxonomicClassification)-[:IDENTIFIED {read_count, abundance, rank}]->(:Organism{taxid})

Emitted (under ``<outdir>/kg/``):

  taxonomic_classification.csv  — TaxonomicClassification ProcessRun (linked to Sample)
  meta_reads.csv                — BioDataFile node (input FASTQ; CLASSIFIED_FROM)
  taxa.csv                      — Organism nodes + IDENTIFIED edges (read_count/abundance/rank)

Only species (rank ``S``) and genus (rank ``G``) rows are kept, reusing the existing
``Organism {taxid, sciname}`` vocabulary. Per STTLab conventions: ``taxid`` is a STRING
(matches ``Organisms.csv``); booleans are lowercase ``true``/``false``; empty values are
``""``. Abundance is the Kraken2 clade fraction (clade reads / classified reads).

Seam: Bracken refinement is intentionally not wired in. To add it, run Bracken on the
Kraken2 report to produce a kraken-style ``<sid>.bracken.report`` (same 6-col format
handled by ``_read_kraken2``) and override per-taxon read counts/abundance before
writing ``taxa.csv``, setting ``--tool kraken2+bracken``.
"""
import argparse
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd

# Standard Kraken2 report: 6 tab-separated columns, no header.
KRAKEN2_COLS = ["pct", "clade_reads", "taxon_reads", "rank_code", "taxid", "name"]
# Reuse the existing Organism vocabulary at species + genus only.
KEEP_RANKS = {"S", "G"}


def _write_csv(path: Path, fieldnames, rows) -> None:
    pd.DataFrame(rows, columns=fieldnames).to_csv(path, index=False)


def _read_kraken2(report: Path) -> pd.DataFrame:
    df = pd.read_csv(
        report, sep="\t", header=None, names=KRAKEN2_COLS, dtype={"taxid": str}
    )
    # Names are indented by depth in the lineage; rank codes can carry trailing spaces.
    df["rank_code"] = df["rank_code"].astype(str).str.strip()
    df["name"] = df["name"].astype(str).str.strip()
    return df


def _clade_reads(df: pd.DataFrame, rank_code: str) -> int:
    """Clade-read count of the first row with this exact rank code, or 0."""
    sub = df[df["rank_code"] == rank_code]
    return int(sub["clade_reads"].iloc[0]) if not sub.empty else 0


def export(kg_dir, sample_id, kraken2_report, reads, tool):
    process_run_id = f"{sample_id}_taxclass"
    created_at = datetime.now(timezone.utc).date().isoformat()

    df = _read_kraken2(kraken2_report)
    classified = _clade_reads(df, "R")    # root clade = all classified reads
    unclassified = _clade_reads(df, "U")

    # --- TaxonomicClassification run + reads link ---
    reads_path = Path(reads).resolve() if reads else None
    fastq_uri = str(reads_path) if reads_path else ""

    _write_csv(
        kg_dir / "taxonomic_classification.csv",
        ["process_run_id", "sample_id", "tool", "created_at",
         "classified_reads", "unclassified_reads", "fastq_uri"],
        [{
            "process_run_id":     process_run_id,
            "sample_id":          sample_id,
            "tool":               tool,
            "created_at":         created_at,
            "classified_reads":   classified,
            "unclassified_reads": unclassified,
            "fastq_uri":          fastq_uri,
        }],
    )

    meta_rows = []
    if reads_path is not None:  # FASTQ can be tens of GB; SHA-256 skipped (see kg_export.py).
        meta_rows.append({
            "uri":            fastq_uri,
            "file_type":      "FASTQ",
            "compressed":     "true" if reads_path.suffix in (".gz", ".bz2") else "false",
            "sha256":         "",
            "sample_id":      sample_id,
            "process_run_id": process_run_id,
        })
    _write_csv(
        kg_dir / "meta_reads.csv",
        ["uri", "file_type", "compressed", "sha256", "sample_id", "process_run_id"],
        meta_rows,
    )

    # --- Identified taxa (species + genus) ---
    taxa_rows = []
    for _, r in df[df["rank_code"].isin(KEEP_RANKS)].iterrows():
        clade = int(r["clade_reads"])
        taxa_rows.append({
            "process_run_id": process_run_id,
            "taxid":          str(r["taxid"]),
            "sciname":        r["name"],
            "rank":           r["rank_code"],
            "read_count":     clade,
            "abundance":      round(clade / classified, 6) if classified else 0,
        })
    _write_csv(
        kg_dir / "taxa.csv",
        ["process_run_id", "taxid", "sciname", "rank", "read_count", "abundance"],
        taxa_rows,
    )


def main():
    p = argparse.ArgumentParser(
        description="Export NosoGraph per-sample metagenomics outputs to Neo4j CSVs"
    )
    p.add_argument("--sample", required=True, help="Sample ID")
    p.add_argument("--kraken2-report", required=True, help="Kraken2 report (.kraken2.report.txt)")
    p.add_argument("--reads", default="", help="Input FASTQ used for classification (optional)")
    p.add_argument("--tool", default="kraken2", help="Classifier tool label (default: kraken2)")
    p.add_argument("--outdir", default=".", help="Output dir; CSVs are written to <outdir>/kg/")
    args = p.parse_args()

    kg_dir = Path(args.outdir) / "kg"
    kg_dir.mkdir(parents=True, exist_ok=True)

    export(
        kg_dir,
        args.sample,
        Path(args.kraken2_report),
        args.reads or None,
        args.tool,
    )

    written = sorted(p.name for p in kg_dir.glob("*.csv"))
    print(f"[meta_kg_export] {args.sample}: {len(written)} CSV(s) -> {kg_dir}")
    for name in written:
        print(f"  {name}")


if __name__ == "__main__":
    main()
