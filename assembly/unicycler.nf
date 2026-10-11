/*
 * Copyright (c) 2026 Sara Wattanasombat
 * SPDX-License-Identifier: MPL-2.0
 *
 * This Source Code Form is subject to the terms of the
 * Mozilla Public License, v. 2.0. If a copy of the MPL
 * was not distributed with this file, You can obtain one at
 * https://mozilla.org/MPL/2.0/
 */
// Hybrid (-1/-2/-l) when both short reads are real files; long-only (-l) when they
// are the assets/NO_FILE sentinel. Per-input stageAs subdirs keep the two sentinels
// from colliding.
process ASSEMBLY_UNICYCLER {
    label 'assemblers'
    conda "${moduleDir}/../conda/unicycler.yaml"
    container params.images.unicycler
    publishDir "${params.outdir}/01_assembly", mode: 'copy'

    input:
    path long_reads
    path read1, stageAs: 'sr1/*'
    path read2, stageAs: 'sr2/*'

    output:
    path "assembly.contigs.fasta", emit: contigs
    path "assembly.gfa",           emit: graph
    path "unicycler.log",          emit: log

    script:
    def hybrid  = !read1.toString().endsWith('NO_FILE') && !read2.toString().endsWith('NO_FILE')
    def sr_args = hybrid ? "-1 ${read1} -2 ${read2}" : ""
    """
    unicycler \\
        ${sr_args} \\
        -l ${long_reads} \\
        -o unicycler_out \\
        -t ${params.threads} \\
        --mode ${params.unicycler_mode}
    mv unicycler_out/assembly.fasta assembly.contigs.fasta
    mv unicycler_out/assembly.gfa assembly.gfa
    mv unicycler_out/unicycler.log unicycler.log
    """

    stub:
    """
    touch assembly.contigs.fasta
    touch assembly.gfa
    touch unicycler.log
    """
}
