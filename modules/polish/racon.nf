process RACON_ITER {
    label 'assemblers'
    publishDir "${params.outdir}/02_polish/01_racon", mode: 'copy'

    input:
    path contigs
    path long_reads
    val  iter

    output:
    path "racon_iter_${iter}.fa"

    script:
    def minimap2_preset = (params.tech == 'nanopore' || params.tech == 'nanopore-hq') ? 'ava-ont' : 'ava-pb'
    """
    minimap2 \\
        -x ${minimap2_preset} \\
        -o overlap.paf \\
        -t ${params.threads} \\
        ${contigs} ${long_reads}

    racon \\
        -t ${params.threads} \\
        -e 0.1 -q 15 \\
        ${long_reads} overlap.paf ${contigs} > racon_iter_${iter}.fa
    """
}
