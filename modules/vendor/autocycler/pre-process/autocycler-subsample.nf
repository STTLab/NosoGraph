/*
 * Copyright (c) 2026 Sara Wattanasombat
 * SPDX-License-Identifier: MPL-2.0
 *
 * This Source Code Form is subject to the terms of the
 * Mozilla Public License, v. 2.0. If a copy of the MPL
 * was not distributed with this file, You can obtain one at
 * https://mozilla.org/MPL/2.0/
 */
process AUTOCYCLER_SUBSAMPLE {
    // Subsample the long-read set into multiple independent files for assembly.
    label 'autocycler'
    conda "${moduleDir}/../conda/autocycler.yaml"
    publishDir "${params.outdir}/01_assembly/subsampled_reads", mode: 'copy'

    input:
    tuple path(long_reads), val(genome_size)

    output:
    path "subsampled_reads/sample_*.fastq"

    script:
    """
    autocycler subsample \\
        --reads ${long_reads} \\
        --out_dir subsampled_reads \\
        --genome_size ${genome_size} \\
        --count ${params.subsample_count}
    """

    stub:
    """
    mkdir -p subsampled_reads
    for i in \$(seq -w 1 ${params.subsample_count}); do
        touch subsampled_reads/sample_\${i}.fastq
    done
    """
}
