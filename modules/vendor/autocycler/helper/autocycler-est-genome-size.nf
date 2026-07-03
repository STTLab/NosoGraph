/*
 * Copyright (c) 2026 Sara Wattanasombat
 * SPDX-License-Identifier: MPL-2.0
 *
 * This Source Code Form is subject to the terms of the
 * Mozilla Public License, v. 2.0. If a copy of the MPL
 * was not distributed with this file, You can obtain one at
 * https://mozilla.org/MPL/2.0/
 */
process AUTOCYCLER_EST_GENOMESIZE {
    // Estimate genome size from the long reads (used when params.genome_size is null).
    label 'autocycler'
    conda "${moduleDir}/../conda/autocycler.yaml"

    input:
    path long_reads

    output:
    stdout

    script:
    """
    autocycler helper genome_size \\
        --reads ${long_reads} \\
        --threads ${params.threads}
    """

    stub:
    """
    echo "242000"
    """
}
