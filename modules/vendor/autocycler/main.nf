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

include { AUTOCYCLER_EST_GENOMESIZE } from './helper/autocycler-est-genome-size.nf'
include { AUTOCYCLER_SUBSAMPLE }      from './pre-process/autocycler-subsample.nf'
include { AUTOCYCLER_ASSEMBLE
          AUTOCYCLER_COMPRESS
          AUTOCYCLER_CLUSTER
          AUTOCYCLER_TRIM_RESOLVE
          AUTOCYCLER_COMBINE }        from './assembly/autocycler.nf'

// Composable core: takes a long-reads channel, emits the consensus assembly.
workflow AUTOCYCLER {
    take:
        long_reads_ch

    main:
        // --- Genome size: use the override, else estimate from the reads ---
        genome_size_ch = params.genome_size
            ? channel.value(params.genome_size as String)
            : AUTOCYCLER_EST_GENOMESIZE(long_reads_ch).map { item -> item.trim() }

        // --- Subsample, then fan one channel item out per subsample file ---
        samples_ch = AUTOCYCLER_SUBSAMPLE(
                         long_reads_ch.combine(genome_size_ch)
                     ).flatten()

        // --- Assemble every (assembler, subsample) combination in parallel ---
        assemblers_ch = channel.fromList(params.assemblers.tokenize(','))
        combos_ch     = assemblers_ch.combine(samples_ch).combine(genome_size_ch)
                        // -> tuple(assembler, sample, genome_size)
        assemblies_ch = AUTOCYCLER_ASSEMBLE(combos_ch).collect()

        // --- Compress + cluster; cluster count is only known at runtime ---
        clustered = AUTOCYCLER_CLUSTER(AUTOCYCLER_COMPRESS(assemblies_ch))

        // --- Trim/resolve each cluster in parallel, then gather the final GFAs ---
        gfas_ch = AUTOCYCLER_TRIM_RESOLVE(clustered.clusters.flatten()).collect()

        // --- Combine into the consensus assembly ---
        AUTOCYCLER_COMBINE(clustered.dir, gfas_ch)

    emit:
        // nextflow-lint-disable-next-line emit-name-should-be-omitted
        consensus = AUTOCYCLER_COMBINE.out.fasta
}

// Entry wrapper: reads params, builds the long-reads channel, runs the core.
workflow AUTO_AUTOCYCLER {
    if (!params.long_reads) error "Missing required param: --long_reads"
    AUTOCYCLER(channel.fromPath(params.long_reads, checkIfExists: false))
}

// Default entry so the module runs standalone:
//   nextflow run modules/autocycler --long_reads <reads>
workflow {
    AUTO_AUTOCYCLER()
}
