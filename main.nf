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

include { KRAKEN2 } from './classify/kraken2.nf'

// Composable core: takes a long-reads channel, emits the Kraken2 report.
// Bracken abundance re-estimation is a deliberate future seam (see meta_kg_export.py).
workflow KRAKEN2_CLASSIFY {
    take:
        long_reads_ch

    main:
        KRAKEN2(long_reads_ch)

    emit:
        report = KRAKEN2.out.report
}

// Entry wrapper: reads params, validates, builds the channel, runs the core.
workflow AUTO_KRAKEN2_CLASSIFY {
    if (!params.sample_id)  error "Missing required param: --sample_id"
    if (!params.long_reads) error "Missing required param: --long_reads"
    if (!params.kraken2_db) error "Missing required param: --kraken2_db (Kraken2 DB dir with hash.k2d/opts.k2d/taxo.k2d)"

    KRAKEN2_CLASSIFY(channel.fromPath(params.long_reads, checkIfExists: false))
}

// Default entry so the module runs standalone:
//   nextflow run ./kraken2-classify --sample_id S01 --long_reads reads.fq.gz --kraken2_db <db>
workflow {
    AUTO_KRAKEN2_CLASSIFY()
}
