/*
 * SPDX-License-Identifier: MPL-2.0
 *
 * NosoGraph-owned (not vendored) process: export one sample's metagenomics
 * classification outputs to Neo4j-ready CSVs under <outdir>/<sample_id>/kg/, matching
 * the migrated `nosograph` graph schema (taxonomic-classification public extension).
 * Consumes a Kraken2 report. The input FASTQ is sourced from params.long_reads when set
 * (for the BioDataFile node). Identified taxa ride along as a `taxa_json` QC blob on the
 * TaxonomicClassification node (no Organism nodes); the z-score "Other" bucket is tuned via
 * params.kraken2_z_min / params.kraken2_min_taxa. Bracken refinement is a future seam
 * (see meta_kg_export.py).
 */
nextflow.enable.dsl=2

process META_KG_EXPORT {
    tag "${params.sample_id}"
    // Runs on the host Python (pandas only — see requirements.txt). No conda/container:
    // it's a trivial CSV writer, not a bioinformatics tool, so it needs neither the
    // frozen-image guarantee nor a solved env.
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
        --z-min           ${params.kraken2_z_min} \\
        --min-taxa        ${params.kraken2_min_taxa} \\
        --outdir .
    """

    stub:
    """
    mkdir -p kg
    for f in meta_reads taxonomic_classification; do
        echo "stub" > kg/\$f.csv
    done
    """
}
