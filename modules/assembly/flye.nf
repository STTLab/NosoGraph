process ASSEMBLY_FLYE {
    label 'assemblers'
    publishDir "${params.outdir}/01_assembly", mode: 'copy'

    input:
    path long_reads

    output:
    path "assembly.contigs.fasta"

    script:
    def tech_flag = params.tech == 'nanopore'    ? '--nano-raw'   :
                    params.tech == 'nanopore-hq'  ? '--nano-hq'    :
                    params.tech == 'pacbio'        ? '--pacbio-raw' :
                    { error "Unknown tech '${params.tech}'. Use: nanopore, nanopore-hq, pacbio" }()
    def genome_size_arg = params.genome_size ? "--genome-size ${params.genome_size}" : ""
    """
    flye \\
        --out-dir flye_out \\
        --threads ${params.threads} \\
        ${genome_size_arg} \\
        ${tech_flag} ${long_reads}
    mv flye_out/assembly.fasta assembly.contigs.fasta
    """
}
