process CHECKM2 {
    label 'qc_tools'
    conda "${moduleDir}/../conda/bacterial-assembly.yaml"
    publishDir "${params.outdir}", mode: 'copy'

    input:
    path assembly

    output:
    path "checkm2_results/"

    script:
    if (!params.checkm2_db) error "CHECKM2 requires --checkm2_db (path to uniref100.KO.1.dmnd)"
    """
    checkm2 predict \\
        --threads ${params.threads} \\
        --input ${assembly} \\
        --output-directory checkm2_results \\
        --database_path ${params.checkm2_db} \\
        --remove_intermediates
    """

    stub:
    """
    mkdir -p checkm2_results
    """
}
