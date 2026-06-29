/*
 * Copyright (c) 2026 Sara Wattanasombat
 * SPDX-License-Identifier: MPL-2.0
 *
 * This Source Code Form is subject to the terms of the
 * Mozilla Public License, v. 2.0. If a copy of the MPL
 * was not distributed with this file, You can obtain one at
 * https://mozilla.org/MPL/2.0/
 */
process KRAKEN2 {
    // Classify one long-read FASTQ against a pre-built Kraken2 database. Emits the
    // standard 6-column kraken-style report consumed downstream by META_KG_EXPORT.
    label 'kraken2'
    conda "${moduleDir}/../conda/kraken2.yaml"
    publishDir "${params.outdir}/kraken2", mode: 'copy'

    input:
    path long_reads

    output:
    path "${params.sample_id}.kraken2.report.txt", emit: report
    path "${params.sample_id}.kraken2.output.txt", emit: output

    script:
    // kraken2 does not auto-detect compression; flag it from the staged filename.
    def comp = long_reads.toString().endsWith('.gz') ? '--gzip-compressed' : ''
    """
    kraken2 \\
        --db ${params.kraken2_db} \\
        --threads ${params.threads} \\
        ${comp} \\
        --confidence ${params.kraken2_confidence} \\
        --report ${params.sample_id}.kraken2.report.txt \\
        --output ${params.sample_id}.kraken2.output.txt \\
        ${long_reads}
    """

    stub:
    """
    touch ${params.sample_id}.kraken2.report.txt
    touch ${params.sample_id}.kraken2.output.txt
    """
}
