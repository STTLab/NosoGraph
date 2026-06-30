/*
 * Copyright (c) 2026 Sara Wattanasombat
 * SPDX-License-Identifier: MPL-2.0
 *
 * This Source Code Form is subject to the terms of the
 * Mozilla Public License, v. 2.0. If a copy of the MPL
 * was not distributed with this file, You can obtain one at
 * https://mozilla.org/MPL/2.0/
 */
process QUAST {
    // Assembly-level metrics for one sample's FASTA. reads/reference are optional: the
    // caller passes either a real path or the assets/NO_FILE sentinel (an empty channel
    // would stall the process), and we gate the flags on the staged filename. Reference-
    // free mode is the QUAST default — the genome-fraction/misassembly columns are simply
    // omitted (§7.1).
    label 'quast'
    conda "${moduleDir}/../conda/quast.yaml"
    publishDir "${params.outdir}", mode: 'copy'

    input:
    path assembly
    path reads,     stageAs: 'optional_reads/*'
    path reference, stageAs: 'optional_ref/*'

    output:
    path "quast_results/",        emit: results
    path "versions/quast.txt",    emit: versions

    script:
    def readflag = reads.name != 'NO_FILE'
        ? (params.tech == 'pacbio' ? "--pacbio ${reads}" : "--nanopore ${reads}")
        : ''
    def refflag = reference.name != 'NO_FILE' ? "-r ${reference}" : ''
    """
    quast.py \\
        -o quast_results \\
        -t ${params.threads} \\
        ${refflag} \\
        ${readflag} \\
        ${assembly}

    mkdir -p versions
    quast.py --version > versions/quast.txt
    """

    stub:
    """
    mkdir -p quast_results versions
    touch quast_results/report.tsv
    touch versions/quast.txt
    """
}
