/*
 * SPDX-License-Identifier: MPL-2.0
 *
 * NosoGraph-owned (not vendored) process: export one sample's metagenomics
 * classification outputs to Neo4j-ready CSVs under <outdir>/<sample_id>/kg/, matching
 * the migrated `nosograph` graph schema (taxonomic-classification public extension).
 * Consumes a Kraken2 report. The input FASTQ is sourced from params.long_reads when set
 * (for the BioDataFile node). Bracken refinement is a future seam (see meta_kg_export.py).
 */
nextflow.enable.dsl=2

process META_KG_EXPORT {
    tag "${params.sample_id}"
    conda "${moduleDir}/../../conda/meta_kg_export.yaml"
    publishDir "${params.outdir}/${params.sample_id}", mode: 'copy'

    input:
    path kraken2_report

    output:
    path "kg/*.csv"

    script:
    def reads_arg = params.long_reads ? "--reads ${file(params.long_reads)}" : ""
    """
    python ${projectDir}/report/meta_kg_export.py \\
        --sample          ${params.sample_id} \\
        --kraken2-report  ${kraken2_report} \\
        ${reads_arg} \\
        --outdir .
    """

    stub:
    """
    mkdir -p kg
    for f in meta_reads taxonomic_classification taxa; do
        echo "stub" > kg/\$f.csv
    done
    """
}
