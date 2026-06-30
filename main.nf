/*
 * Copyright (c) 2026 Sara Wattanasombat
 * SPDX-License-Identifier: MPL-2.0
 *
 * This Source Code Form is subject to the terms of the
 * Mozilla Public License, v. 2.0. If a copy of the MPL
 * was not distributed with this file, You can obtain one at
 * https://mozilla.org/MPL/2.0/
 */
nextflow.enable.dsl=2

include { QUAST   } from './qc/quast.nf'
include { CHECKM2 } from './qc/checkm2.nf'
include { BLAST   } from './iden/blast.nf'

// Composable core: QC + identification for ONE sample's assembly. reads/reference are
// optional — they arrive as value channels carrying either a real path or the
// assets/NO_FILE sentinel (an empty channel would stall QUAST). NosoGraph maps the §7
// outputs into the knowledge graph; this module produces tool outputs only.
workflow ASSEMBLY_QC_IDEN {
    take:
        assembly        // path — required, the FASTA
        reads           // path — optional (QUAST read-mapping stats); NO_FILE sentinel = none
        reference       // path — optional (QUAST reference-based stats); NO_FILE sentinel = none

    main:
        QUAST(assembly, reads, reference)
        CHECKM2(assembly)
        BLAST(assembly)

    emit:
        quast   = QUAST.out.results      // path "quast_results/"
        checkm2 = CHECKM2.out.results    // path "checkm2_results/"
        blast   = BLAST.out.results      // path "blast/"
}

// Entry wrapper: reads params, validates, builds channels, runs the core. Optional inputs
// resolve to the NO_FILE sentinel so the single-invocation processes always run once.
workflow AUTO_ASSEMBLY_QC_IDEN {
    if (!params.sample_id) error "Missing required param: --sample_id"
    if (!params.assembly)  error "Missing required param: --assembly (input FASTA)"

    def no_file = "${moduleDir}/assets/NO_FILE"

    assembly_ch  = channel.fromPath(params.assembly, checkIfExists: false)
    reads_ch     = channel.fromPath(params.reads     ?: no_file, checkIfExists: false)
    reference_ch = channel.fromPath(params.reference ?: no_file, checkIfExists: false)

    ASSEMBLY_QC_IDEN(assembly_ch, reads_ch, reference_ch)
}

// Default entry so the module runs standalone:
//   nextflow run ./assembly-qc-iden --sample_id S01 --assembly contigs.fasta \
//     --checkm2_db <db> --blast_db <db_prefix>
workflow {
    AUTO_ASSEMBLY_QC_IDEN()
}
