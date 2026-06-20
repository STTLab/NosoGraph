process ASSEMBLY_CANU {
    label 'assemblers'
    publishDir "${params.outdir}/01_assembly", mode: 'copy'

    input:
    path long_reads

    output:
    path "assembly.contigs.fasta"

    script:
    if (!params.genome_size) error "ASSEMBLY_CANU requires --genome_size"
    def tech_flag = (params.tech == 'nanopore' || params.tech == 'nanopore-hq') ? '-nanopore-raw' : '-pacbio-raw'
    """
    canu \\
        -p assembly \\
        -d canu_out \\
        genomeSize=${params.genome_size} \\
        ${tech_flag} ${long_reads} \\
        maxThreads=${params.threads}
    mv canu_out/assembly.contigs.fasta assembly.contigs.fasta
    """

    stub:
    """
    touch assembly.contigs.fasta
    """
}
