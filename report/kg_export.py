#!/usr/bin/env python3
# SPDX-License-Identifier: MPL-2.0
"""NosoGraph knowledge-graph CSV exporter.

Reads one sample's bacterial-assembly pipeline outputs and writes flat CSVs for
manual bulk import into Neo4j via the LOAD DATA templates in
``assets/nosograph_cypher_templates.csv``. The node labels, property names and
relationship types match the migrated ``nosograph`` graph schema exactly, so the
manual load produces the same structure as the private ``nosograph`` library's ingest.

Emitted (under ``<outdir>/kg/``):

  sample.csv          — Sample node
  assembly.csv        — Assembly node (linked to Sample; CheckM2 completeness/contamination)
  biodata_files.csv   — BioDataFile nodes (input FASTQ + consensus FASTA)
  contigs.csv         — Contig nodes (FASTA joined with Flye assembly_info.txt)

Contig IDs are namespaced ``{sample_id}:{contig_name}`` so they are globally unique
across samples (Flye restarts numbering from contig_1 every run). Per STTLab
conventions: booleans are lowercase ``true``/``false``; empty values are ``""``;
file identity uses SHA-256; the Contig sequence hash uses md5 (matching the lib).
"""
import argparse
import csv
import hashlib
from datetime import datetime, timezone
from pathlib import Path

from ContextBuilder.assembly_info import parse_assembly


def _sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest()


def _write_csv(path: Path, fieldnames, rows) -> None:
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        w.writeheader()
        w.writerows(rows)


def _bool_str(v) -> str:
    """Normalise an optional Python bool to the lowercase string the schema expects."""
    if v is None:
        return ""
    return "true" if v else "false"


def _blank(v) -> str:
    return "" if v is None else str(v)


def export_sample(kg_dir: Path, sample_id: str) -> None:
    _write_csv(kg_dir / "sample.csv", ["sample_id"], [{"sample_id": sample_id}])


def _read_checkm2(checkm2_path: Path | None):
    """Return (completeness, contamination) from a CheckM2 quality_report.tsv, or ('', '')."""
    if checkm2_path is None:
        return "", ""
    tsv = checkm2_path
    if tsv.is_dir():
        tsv = tsv / "quality_report.tsv"
    if not tsv.exists():
        return "", ""
    with open(tsv, encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f, delimiter="\t"):
            return row.get("Completeness", ""), row.get("Contamination", "")
    return "", ""


def export_assembly_and_contigs(kg_dir, sample_id, assembler, fasta, flye_info, checkm2):
    assembly_id = f"{sample_id}_assembly"
    created_at = datetime.now(timezone.utc).date().isoformat()
    completeness, contamination = _read_checkm2(checkm2)

    _write_csv(
        kg_dir / "assembly.csv",
        ["assembly_id", "sample_id", "assembler", "created_at", "completeness", "contamination"],
        [{
            "assembly_id": assembly_id,
            "sample_id": sample_id,
            "assembler": assembler,
            "created_at": created_at,
            "completeness": completeness,
            "contamination": contamination,
        }],
    )

    flye_info_path = str(flye_info) if flye_info and Path(flye_info).exists() else None
    contig_rows = []
    for rec in parse_assembly(str(fasta), flye_info_path):
        name = rec["name"]
        contig_rows.append({
            "contig_id":          f"{sample_id}:{name}",
            "assembly_id":        assembly_id,
            "name":               name,
            "accession":          "",  # de novo assembly — no external accession
            "length":             _blank(rec["length"]),
            "coverage":           _blank(rec["coverage"]),
            "is_circular":        _bool_str(rec["is_circular"]),
            "is_repeated_region": _bool_str(rec["is_repeated_region"]),
            "multiplicity":       _blank(rec["multiplicity"]),
            "alt_group":          _blank(rec["alt_group"]),
            "graph_path":         _blank(rec["graph_path"]),
            "sequence_hash":      rec["sequence_hash"],
            "hash_algorithm":     rec["hash_algorithm"],
        })

    _write_csv(
        kg_dir / "contigs.csv",
        ["contig_id", "assembly_id", "name", "accession", "length", "coverage",
         "is_circular", "is_repeated_region", "multiplicity", "alt_group",
         "graph_path", "sequence_hash", "hash_algorithm"],
        contig_rows,
    )
    return assembly_id


def export_biodata_files(kg_dir, sample_id, assembly_id, fastq, fasta):
    fastq = Path(fastq)
    fasta = Path(fasta)
    rows = [
        {  # input reads — ASSEMBLED_FROM. SHA-256 skipped: FASTQ can be tens of GB.
            "uri":         str(fastq.resolve()),
            "file_type":   "FASTQ",
            "compressed":  "true" if fastq.suffix in (".gz", ".bz2") else "false",
            "sha256":      "",
            "assembly_id": "",
            "sample_id":   sample_id,
        },
        {  # consensus assembly — PRODUCE
            "uri":         str(fasta.resolve()),
            "file_type":   "FASTA",
            "compressed":  "true" if fasta.suffix in (".gz", ".bz2") else "false",
            "sha256":      _sha256(fasta),
            "assembly_id": assembly_id,
            "sample_id":   sample_id,
        },
    ]
    _write_csv(
        kg_dir / "biodata_files.csv",
        ["uri", "file_type", "compressed", "sha256", "assembly_id", "sample_id"],
        rows,
    )


def main():
    p = argparse.ArgumentParser(description="Export NosoGraph per-sample outputs to Neo4j CSVs")
    p.add_argument("--sample", required=True, help="Sample ID")
    p.add_argument("--assembler", required=True, help="Assembler used (flye | canu | autocycler)")
    p.add_argument("--fasta", required=True, help="Final consensus/polished assembly FASTA")
    p.add_argument("--fastq", required=True, help="Input long-read FASTQ")
    p.add_argument("--flye-info", default="", help="Flye assembly_info.txt (optional)")
    p.add_argument("--checkm2", default="", help="CheckM2 results dir or quality_report.tsv (optional)")
    p.add_argument("--outdir", default=".", help="Output dir; CSVs are written to <outdir>/kg/")
    args = p.parse_args()

    kg_dir = Path(args.outdir) / "kg"
    kg_dir.mkdir(parents=True, exist_ok=True)

    flye_info = args.flye_info or None
    checkm2 = Path(args.checkm2) if args.checkm2 else None

    export_sample(kg_dir, args.sample)
    assembly_id = export_assembly_and_contigs(
        kg_dir, args.sample, args.assembler, args.fasta, flye_info, checkm2
    )
    export_biodata_files(kg_dir, args.sample, assembly_id, args.fastq, args.fasta)

    written = sorted(p.name for p in kg_dir.glob("*.csv"))
    print(f"[kg_export] {args.sample}: {len(written)} CSV(s) -> {kg_dir}")
    for name in written:
        print(f"  {name}")


if __name__ == "__main__":
    main()
