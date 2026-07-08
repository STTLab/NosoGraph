/*
 * Copyright (c) 2026 Sara Wattanasombat
 * SPDX-License-Identifier: MPL-2.0
 *
 * This Source Code Form is subject to the terms of the
 * Mozilla Public License, v. 2.0. If a copy of the MPL
 * was not distributed with this file, You can obtain one at
 * https://mozilla.org/MPL/2.0/
 */
process BLAST {
    // Megablast each contig against a formatted nucleotide DB, then collapse to a
    // best-hit-per-contig identification table (§7.3). Uses a shell: block so the awk
    // normalizer keeps bash $-fields literal; Nextflow values come in via !{...}.
    label 'blast'
    conda "${moduleDir}/../conda/blast.yaml"
    container params.images.blast
    publishDir "${params.outdir}", mode: 'copy'

    input:
    path assembly

    output:
    path "blast/",               emit: results
    path "versions/blast.txt",   emit: versions

    script:
    if (!params.blast_db) error "BLAST requires --blast_db (formatted nucleotide DB prefix)"
    '''
    mkdir -p blast versions

    raw="blast/!{params.sample_id}.blast.outfmt6.tsv"
    iden="blast/!{params.sample_id}.contig_identification.tsv"

    # 1) Raw hits — column order is fixed by the output contract (§7.3 file 1).
    blastn \
        -task megablast \
        -query !{assembly} \
        -db !{params.blast_db} \
        -num_threads !{params.threads} \
        -max_target_seqs !{params.blast_max_target_seqs} \
        -evalue !{params.blast_evalue} \
        -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen staxid ssciname stitle" \
        > "$raw"

    # Every contig id from the FASTA — token up to first whitespace, the exact join key
    # (§7.4). blastn's qseqid is whitespace-truncated the same way, so they match byte-for-byte.
    grep '^>' !{assembly} | sed 's/^>//' | awk '{print $1}' > blast/.contig_ids.txt

    # 2) Best hit per contig: max bitscore, then min e-value, then lexicographically
    #    smallest accession (§8 deterministic tie-break). No-hit contigs still emit a row
    #    with empty-string fields (never NA/null/-; §7.3 empty-value convention).
    awk -F'\t' '
    BEGIN { OFS="\t" }
    FNR==NR { order[++n]=$1; next }
    {
        q=$1; bs=$12+0; ev=$11+0; acc=$2
        better=0
        if (!(q in best_acc)) better=1
        else if (bs > best_bs[q]) better=1
        else if (bs == best_bs[q] && ev < best_ev[q]) better=1
        else if (bs == best_bs[q] && ev == best_ev[q] && acc < best_acc[q]) better=1
        if (better) {
            best_bs[q]=bs; best_ev[q]=ev; best_acc[q]=acc
            pid[q]=$3; sci[q]=$16; tax[q]=$15; ev_raw[q]=$11; bs_raw[q]=$12
            qcov[q]=($13+0>0) ? ($4/$13) : ""
        }
    }
    END {
        print "contig","accession","sciname","staxid","pident","query_coverage","evalue","bitscore"
        for (i=1;i<=n;i++) {
            c=order[i]
            if (c in best_acc)
                print c, best_acc[c], sci[c], tax[c], pid[c], qcov[c], ev_raw[c], bs_raw[c]
            else
                print c, "", "", "", "", "", "", ""
        }
    }
    ' blast/.contig_ids.txt "$raw" > "$iden"

    rm -f blast/.contig_ids.txt
    blastn -version > versions/blast.txt
    '''

    stub:
    """
    mkdir -p blast versions
    touch blast/${params.sample_id}.blast.outfmt6.tsv
    touch blast/${params.sample_id}.contig_identification.tsv
    touch versions/blast.txt
    """
}
