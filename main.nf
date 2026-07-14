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

include { ASSEMBLY_CANU } from './assembly/canu.nf'
include { ASSEMBLY_FLYE } from './assembly/flye.nf'
include { RACON_POLISH  } from './polish/racon.nf'
include { PILON_POLISH  } from './polish/pilon.nf'
include { CHECKM2       } from './qc/checkm2.nf'

// Composable core: single-assembler long-read assembly -> racon -> pilon -> CheckM2.
// Racon is gated by params.racon_iter, Pilon by the pilon_iter input. CheckM2 always
// runs, on whichever assembly comes out last.
workflow BACTERIAL_ASSEMBLY {
    take:
        long_reads_ch
        read1_ch
        read2_ch
        pilon_iter      // effective iterations; 0 skips Pilon (read1_ch/read2_ch unused)

    main:
        // --- Assembly ---
        def assembly_ch
        if (params.assembler == 'canu') {
            assembly_ch = ASSEMBLY_CANU(long_reads_ch).contigs
        } else if (params.assembler == 'flye') {
            assembly_ch = ASSEMBLY_FLYE(long_reads_ch).contigs
        } else {
            error "Unknown assembler '${params.assembler}'. Use: canu, flye"
        }

        def racon_iter = params.racon_iter as int

        // --- Racon polishing (all iterations in one process) ---
        def polished_ch = (racon_iter > 0)
            ? RACON_POLISH(assembly_ch, long_reads_ch)
            : assembly_ch

        // --- Pilon polishing (all iterations in one process) ---
        def final_ch = (pilon_iter > 0)
            ? PILON_POLISH(polished_ch, read1_ch, read2_ch)
            : polished_ch

        // --- QC: always runs, on whatever the final assembly is ---
        def qc_ch = CHECKM2(final_ch)

    emit:
        assembly = final_ch
        qc       = qc_ch
}

// Entry wrapper: reads params, validates, builds channels, runs the core.
workflow AUTO_BACTERIAL_ASSEMBLY {
    if (!params.long_reads) error "Missing required param: --long_reads"
    if (!params.assembler)  error "Missing required param: --assembler (canu | flye)"
    if (!params.tech)       error "Missing required param: --tech (nanopore | nanopore-hq | pacbio)"

    // Long-read-only runs are a first-class mode: rather than making the user pass
    // --pilon_iter 0, drop the short-read polish when there are no short reads to
    // polish with. params is read-only at runtime, so resolve the value here.
    def pilon_iter = params.pilon_iter as int
    if (pilon_iter > 0 && (!params.read1 || !params.read2)) {
        log.info "No --read1/--read2 supplied: skipping Pilon short-read polishing (QC still runs)."
        pilon_iter = 0
    }

    long_reads_ch = channel.fromPath(params.long_reads, checkIfExists: false)
    read1_ch = params.read1 ? channel.fromPath(params.read1, checkIfExists: false) : channel.empty()
    read2_ch = params.read2 ? channel.fromPath(params.read2, checkIfExists: false) : channel.empty()

    BACTERIAL_ASSEMBLY(long_reads_ch, read1_ch, read2_ch, pilon_iter)
}

// Default entry so the module runs standalone:
//   nextflow run modules/bacterial-assembly --long_reads <reads> --assembler flye --tech nanopore
workflow {
    AUTO_BACTERIAL_ASSEMBLY()
}
