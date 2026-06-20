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
