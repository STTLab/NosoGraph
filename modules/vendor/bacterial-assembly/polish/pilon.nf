/*
 * Copyright (c) 2026 Sara Wattanasombat
 * SPDX-License-Identifier: MPL-2.0
 *
 * This Source Code Form is subject to the terms of the
 * Mozilla Public License, v. 2.0. If a copy of the MPL
 * was not distributed with this file, You can obtain one at
 * https://mozilla.org/MPL/2.0/
 */
process PILON_POLISH {
    label 'assemblers'
    conda "${moduleDir}/../conda/bacterial-assembly.yaml"
    container params.images.bacterial_assembly
    publishDir "${params.outdir}/02_polish/02_pilon", mode: 'copy'

    input:
    path contigs
    path read1, stageAs: 'reads_1.fastq.gz'
    path read2, stageAs: 'reads_2.fastq.gz'

    output:
    path "pilon_final.fasta"

    script:
    def half_threads = Math.max(1, ((params.threads as int) * 0.5) as int)
    def sort_threads = Math.max(0, half_threads - 1)
    """
    CONTIGS=${contigs}
    for i in \$(seq 1 ${params.pilon_iter}); do
        bwa-mem2 index -p bwa_idx_\${i} \$CONTIGS

        bwa-mem2 mem -t ${half_threads} bwa_idx_\${i} reads_1.fastq.gz reads_2.fastq.gz \\
            | samtools sort -@ ${sort_threads} -o alignment_\${i}.bam

        samtools index alignment_\${i}.bam

        pilon \\
            -Xmx24G \\
            --genome \$CONTIGS \\
            --output pilon_\${i} \\
            --outdir . \\
            --bam alignment_\${i}.bam \\
            --threads ${params.threads} \\
            --changes --iupac

        CONTIGS=pilon_\${i}.fasta
    done
    cp \$CONTIGS pilon_final.fasta
    """

    stub:
    """
    touch pilon_final.fasta
    """
}
