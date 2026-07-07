/*
 * Copyright (c) 2026 Sara Wattanasombat
 * SPDX-License-Identifier: MPL-2.0
 *
 * This Source Code Form is subject to the terms of the
 * Mozilla Public License, v. 2.0. If a copy of the MPL
 * was not distributed with this file, You can obtain one at
 * https://mozilla.org/MPL/2.0/
 */
process RACON_POLISH {
    label 'assemblers'
    conda "${moduleDir}/../conda/bacterial-assembly.yaml"
    container params.images.bacterial_assembly
    publishDir "${params.outdir}/02_polish/01_racon", mode: 'copy'

    input:
    path contigs
    path long_reads

    output:
    path "racon_final.fa"

    script:
    def minimap2_preset = (params.tech == 'nanopore' || params.tech == 'nanopore-hq') ? 'ava-ont' : 'ava-pb'
    """
    CONTIGS=${contigs}
    for i in \$(seq 1 ${params.racon_iter}); do
        minimap2 -x ${minimap2_preset} -o overlap_\${i}.paf -t ${params.threads} \$CONTIGS ${long_reads}
        racon -t ${params.threads} -e 0.1 -q 15 ${long_reads} overlap_\${i}.paf \$CONTIGS > racon_\${i}.fa
        CONTIGS=racon_\${i}.fa
    done
    cp \$CONTIGS racon_final.fa
    """

    stub:
    """
    touch racon_final.fa
    """
}
