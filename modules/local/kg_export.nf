/*
 * SPDX-License-Identifier: MPL-2.0
 *
 * NosoGraph-owned (not vendored) process: export one sample's assembly outputs to
 * Neo4j-ready CSVs under <outdir>/<sample_id>/kg/, matching the migrated `nosograph`
 * graph schema. Consumes the final assembly FASTA plus, when available, Flye's
 * assembly_info.txt and the CheckM2 results directory. Missing optional inputs are
 * passed as a NO_FILE sentinel and the exporter degrades gracefully.
 */
nextflow.enable.dsl=2

process KG_EXPORT {
    tag "${params.sample_id}"
    conda "${moduleDir}/../../conda/kg_export.yaml"
    publishDir "${params.outdir}/${params.sample_id}", mode: 'copy'

    input:
    path assembly_fasta
    path flye_info
    path checkm2_dir

    output:
    path "kg/*.csv"

    script:
    def fastq_abs = file(params.long_reads)
    def info_arg  = flye_info.name   != 'NO_FLYE_INFO' ? "--flye-info ${flye_info}"  : ""
    def cm2_arg   = checkm2_dir.name != 'NO_CHECKM2'   ? "--checkm2 ${checkm2_dir}"  : ""
    """
    python ${projectDir}/report/kg_export.py \\
        --sample    ${params.sample_id} \\
        --assembler ${params.assembler} \\
        --fasta     ${assembly_fasta} \\
        --fastq     ${fastq_abs} \\
        ${info_arg} \\
        ${cm2_arg} \\
        --outdir .
    """

    stub:
    """
    mkdir -p kg
    for f in sample assembly biodata_files contigs; do
        echo "stub" > kg/\$f.csv
    done
    """
}
