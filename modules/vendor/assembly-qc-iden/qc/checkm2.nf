/*
 * Copyright (c) 2026 Sara Wattanasombat
 * SPDX-License-Identifier: MPL-2.0
 *
 * This Source Code Form is subject to the terms of the
 * Mozilla Public License, v. 2.0. If a copy of the MPL
 * was not distributed with this file, You can obtain one at
 * https://mozilla.org/MPL/2.0/
 */
process CHECKM2 {
    // Completeness/contamination for one assembly. Emits checkm2_results/quality_report.tsv
    // (columns Completeness, Contamination — consumed by NosoGraph's _read_checkm2; §7.2).
    label 'checkm2'
    conda "${moduleDir}/../conda/checkm2.yaml"
    container params.images.checkm2
    publishDir "${params.outdir}", mode: 'copy'

    input:
    path assembly

    output:
    path "checkm2_results/",      emit: results
    path "versions/checkm2.txt",  emit: versions

    script:
    if (!params.checkm2_db) error "CHECKM2 requires --checkm2_db (path to uniref100.KO.1.dmnd)"
    """
    checkm2 predict \\
        --threads ${params.threads} \\
        --input ${assembly} \\
        --output-directory checkm2_results \\
        --database_path ${params.checkm2_db} \\
        --remove_intermediates

    mkdir -p versions
    checkm2 --version > versions/checkm2.txt
    """

    stub:
    """
    mkdir -p checkm2_results versions
    touch checkm2_results/quality_report.tsv
    touch versions/checkm2.txt
    """
}
