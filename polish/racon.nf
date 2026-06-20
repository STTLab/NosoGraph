process RACON_POLISH {
    label 'assemblers'
    conda "${moduleDir}/../conda/bacterial-assembly.yaml"
    publishDir "${params.outdir}/02_polish/01_racon", mode: 'copy'

    input:
    path contigs
    path long_reads

    output:
    path "racon_final.fa"

    script:
    def minimap2_preset = (params.tech == 'nanopore' || params.tech == 'nanopore-hq') ? 'ava-ont' : 'ava-pb'
    """
    CONTIGS=${contigs}
    for i in \$(seq 1 ${params.racon_iter}); do
        minimap2 -x ${minimap2_preset} -o overlap_\${i}.paf -t ${params.threads} \$CONTIGS ${long_reads}
        racon -t ${params.threads} -e 0.1 -q 15 ${long_reads} overlap_\${i}.paf \$CONTIGS > racon_\${i}.fa
        CONTIGS=racon_\${i}.fa
    done
    cp \$CONTIGS racon_final.fa
    """

    stub:
    """
    touch racon_final.fa
    """
}
