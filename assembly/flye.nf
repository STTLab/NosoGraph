/*
 * Copyright (c) 2026 Sara Wattanasombat
 * SPDX-License-Identifier: MPL-2.0
 *
 * This Source Code Form is subject to the terms of the
 * Mozilla Public License, v. 2.0. If a copy of the MPL
 * was not distributed with this file, You can obtain one at
 * https://mozilla.org/MPL/2.0/
 */
process ASSEMBLY_FLYE {
    label 'assemblers'
    conda "${moduleDir}/../conda/bacterial-assembly.yaml"
    publishDir "${params.outdir}/01_assembly", mode: 'copy'

    input:
    path long_reads

    output:
    path "assembly.contigs.fasta"
    path "assembly_info.txt"

    script:
    def tech_flag = params.tech == 'nanopore'    ? '--nano-raw'   :
                    params.tech == 'nanopore-hq'  ? '--nano-hq'    :
                    params.tech == 'pacbio'        ? '--pacbio-raw' :
                    { error "Unknown tech '${params.tech}'. Use: nanopore, nanopore-hq, pacbio" }()
    def genome_size_arg = params.genome_size ? "--genome-size ${params.genome_size}" : ""
    """
    flye \\
        --out-dir flye_out \\
        --threads ${params.threads} \\
        ${genome_size_arg} \\
        ${tech_flag} ${long_reads}
    mv flye_out/assembly.fasta assembly.contigs.fasta
    mv flye_out/assembly_info.txt assembly_info.txt
    """

    stub:
    """
    mkdir -p flye_out
    touch assembly.contigs.fasta
    touch assembly_info.txt
    """
}
