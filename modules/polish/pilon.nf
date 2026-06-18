process PILON_ITER {
    label 'assemblers'
    memory '28 GB'
    publishDir "${params.outdir}/02_polish/02_pilon/iter_${iter}", mode: 'copy'

    input:
    path contigs
    path read1
    path read2
    val  iter

    output:
    path "pilon_polished.fasta"

    script:
    def half_threads     = Math.max(1, (int)(params.threads * 0.5))
    def sort_threads     = Math.max(0, half_threads - 1)
    """
    bwa-mem2 index -p bwa_idx ${contigs}

    bwa-mem2 mem -t ${half_threads} bwa_idx ${read1} ${read2} \\
        | samtools sort -@ ${sort_threads} -o alignment.bam

    samtools index alignment.bam

    pilon \\
        -Xmx24G \\
        --genome ${contigs} \\
        --output pilon_polished \\
        --outdir . \\
        --bam alignment.bam \\
        --threads ${params.threads} \\
        --changes --iupac
    """
}
