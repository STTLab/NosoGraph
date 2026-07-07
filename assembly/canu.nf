/*
 * Copyright (c) 2026 Sara Wattanasombat
 * SPDX-License-Identifier: MPL-2.0
 *
 * This Source Code Form is subject to the terms of the
 * Mozilla Public License, v. 2.0. If a copy of the MPL
 * was not distributed with this file, You can obtain one at
 * https://mozilla.org/MPL/2.0/
 */
process ASSEMBLY_CANU {
    label 'assemblers'
    conda "${moduleDir}/../conda/bacterial-assembly.yaml"
    container params.images.bacterial_assembly
    publishDir "${params.outdir}/01_assembly", mode: 'copy'

    input:
    path long_reads

    output:
    path "assembly.contigs.fasta", emit: contigs

    script:
    if (!params.genome_size) error "ASSEMBLY_CANU requires --genome_size"
    def tech_flag = (params.tech == 'nanopore' || params.tech == 'nanopore-hq') ? '-nanopore-raw' : '-pacbio-raw'
    """
    canu \\
        -p assembly \\
        -d canu_out \\
        genomeSize=${params.genome_size} \\
        ${tech_flag} ${long_reads} \\
        maxThreads=${params.threads}
    mv canu_out/assembly.contigs.fasta assembly.contigs.fasta
    """

    stub:
    """
    touch assembly.contigs.fasta
    """
}
