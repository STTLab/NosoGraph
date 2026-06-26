# SPDX-License-Identifier: MPL-2.0
"""Parsers for Flye assembly output.

Ported from the canonical ``nosograph`` library (``nosograph/utils/assembly.py``)
so that the Contig records this public pipeline emits match what the private interface
library produces (same md5 hashing, same Flye metadata fields). Pure stdlib — no
biopython. Reads a Flye (or polished) consensus FASTA together
with Flye's ``assembly_info.txt`` and flattens them into Contig records carrying the
sequence's md5 hash plus Flye's per-contig metadata (coverage, circularity,
multiplicity, graph path).

When ``assembly_info.txt`` is absent (e.g. a Canu or Autocycler assembly that has no
equivalent), Flye-specific fields are left as ``None`` and the contig is still emitted
from the FASTA alone (id, length, sequence hash).
"""
from __future__ import annotations

import csv
import gzip
import hashlib


def _open_text(path: str):
    """Open a (possibly gzipped) text file for reading."""
    if path.endswith(".gz"):
        return gzip.open(path, "rt", encoding="utf-8")
    return open(path, encoding="utf-8")


def hash_sequence(sequence: str, algorithm: str = "md5") -> str:
    """Return the hex digest of a nucleotide sequence (default md5, matching the lib)."""
    return hashlib.new(algorithm, sequence.encode()).hexdigest()


def read_fasta(fasta_path: str) -> list[tuple[str, str]]:
    """Return ``[(contig_name, sequence), ...]`` from a FASTA (gzip-aware).

    Pure stdlib (no biopython). The contig name is the first whitespace-delimited
    token of the header line, matching ``Bio.SeqRecord.id`` used by the canonical lib.
    """
    records: list[tuple[str, str]] = []
    name: str | None = None
    seq: list[str] = []
    with _open_text(fasta_path) as fh:
        for line in fh:
            line = line.rstrip("\n")
            if line.startswith(">"):
                if name is not None:
                    records.append((name, "".join(seq)))
                name = line[1:].split()[0] if len(line) > 1 else ""
                seq = []
            elif line:
                seq.append(line.strip())
    if name is not None:
        records.append((name, "".join(seq)))
    return records


def _to_float(val: str | None) -> float | None:
    try:
        return float(val) if val not in (None, "", "*") else None
    except ValueError:
        return None


def _to_int(val: str | None) -> int | None:
    try:
        return int(val) if val not in (None, "", "*") else None
    except ValueError:
        return None


def _clean(val: str | None) -> str | None:
    """Normalise Flye's empty-field sentinel (``*``) and blanks to ``None``."""
    return None if val in (None, "", "*") else val


def read_flye_assembly_info(flye_info_path: str) -> dict[str, dict]:
    """Parse Flye's ``assembly_info.txt`` into ``{contig_name: metadata}``.

    Columns: ``#seq_name length cov. circ. repeat mult. alt_group graph_path``.
    """
    data: dict[str, dict] = {}
    with open(flye_info_path, encoding="utf-8", newline="") as fh:
        reader = csv.DictReader(fh, delimiter="\t")
        for row in reader:
            data[row["#seq_name"]] = {
                "coverage": _to_float(row.get("cov.")),
                "is_circular": row.get("circ.") == "Y",
                "is_repeated_region": row.get("repeat") == "Y",
                "multiplicity": _to_int(row.get("mult.")),
                "alt_group": _clean(row.get("alt_group")),
                "graph_path": _clean(row.get("graph_path")),
            }
    return data


def parse_assembly(
    fasta_path: str,
    flye_info_path: str | None = None,
    hash_algorithm: str = "md5",
) -> list[dict]:
    """Combine a consensus FASTA with (optional) Flye ``assembly_info.txt`` into Contig dicts.

    Only contigs present in the FASTA are returned (the FASTA is the post-polish survivor
    set). Flye metadata is ``None`` for any contig absent from ``assembly_info.txt`` (or for
    every contig when ``flye_info_path`` is ``None``).
    """
    info = read_flye_assembly_info(flye_info_path) if flye_info_path else {}
    records: list[dict] = []
    for contig_name, sequence in read_fasta(fasta_path):
        meta = info.get(contig_name, {})
        records.append({
            "name": contig_name,
            "length": len(sequence),
            "sequence_hash": hash_sequence(sequence, hash_algorithm),
            "hash_algorithm": hash_algorithm,
            "coverage": meta.get("coverage"),
            "is_circular": meta.get("is_circular"),
            "is_repeated_region": meta.get("is_repeated_region"),
            "multiplicity": meta.get("multiplicity"),
            "alt_group": meta.get("alt_group"),
            "graph_path": meta.get("graph_path"),
        })
    return records
